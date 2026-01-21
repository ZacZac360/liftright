# liftright/ml/scripts/realtime_server.py
# v1: BICEP CURL ONLY — ported from golden standard 04_live_bicep_curl.py
# Contract matches your PHP bridge:
#   POST /start  {exercise_type, log_id, user_id} -> {session_token}
#   POST /frame  {session_token, frame_dataurl}   -> {annotated_frame_dataurl, status}
#   POST /finish {session_token}                  -> {reps_total, reps_good, reps_bad, form_error_count, fatigue_flag, reps[], feedback[]}

import base64
import json
import time
import uuid
import random
from dataclasses import dataclass, field
from typing import Dict, Any, Optional, Tuple, List
from collections import deque
from pathlib import Path

import cv2
import numpy as np
import joblib
import mediapipe as mp

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel


VERSION = "realtime_server_bicep_contract_v1_2026-01-21"

# ---------------- PATHS ----------------
PROJECT_ROOT = Path(__file__).resolve().parents[1]  # liftright/ml
MODEL_PKL = PROJECT_ROOT / "models" / "bicep_curl_ocsvm.pkl"
OUT_DIR = PROJECT_ROOT / "outputs"
OUT_DIR.mkdir(parents=True, exist_ok=True)
STATUS_JSON = OUT_DIR / "bicep_curl_status.json"  # optional debug mirror

# ---------------- CONFIG (match golden standard) ----------------

DRAW_TEXT_OVERLAY = False  # set True if you want cv2.putText inside the frame

MIN_CONF = 0.50

TOP_THR = 75
BOT_THR = 155
SMOOTH_N = 7
MIN_REP_TIME = 0.35

ELBOW_DRIFT_WARN = 0.35
ELBOW_DRIFT_BAD  = 0.55

CALIB_REPS = 5
FATIGUE_WINDOW = 6

ML_MARGIN = 0.030
ML_LOW_STREAK_FOR_TIP = 3

ML_SCORE_WINDOW = 8
ML_REL_DROP = 0.020
ML_MIN_SCORES_FOR_REL = 4

FATIGUE_WARN_INDEX = 55
FATIGUE_STOP_INDEX = 80
FATIGUE_STOP_STREAK = 2

GOOD_COLOR = (0, 255, 0)
WARN_COLOR = (0, 255, 255)
BAD_COLOR  = (0, 0, 255)
TEXT_COLOR = (240, 240, 240)
NEUTRAL_COLOR = (160, 160, 160)

PRAISE_LINES = [
    "Clean rep - controlled.",
    "Solid rep - keep it steady.",
    "Nice rep - good control.",
    "Smooth rep.",
    "Good rep - consistent tempo.",
]

GENERAL_TIPS = [
    "Control the way down (slow eccentric).",
    "Keep wrists neutral.",
    "Relax the shoulders.",
    "Breathe out as you curl.",
    "Keep your upper arm steady.",
]

mp_pose = mp.solutions.pose
mp_draw = mp.solutions.drawing_utils


# ----------------------------- UTIL -----------------------------
def write_status(payload: Dict[str, Any]) -> None:
    """Optional debug mirror like the golden standard file-based status."""
    try:
        payload = dict(payload)
        payload["timestamp"] = time.time()
        STATUS_JSON.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    except Exception:
        pass


def calculate_angle(a, b, c) -> float:
    a = np.array(a, dtype=np.float32)
    b = np.array(b, dtype=np.float32)
    c = np.array(c, dtype=np.float32)
    ba = a - b
    bc = c - b
    denom = (np.linalg.norm(ba) * np.linalg.norm(bc) + 1e-6)
    cos_angle = float(np.dot(ba, bc) / denom)
    cos_angle = float(np.clip(cos_angle, -1.0, 1.0))
    return float(np.degrees(np.arccos(cos_angle)))


def lm_xyv(landmarks, idx, w, h):
    lm = landmarks[idx]
    return (lm.x * w, lm.y * h, float(lm.visibility))


def safe_div(a, b, eps=1e-6) -> float:
    return float(a / (b + eps))


def median_or(x, fallback: float) -> float:
    x = [v for v in x if np.isfinite(v)]
    return float(np.median(x)) if len(x) else float(fallback)


def draw_skeleton_neutral(frame_bgr, pose_landmarks):
    if pose_landmarks is None:
        return
    spec = mp_draw.DrawingSpec(color=NEUTRAL_COLOR, thickness=2, circle_radius=2)
    mp_draw.draw_landmarks(
        frame_bgr,
        pose_landmarks,
        mp_pose.POSE_CONNECTIONS,
        landmark_drawing_spec=spec,
        connection_drawing_spec=spec
    )


def draw_segment(frame_bgr, pose_landmarks, a, b, color, thickness=6):
    if pose_landmarks is None:
        return
    lm = pose_landmarks.landmark
    h, w = frame_bgr.shape[:2]
    ax, ay = int(lm[a].x * w), int(lm[a].y * h)
    bx, by = int(lm[b].x * w), int(lm[b].y * h)
    cv2.line(frame_bgr, (ax, ay), (bx, by), color, thickness)


def highlight_issues(frame_bgr, pose_landmarks, right_elbow_level: int, left_elbow_level: int):
    if pose_landmarks is None:
        return

    if right_elbow_level > 0:
        c = WARN_COLOR if right_elbow_level == 1 else BAD_COLOR
        draw_segment(frame_bgr, pose_landmarks, mp_pose.PoseLandmark.RIGHT_SHOULDER, mp_pose.PoseLandmark.RIGHT_ELBOW, c)
        draw_segment(frame_bgr, pose_landmarks, mp_pose.PoseLandmark.RIGHT_ELBOW, mp_pose.PoseLandmark.RIGHT_WRIST, c)

    if left_elbow_level > 0:
        c = WARN_COLOR if left_elbow_level == 1 else BAD_COLOR
        draw_segment(frame_bgr, pose_landmarks, mp_pose.PoseLandmark.LEFT_SHOULDER, mp_pose.PoseLandmark.LEFT_ELBOW, c)
        draw_segment(frame_bgr, pose_landmarks, mp_pose.PoseLandmark.LEFT_ELBOW, mp_pose.PoseLandmark.LEFT_WRIST, c)


def decode_dataurl_to_bgr(dataurl: str) -> Optional[np.ndarray]:
    try:
        if dataurl.startswith("data:image"):
            b64 = dataurl.split(",", 1)[1]
        else:
            b64 = dataurl
        raw = base64.b64decode(b64)
        arr = np.frombuffer(raw, dtype=np.uint8)
        img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
        return img
    except Exception:
        return None


def bgr_to_dataurl_jpeg(frame_bgr: np.ndarray, quality: int = 80) -> str:
    ok, buf = cv2.imencode(".jpg", frame_bgr, [int(cv2.IMWRITE_JPEG_QUALITY), int(quality)])
    if not ok:
        return ""
    b64 = base64.b64encode(buf.tobytes()).decode("utf-8")
    return "data:image/jpeg;base64," + b64


# ----------------------------- FATIGUE -----------------------------
def compute_fatigue_index(baseline, rom_med, dur_med, drift_med):
    rom_ratio = safe_div(rom_med, baseline["rom"])
    dur_ratio = safe_div(dur_med, baseline["duration"])
    drift_delta = drift_med - baseline["drift"]

    c_rom = np.clip((0.70 - rom_ratio) / 0.70, 0.0, 1.0)
    c_dur = np.clip((dur_ratio - 1.25) / 1.25, 0.0, 1.0)
    c_drift = np.clip(drift_delta / 0.25, 0.0, 1.0)

    idx = (0.45 * c_rom + 0.25 * c_dur + 0.30 * c_drift) * 100.0

    comps = {
        "rom_ratio": float(rom_ratio),
        "dur_ratio": float(dur_ratio),
        "drift_delta": float(drift_delta),
        "c_rom": float(c_rom),
        "c_dur": float(c_dur),
        "c_drift": float(c_drift),
    }
    return float(idx), comps


def top_set_issues(set_counts):
    items = []
    right_total = set_counts["elbow_bad_right"] + set_counts["elbow_warn_right"]
    left_total  = set_counts["elbow_bad_left"] + set_counts["elbow_warn_left"]

    if right_total > 0:
        items.append(("right elbow drift", right_total))
    if left_total > 0:
        items.append(("left elbow drift", left_total))
    if set_counts["low_conf"] > 0:
        items.append(("tracking low", set_counts["low_conf"]))

    items.sort(key=lambda x: x[1], reverse=True)
    return items[:2]


# ----------------------------- REP COUNTER -----------------------------
class CurlRepCounter:
    """
    Golden standard + adds per-rep conf accumulation so we can report confidence_avg to DB.
    """
    def __init__(self):
        self.state = "down"
        self.rep_count = 0
        self.last_rep_t = 0.0
        self.buf = deque(maxlen=SMOOTH_N)
        self.reset_rep(time.time())

    def reset_rep(self, t):
        self.rep_start_t = t
        self.angles = []
        self.drift = []
        self.confs = []

        self.rep_tip_seen = False
        self.rep_bad_seen = False
        self.rep_tip_reason = ""
        self.rep_bad_reason = ""

    def mark_feedback(self, bad_list, tip_list):
        if bad_list:
            self.rep_bad_seen = True
            if not self.rep_bad_reason:
                self.rep_bad_reason = str(bad_list[0])
        if tip_list:
            self.rep_tip_seen = True
            if not self.rep_tip_reason:
                self.rep_tip_reason = str(tip_list[0])

    def update(self, elbow_angle, elbow_drift_norm, conf_mean: float):
        now = time.time()
        self.buf.append(float(elbow_angle))
        ang_s = float(np.median(self.buf))

        self.angles.append(ang_s)
        self.drift.append(float(elbow_drift_norm))
        self.confs.append(float(conf_mean))

        rep_done = False
        rep_summary = None

        if self.state == "down":
            if ang_s <= TOP_THR:
                self.state = "up"
        else:
            if ang_s >= BOT_THR:
                if (now - self.last_rep_t) >= MIN_REP_TIME and len(self.angles) >= 6:
                    self.rep_count += 1
                    self.last_rep_t = now
                    rep_done = True

                    angles = np.array(self.angles, dtype=np.float32)
                    drift  = np.array(self.drift, dtype=np.float32)
                    confs  = np.array(self.confs, dtype=np.float32)

                    rep_summary = {
                        "rep": self.rep_count,
                        "min_angle": float(angles.min()),
                        "max_angle": float(angles.max()),
                        "rom": float(angles.max() - angles.min()),
                        "duration": float(now - self.rep_start_t),
                        "elbow_drift_absmax": float(np.max(drift)),
                        "confidence_avg": float(np.mean(confs)) if len(confs) else 0.0,

                        "rep_tip_seen": bool(self.rep_tip_seen),
                        "rep_bad_seen": bool(self.rep_bad_seen),
                        "rep_tip_reason": str(self.rep_tip_reason),
                        "rep_bad_reason": str(self.rep_bad_reason),
                    }

                self.state = "down"
                self.reset_rep(now)

        return ang_s, rep_done, rep_summary


# ----------------------------- SESSION STATE -----------------------------
@dataclass
class BicepCurlSession:
    session_token: str
    user_id: int
    log_id: int
    exercise_type: str = "bicep_curl"

    rep_counter: CurlRepCounter = field(default_factory=CurlRepCounter)

    calib: list = field(default_factory=list)
    baseline_ready: bool = False
    baseline: Dict[str, Optional[float]] = field(default_factory=lambda: {"rom": None, "duration": None, "drift": None})
    recent: deque = field(default_factory=lambda: deque(maxlen=FATIGUE_WINDOW))

    set_counts: Dict[str, int] = field(default_factory=lambda: {
        "elbow_warn_right": 0,
        "elbow_bad_right": 0,
        "elbow_warn_left": 0,
        "elbow_bad_left": 0,
        "low_conf": 0,
    })

    # ML
    ml_low_streak: int = 0
    score_hist: deque = field(default_factory=lambda: deque(maxlen=ML_SCORE_WINDOW))

    # Fatigue
    fatigue_stop_streak: int = 0
    fatigue_index: float = 0.0
    fatigue_since_rep: Optional[int] = None
    fatigue_text: str = ""
    fatigue_details: Dict[str, Any] = field(default_factory=dict)

    # UI text
    last_rep_text: str = "-"
    last_rep_color: Tuple[int, int, int] = TEXT_COLOR

    # Summary for /finish
    reps: List[Dict[str, Any]] = field(default_factory=list)        # per rep metrics
    feedback: List[Dict[str, Any]] = field(default_factory=list)    # feedback events
    fatigue_flag: int = 0
    stopped: bool = False

    # last seen conf
    conf_last: float = 0.0


class BicepCurlPipeline:
    def __init__(self):
        bundle = joblib.load(MODEL_PKL)
        self.scaler = bundle["scaler"]
        self.model = bundle["model"]
        self.feats = bundle["features"]
        self.thr = float(bundle["threshold"])

        self.pose = mp_pose.Pose(
            static_image_mode=False,
            model_complexity=1,
            smooth_landmarks=True,
            enable_segmentation=False,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5,
        )

    def process(self, frame_bgr: np.ndarray, sess: BicepCurlSession) -> Tuple[np.ndarray, Dict[str, Any]]:
        h, w = frame_bgr.shape[:2]
        rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
        res = self.pose.process(rgb)

        feedback = "Tracking..."
        fb_color = TEXT_COLOR

        right_elbow_level = 0
        left_elbow_level = 0

        if res.pose_landmarks:
            lm = res.pose_landmarks.landmark

            LSH = lm_xyv(lm, mp_pose.PoseLandmark.LEFT_SHOULDER,  w, h)
            RSH = lm_xyv(lm, mp_pose.PoseLandmark.RIGHT_SHOULDER, w, h)
            LEL = lm_xyv(lm, mp_pose.PoseLandmark.LEFT_ELBOW,     w, h)
            REL = lm_xyv(lm, mp_pose.PoseLandmark.RIGHT_ELBOW,    w, h)
            LWR = lm_xyv(lm, mp_pose.PoseLandmark.LEFT_WRIST,     w, h)
            RWR = lm_xyv(lm, mp_pose.PoseLandmark.RIGHT_WRIST,    w, h)
            LHP = lm_xyv(lm, mp_pose.PoseLandmark.LEFT_HIP,       w, h)
            RHP = lm_xyv(lm, mp_pose.PoseLandmark.RIGHT_HIP,      w, h)

            conf_mean = float(np.mean([LSH[2], RSH[2], LEL[2], REL[2], LWR[2], RWR[2], LHP[2], RHP[2]]))
            sess.conf_last = conf_mean

            draw_skeleton_neutral(frame_bgr, res.pose_landmarks)

            if conf_mean >= MIN_CONF:
                shoulder_width = abs(LSH[0] - RSH[0])
                if shoulder_width < 2:
                    shoulder_width = 2

                right_angle = calculate_angle((RSH[0], RSH[1]), (REL[0], REL[1]), (RWR[0], RWR[1]))
                left_angle  = calculate_angle((LSH[0], LSH[1]), (LEL[0], LEL[1]), (LWR[0], LWR[1]))

                right_drift_norm = safe_div(abs(REL[0] - RSH[0]), shoulder_width)
                left_drift_norm  = safe_div(abs(LEL[0] - LSH[0]), shoulder_width)

                use_right_for_rep = (REL[2] >= LEL[2])
                elbow_angle_for_rep = right_angle if use_right_for_rep else left_angle
                elbow_drift_for_rep = right_drift_norm if use_right_for_rep else left_drift_norm

                bad = []
                tips = []

                if right_drift_norm > ELBOW_DRIFT_BAD:
                    right_elbow_level = 2
                    sess.set_counts["elbow_bad_right"] += 1
                elif right_drift_norm > ELBOW_DRIFT_WARN:
                    right_elbow_level = 1
                    sess.set_counts["elbow_warn_right"] += 1

                if left_drift_norm > ELBOW_DRIFT_BAD:
                    left_elbow_level = 2
                    sess.set_counts["elbow_bad_left"] += 1
                elif left_drift_norm > ELBOW_DRIFT_WARN:
                    left_elbow_level = 1
                    sess.set_counts["elbow_warn_left"] += 1

                worst_elbow = max(right_elbow_level, left_elbow_level)
                if worst_elbow == 2:
                    if right_elbow_level == 2 and left_elbow_level == 2:
                        bad.append("Elbow drifting a lot (both)")
                    elif right_elbow_level == 2:
                        bad.append("Elbow drifting a lot (right)")
                    else:
                        bad.append("Elbow drifting a lot (left)")
                elif worst_elbow == 1:
                    if right_elbow_level == 1 and left_elbow_level == 1:
                        tips.append("Keep elbows steadier (both)")
                    elif right_elbow_level == 1:
                        tips.append("Keep elbow steadier (right)")
                    else:
                        tips.append("Keep elbow steadier (left)")

                highlight_issues(frame_bgr, res.pose_landmarks, right_elbow_level, left_elbow_level)

                if bad:
                    feedback = "UNSAFE: " + bad[0]
                    fb_color = BAD_COLOR
                elif tips:
                    feedback = "COACHING: " + tips[0]
                    fb_color = WARN_COLOR
                else:
                    feedback = "STATUS: Stable"
                    fb_color = GOOD_COLOR

                # While "up", carry feedback into the rep summary (golden behavior)
                if sess.rep_counter.state == "up":
                    sess.rep_counter.mark_feedback(bad, tips)

                elbow_s, rep_done, rep_sum = sess.rep_counter.update(
                    elbow_angle_for_rep, elbow_drift_for_rep, conf_mean
                )

                if rep_done and rep_sum:
                    # --- ML score ---
                    drift_clip = min(rep_sum["elbow_drift_absmax"], 0.70)
                    feat_map = {
                        "rom": rep_sum["rom"],
                        "duration": rep_sum["duration"],
                        "elbow_drift_absmax": drift_clip,
                    }
                    if "trunk_absmax" in self.feats:
                        feat_map["trunk_absmax"] = 0.0

                    x = np.array([[feat_map[f] for f in self.feats]], dtype=np.float32)
                    xs = self.scaler.transform(x)
                    score = float(self.model.decision_function(xs)[0])

                    sess.recent.append({
                        "rom": rep_sum["rom"],
                        "duration": rep_sum["duration"],
                        "drift": drift_clip,
                        "score": score
                    })

                    # --- Baseline ---
                    if not sess.baseline_ready and not rep_sum["rep_bad_seen"]:
                        sess.calib.append(sess.recent[-1])
                        if len(sess.calib) >= CALIB_REPS:
                            sess.baseline["rom"] = median_or([r["rom"] for r in sess.calib], 120.0)
                            sess.baseline["duration"] = median_or([r["duration"] for r in sess.calib], 1.5)
                            sess.baseline["drift"] = median_or([r["drift"] for r in sess.calib], 0.14)
                            sess.baseline_ready = True

                    # --- Fatigue ---
                    sess.fatigue_text = ""
                    sess.fatigue_details = {}
                    if sess.baseline_ready and len(sess.recent) >= 4:
                        last3 = list(sess.recent)[-3:]
                        rom_med = median_or([r["rom"] for r in last3], sess.baseline["rom"])
                        dur_med = median_or([r["duration"] for r in last3], sess.baseline["duration"])
                        drift_med = median_or([r["drift"] for r in last3], sess.baseline["drift"])
                        sess.fatigue_index, comps = compute_fatigue_index(sess.baseline, rom_med, dur_med, drift_med)
                        sess.fatigue_details = comps

                        if sess.fatigue_since_rep is None and sess.fatigue_index >= FATIGUE_WARN_INDEX:
                            sess.fatigue_since_rep = int(rep_sum["rep"])

                        if sess.fatigue_index >= FATIGUE_WARN_INDEX:
                            sess.fatigue_text = f"FATIGUE WARNING: index {sess.fatigue_index:.0f}/100"

                        if sess.fatigue_index >= FATIGUE_STOP_INDEX:
                            sess.fatigue_stop_streak += 1
                        else:
                            sess.fatigue_stop_streak = 0

                        if sess.fatigue_stop_streak >= FATIGUE_STOP_STREAK:
                            sess.fatigue_flag = 1
                            sess.stopped = True

                            since = sess.fatigue_since_rep if sess.fatigue_since_rep is not None else int(rep_sum["rep"])
                            issues = top_set_issues(sess.set_counts)
                            issues_str = ", ".join([f"{n} x{c}" for n, c in issues]) if issues else "no dominant issue"
                            msg = (
                                f"Stop recommended. Strong fatigue detected since Rep {since}. "
                                f"Top issues: {issues_str}. Please rest or reduce weight."
                            )
                            sess.feedback.append({
                                "feedback_type": "fatigue",
                                "severity": "warning",
                                "feedback_text": msg,
                                "meta": {"since_rep": int(since), "top_issues": issues, "fatigue_index": float(sess.fatigue_index)}
                            })

                    # --- ML softness (rolling baseline) ---
                    sess.score_hist.append(float(score))
                    use_relative = (len(sess.score_hist) >= ML_MIN_SCORES_FOR_REL)
                    score_ref = float(np.median(sess.score_hist)) if use_relative else float(self.thr)

                    ml_low_rel = use_relative and (score < (score_ref - ML_REL_DROP))
                    ml_low_abs = (score < (self.thr - ML_MARGIN))
                    ml_low = ml_low_rel if use_relative else ml_low_abs

                    sess.ml_low_streak = sess.ml_low_streak + 1 if ml_low else 0
                    ml_tip = (sess.ml_low_streak >= ML_LOW_STREAK_FOR_TIP)

                    rep_tips = []
                    if sess.fatigue_text:
                        rep_tips.append("Fatigue trend - consider rest or lighter weight")
                    if sess.baseline_ready:
                        if rep_sum["rom"] < 0.55 * sess.baseline["rom"]:
                            rep_tips.append("ROM is dropping - lighten weight or rest")
                    else:
                        if rep_sum["rom"] < 45:
                            rep_tips.append("Try a fuller range of motion (if comfortable)")
                    if sess.baseline_ready and rep_sum["duration"] > 1.8 * sess.baseline["duration"]:
                        rep_tips.append("Tempo slowing - stay controlled")
                    if ml_tip:
                        rep_tips.append("Consistency drifting (ML)")

                    rep_bad_reason = rep_sum.get("rep_bad_reason", "")
                    rep_tip_reason = rep_sum.get("rep_tip_reason", "")

                    rep_n = int(rep_sum["rep"])
                    reasons: List[str] = []
                    if rep_sum.get("rep_bad_seen", False):
                        reasons.append(rep_bad_reason or "unsafe form")
                    if rep_sum.get("rep_tip_seen", False) and rep_tip_reason:
                        reasons.append(rep_tip_reason)
                    for t in rep_tips[:2]:
                        reasons.append(t)

                    # last_rep_text (golden style)
                    if rep_sum.get("rep_bad_seen", False):
                        sess.last_rep_text = f"Rep {rep_n}: UNSAFE - {rep_bad_reason or 'adjust form'}"
                        sess.last_rep_color = BAD_COLOR
                    else:
                        any_tip = rep_sum.get("rep_tip_seen", False) or ml_tip
                        if any_tip:
                            reason = rep_tip_reason if rep_tip_reason else (rep_tips[0] if rep_tips else "small adjustment")
                            sess.last_rep_text = f"Rep {rep_n}: COACHING - {reason}"
                            sess.last_rep_color = WARN_COLOR
                        else:
                            msg = random.choice(PRAISE_LINES)
                            if random.random() < 0.40:
                                msg += " " + random.choice(GENERAL_TIPS)
                            sess.last_rep_text = f"Rep {rep_n}: {msg}"
                            sess.last_rep_color = GOOD_COLOR

                    # ---- Rep label rules ----
                    # bad (unsafe) overrides everything
                    rep_bad = bool(rep_sum.get("rep_bad_seen", False))

                    # warning = not bad, but any tip happened DURING rep OR ML tip OR any rep_tips (tempo/ROM/fatigue)
                    rep_warn = (not rep_bad) and (
                        bool(rep_sum.get("rep_tip_seen", False)) or
                        bool(ml_tip) or
                        (len(rep_tips) > 0)
                    )

                    if rep_bad:
                        form_label = "bad"
                    elif rep_warn:
                        form_label = "warning"
                    else:
                        form_label = "good"

                    # "anomaly_score" in your DB schema can store the OCSVM decision_function
                    anomaly_score = float(score)

                    sess.reps.append({
                        "rep_index": rep_n,
                        "duration_ms": int(round(rep_sum["duration"] * 1000)),
                        "rom_score": float(rep_sum["rom"]),
                        "trunk_sway": 0.0,  # bicep curl uses elbow drift; trunk placeholder
                        "confidence_avg": float(rep_sum.get("confidence_avg", 0.0)),
                        "form_label": form_label,
                        "anomaly_score": anomaly_score,
                        "meta": {
                            "elbow_drift_absmax": float(drift_clip),
                            "rep_tip_seen": bool(rep_sum.get("rep_tip_seen", False)),
                            "rep_bad_seen": bool(rep_sum.get("rep_bad_seen", False)),
                            "reasons": reasons[:4],
                            "fatigue_index": float(sess.fatigue_index),
                        }
                    })

                    # feedback table rows (optional)
                    if rep_sum.get("rep_bad_seen", False):
                        sess.feedback.append({
                            "feedback_type": "posture",
                            "severity": "danger",
                            "feedback_text": rep_bad_reason or "Unsafe form detected",
                            "meta": {"rep": rep_n}
                        })
                    elif reasons:
                        # coaching/info
                        sess.feedback.append({
                            "feedback_type": "posture",
                            "severity": "warning" if ("COACHING" in sess.last_rep_text) else "info",
                            "feedback_text": reasons[0],
                            "meta": {"rep": rep_n, "all": reasons[:4]}
                        })

                    # optional debug status mirror
                    issues = top_set_issues(sess.set_counts)
                    issues_str = ", ".join([f"{n} x{c}" for n, c in issues]) if issues else "no major issues"
                    write_status({
                        "state": "stop" if sess.stopped else "running",
                        "exercise": "bicep_curl",
                        "rep_now": rep_n,
                        "last_rep_text": sess.last_rep_text,
                        "last_rep_reasons": reasons[:4],
                        "score": float(score),
                        "threshold": float(self.thr),
                        "fatigue_index": float(sess.fatigue_index),
                        "fatigue_warning": bool(sess.fatigue_text),
                        "message": "Active",
                        "baseline_ready": bool(sess.baseline_ready),
                        "set_summary": sess.set_counts,
                        "set_top_issues": issues,
                        "set_top_issues_text": issues_str,
                        "recent_reps": [],  # you can add if you want
                        "fatigue_details": sess.fatigue_details,
                    })

            else:
                sess.set_counts["low_conf"] += 1
                feedback = f"Tracking quality low ({conf_mean:.2f})"
                fb_color = WARN_COLOR
        else:
            # no landmarks
            sess.set_counts["low_conf"] += 1
            feedback = "No pose detected"
            fb_color = WARN_COLOR

        # overlays (match golden style positions)
        if DRAW_TEXT_OVERLAY:
            cv2.putText(frame_bgr, feedback, (10, h - 110),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, fb_color, 2)
            if sess.fatigue_text:
                cv2.putText(frame_bgr, sess.fatigue_text, (10, h - 75),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, WARN_COLOR, 2)
            cv2.putText(frame_bgr, sess.last_rep_text, (10, h - 35),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, sess.last_rep_color, 2)

        issues = top_set_issues(sess.set_counts)
        issues_str = ", ".join([f"{n} x{c}" for n, c in issues]) if issues else "no major issues"

        status = {
            "state": "stop" if sess.stopped else "running",
            "exercise": "bicep_curl",
            "rep_now": int(sess.rep_counter.rep_count),
            "last_rep_text": sess.last_rep_text,
            "fatigue_index": float(sess.fatigue_index),
            "fatigue_warning": bool(sess.fatigue_text),
            "baseline_ready": bool(sess.baseline_ready),
            "set_top_issues_text": issues_str,
            "conf": float(sess.conf_last),
        }

        return frame_bgr, status


PIPE = BicepCurlPipeline()
SESSIONS: Dict[str, BicepCurlSession] = {}


# ----------------------------- FASTAPI CONTRACT -----------------------------
class StartReq(BaseModel):
    exercise_type: str
    log_id: int
    user_id: int


class FrameReq(BaseModel):
    session_token: str
    frame_dataurl: str


class FinishReq(BaseModel):
    session_token: str


app = FastAPI(title="LiftRight Realtime Server", version=VERSION)

# dev-safe CORS (PHP calls this server via curl, but browser calls PHP; still safe to allow)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"ok": True, "version": VERSION}


@app.post("/start")
def start(req: StartReq):
    ex = (req.exercise_type or "").strip().lower()
    if ex != "bicep_curl":
        return {"ok": False, "error": "This server build supports bicep_curl only."}

    token = uuid.uuid4().hex
    sess = BicepCurlSession(
        session_token=token,
        user_id=int(req.user_id),
        log_id=int(req.log_id),
        exercise_type="bicep_curl",
    )
    SESSIONS[token] = sess

    write_status({"state": "running", "exercise": "bicep_curl", "message": "Session started", "log_id": sess.log_id})
    return {"session_token": token}


@app.post("/frame")
def frame(req: FrameReq):
    token = (req.session_token or "").strip()
    sess = SESSIONS.get(token)
    if not sess:
        return {"ok": False, "error": "Invalid session_token."}

    img = decode_dataurl_to_bgr(req.frame_dataurl)
    if img is None:
        return {"ok": False, "error": "Could not decode frame_dataurl."}

    annotated, status = PIPE.process(img, sess)
    out = bgr_to_dataurl_jpeg(annotated, quality=80)

    return {
        "annotated_frame_dataurl": out,
        "status": status
    }


@app.post("/finish")
def finish(req: FinishReq):
    token = (req.session_token or "").strip()
    sess = SESSIONS.pop(token, None)
    if not sess:
        return {"ok": False, "error": "Invalid session_token."}

    reps_total = len(sess.reps)
    reps_bad = sum(1 for r in sess.reps if (r.get("form_label") == "bad"))
    reps_warn = sum(1 for r in sess.reps if (r.get("form_label") == "warning"))
    # warnings count as "good" (not unsafe)
    reps_good = reps_total - reps_bad

    # form_error_count: count posture feedback "danger" entries
    form_error_count = sum(1 for f in sess.feedback if f.get("severity") == "danger")

    payload = {
    "reps_total": int(reps_total),
    "reps_good": int(reps_good),
    "reps_bad": int(reps_bad),
    "reps_warn": int(reps_warn),
    "form_error_count": int(form_error_count),
    "fatigue_flag": int(sess.fatigue_flag),
    "reps": sess.reps,
    "feedback": sess.feedback,
    }   


    write_status({"state": "finished", "exercise": "bicep_curl", "message": "Session finished", "reps_total": reps_total})
    return payload


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=5101, log_level="info")
