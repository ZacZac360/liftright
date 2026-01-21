# ml/scripts/04_live_bicep_curl.py
import cv2
import numpy as np
import mediapipe as mp
import joblib
import time
import random
import json
from collections import deque
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
MODEL_PKL = PROJECT_ROOT / "models" / "bicep_curl_ocsvm.pkl"
OUT_DIR = PROJECT_ROOT / "outputs"
OUT_DIR.mkdir(parents=True, exist_ok=True)
STATUS_JSON = OUT_DIR / "bicep_curl_status.json"

CAM_INDEX = 0
MIN_CONF = 0.50

# Rep detection thresholds
TOP_THR = 75
BOT_THR = 155
SMOOTH_N = 7
MIN_REP_TIME = 0.35

# --- Very permissive elbow drift thresholds (main posture focus) ---
ELBOW_DRIFT_WARN = 0.35
ELBOW_DRIFT_BAD  = 0.55

# Personalization / fatigue
CALIB_REPS = 5
FATIGUE_WINDOW = 6

# ---------------- ML softness ----------------
ML_MARGIN = 0.030
ML_LOW_STREAK_FOR_TIP = 3

# ✅ FIX: rolling ML baseline so "Consistency drifting" clears once YOU recover
ML_SCORE_WINDOW = 8        # compare against this many recent reps
ML_REL_DROP = 0.020        # sensitivity: bigger = less warnings (0.02–0.03 typical)
ML_MIN_SCORES_FOR_REL = 4  # wait until we have enough history

# Fatigue severity (0-100 index)
FATIGUE_WARN_INDEX = 55     # show fatigue warning overlay
FATIGUE_STOP_INDEX = 80     # hard-stop if sustained high fatigue
FATIGUE_STOP_STREAK = 2     # must hit STOP threshold N reps in a row

GOOD_COLOR = (0, 255, 0)
WARN_COLOR = (0, 255, 255)
BAD_COLOR  = (0, 0, 255)
TEXT_COLOR = (240, 240, 240)

# Neutral skeleton color (dim gray)
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


def write_status(payload):
    """
    Writes a small JSON your web app can read.
    Safe to overwrite every update.
    """
    try:
        payload = dict(payload)
        payload["timestamp"] = time.time()
        STATUS_JSON.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    except Exception:
        pass


def calculate_angle(a, b, c):
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


def safe_div(a, b, eps=1e-6):
    return float(a / (b + eps))


def median_or(x, fallback):
    x = [v for v in x if np.isfinite(v)]
    return float(np.median(x)) if len(x) else float(fallback)


def draw_skeleton_neutral(frame, pose_landmarks):
    if pose_landmarks is None:
        return
    spec = mp_draw.DrawingSpec(color=NEUTRAL_COLOR, thickness=2, circle_radius=2)
    mp_draw.draw_landmarks(
        frame,
        pose_landmarks,
        mp_pose.POSE_CONNECTIONS,
        landmark_drawing_spec=spec,
        connection_drawing_spec=spec
    )


def draw_segment(frame, pose_landmarks, a, b, color, thickness=6):
    """
    Draw a single connection (a-b) thick and colored.
    a, b are PoseLandmark enums.
    """
    if pose_landmarks is None:
        return
    lm = pose_landmarks.landmark
    pa = lm[a].x, lm[a].y
    pb = lm[b].x, lm[b].y
    h, w = frame.shape[:2]
    ax, ay = int(pa[0] * w), int(pa[1] * h)
    bx, by = int(pb[0] * w), int(pb[1] * h)
    cv2.line(frame, (ax, ay), (bx, by), color, thickness)


def highlight_issues(frame, pose_landmarks, right_elbow_level, left_elbow_level):
    """
    Selectively highlight only the problematic parts.
    right_elbow_level: 0 none, 1 warn, 2 bad
    left_elbow_level: 0 none, 1 warn, 2 bad
    """
    if pose_landmarks is None:
        return

    # Right arm
    if right_elbow_level > 0:
        c = WARN_COLOR if right_elbow_level == 1 else BAD_COLOR
        draw_segment(frame, pose_landmarks, mp_pose.PoseLandmark.RIGHT_SHOULDER, mp_pose.PoseLandmark.RIGHT_ELBOW, c)
        draw_segment(frame, pose_landmarks, mp_pose.PoseLandmark.RIGHT_ELBOW, mp_pose.PoseLandmark.RIGHT_WRIST, c)

    # Left arm
    if left_elbow_level > 0:
        c = WARN_COLOR if left_elbow_level == 1 else BAD_COLOR
        draw_segment(frame, pose_landmarks, mp_pose.PoseLandmark.LEFT_SHOULDER, mp_pose.PoseLandmark.LEFT_ELBOW, c)
        draw_segment(frame, pose_landmarks, mp_pose.PoseLandmark.LEFT_ELBOW, mp_pose.PoseLandmark.LEFT_WRIST, c)


class CurlRepCounter:
    """
    Tracks reps and stores per-rep arrays.
    Also stores whether ANY tip/bad happened during the rep (not just last frame).
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
        self.drift = []  # drift for rep-arm only (the one used for counting)

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

    def update(self, elbow_angle, elbow_drift_norm):
        now = time.time()
        self.buf.append(float(elbow_angle))
        ang_s = float(np.median(self.buf))

        self.angles.append(ang_s)
        self.drift.append(float(elbow_drift_norm))

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

                    rep_summary = {
                        "rep": self.rep_count,
                        "min_angle": float(angles.min()),
                        "max_angle": float(angles.max()),
                        "rom": float(angles.max() - angles.min()),
                        "duration": float(now - self.rep_start_t),
                        "elbow_drift_absmax": float(np.max(drift)),

                        "rep_tip_seen": bool(self.rep_tip_seen),
                        "rep_bad_seen": bool(self.rep_bad_seen),
                        "rep_tip_reason": str(self.rep_tip_reason),
                        "rep_bad_reason": str(self.rep_bad_reason),
                    }

                self.state = "down"
                self.reset_rep(now)

        return ang_s, rep_done, rep_summary


def compute_fatigue_index(baseline, rom_med, dur_med, drift_med):
    """
    Returns (index_0_100, components_dict)
    Higher = more fatigue/compensation.
    """
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
    left_total = set_counts["elbow_bad_left"] + set_counts["elbow_warn_left"]

    if right_total > 0:
        items.append(("right elbow drift", right_total))
    if left_total > 0:
        items.append(("left elbow drift", left_total))
    if set_counts["low_conf"] > 0:
        items.append(("tracking low", set_counts["low_conf"]))

    items.sort(key=lambda x: x[1], reverse=True)
    return items[:2]


def main():
    write_status({"state": "running", "message": "Bicep curl tracking active."})

    bundle = joblib.load(MODEL_PKL)
    scaler = bundle["scaler"]
    model  = bundle["model"]
    feats  = bundle["features"]
    thr    = float(bundle["threshold"])

    print("Loaded model:", bundle.get("exercise"))
    print("Features:", feats)
    print("Threshold:", thr)

    cap = cv2.VideoCapture(CAM_INDEX)
    if not cap.isOpened():
        print("Could not open webcam.")
        write_status({"state": "error", "message": "Could not open webcam."})
        return

    rep_counter = CurlRepCounter()

    calib = []
    baseline_ready = False
    baseline = {"rom": None, "duration": None, "drift": None}

    recent = deque(maxlen=FATIGUE_WINDOW)

    set_counts = {
        "elbow_warn_right": 0,
        "elbow_bad_right": 0,
        "elbow_warn_left": 0,
        "elbow_bad_left": 0,
        "low_conf": 0,
    }
    rep_history = []

    # ML tracking
    ml_low_streak = 0
    score_hist = deque(maxlen=ML_SCORE_WINDOW)  # ✅ rolling score baseline

    fatigue_stop_streak = 0

    last_rep_text = "-"
    last_rep_color = TEXT_COLOR

    fatigue_text = ""
    fatigue_color = TEXT_COLOR
    fatigue_index = 0.0
    fatigue_since_rep = None

    with mp_pose.Pose(
        static_image_mode=False,
        model_complexity=1,
        smooth_landmarks=True,
        enable_segmentation=False,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5,
    ) as pose:

        while True:
            ok, frame = cap.read()
            if not ok:
                break

            h, w = frame.shape[:2]
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            res = pose.process(rgb)

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

                draw_skeleton_neutral(frame, res.pose_landmarks)

                if conf_mean >= MIN_CONF:
                    shoulder_width = abs(LSH[0] - RSH[0])
                    if shoulder_width < 2:
                        shoulder_width = 2

                    # Compute BOTH arms every frame (dynamic highlighting)
                    right_angle = calculate_angle((RSH[0], RSH[1]), (REL[0], REL[1]), (RWR[0], RWR[1]))
                    left_angle  = calculate_angle((LSH[0], LSH[1]), (LEL[0], LEL[1]), (LWR[0], LWR[1]))

                    right_drift_norm = safe_div(abs(REL[0] - RSH[0]), shoulder_width)
                    left_drift_norm  = safe_div(abs(LEL[0] - LSH[0]), shoulder_width)

                    # Choose rep-arm ONLY for rep counting stability
                    use_right_for_rep = (REL[2] >= LEL[2])
                    elbow_angle_for_rep = right_angle if use_right_for_rep else left_angle
                    elbow_drift_for_rep = right_drift_norm if use_right_for_rep else left_drift_norm

                    bad = []
                    tips = []

                    # Elbow levels per side (dynamic)
                    if right_drift_norm > ELBOW_DRIFT_BAD:
                        right_elbow_level = 2
                        set_counts["elbow_bad_right"] += 1
                    elif right_drift_norm > ELBOW_DRIFT_WARN:
                        right_elbow_level = 1
                        set_counts["elbow_warn_right"] += 1

                    if left_drift_norm > ELBOW_DRIFT_BAD:
                        left_elbow_level = 2
                        set_counts["elbow_bad_left"] += 1
                    elif left_drift_norm > ELBOW_DRIFT_WARN:
                        left_elbow_level = 1
                        set_counts["elbow_warn_left"] += 1

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

                    highlight_issues(frame, res.pose_landmarks, right_elbow_level, left_elbow_level)

                    if bad:
                        feedback = "UNSAFE: " + bad[0]
                        fb_color = BAD_COLOR
                    elif tips:
                        feedback = "COACHING: " + tips[0]
                        fb_color = WARN_COLOR
                    else:
                        feedback = "STATUS: Stable"
                        fb_color = GOOD_COLOR

                    if rep_counter.state == "up":
                        rep_counter.mark_feedback(bad, tips)

                    elbow_s, rep_done, rep_sum = rep_counter.update(
                        elbow_angle_for_rep, elbow_drift_for_rep
                    )

                    if rep_done and rep_sum:
                        drift_clip = min(rep_sum["elbow_drift_absmax"], 0.70)

                        feat_map = {
                            "rom": rep_sum["rom"],
                            "duration": rep_sum["duration"],
                            "elbow_drift_absmax": drift_clip,
                        }

                        # Keep your current feature contract
                        if "trunk_absmax" in feats:
                            feat_map["trunk_absmax"] = 0.0  # neutral placeholder

                        x = np.array([[feat_map[f] for f in feats]], dtype=np.float32)
                        xs = scaler.transform(x)
                        score = float(model.decision_function(xs)[0])

                        recent.append({
                            "rom": rep_sum["rom"],
                            "duration": rep_sum["duration"],
                            "drift": drift_clip,
                            "score": score
                        })

                        if not baseline_ready and not rep_sum["rep_bad_seen"]:
                            calib.append(recent[-1])
                            if len(calib) >= CALIB_REPS:
                                baseline["rom"] = median_or([r["rom"] for r in calib], 120.0)
                                baseline["duration"] = median_or([r["duration"] for r in calib], 1.5)
                                baseline["drift"] = median_or([r["drift"] for r in calib], 0.14)
                                baseline_ready = True

                        fatigue_text = ""
                        fatigue_color = TEXT_COLOR
                        comps = {}

                        if baseline_ready and len(recent) >= 4:
                            last3 = list(recent)[-3:]
                            rom_med = median_or([r["rom"] for r in last3], baseline["rom"])
                            dur_med = median_or([r["duration"] for r in last3], baseline["duration"])
                            drift_med = median_or([r["drift"] for r in last3], baseline["drift"])

                            fatigue_index, comps = compute_fatigue_index(baseline, rom_med, dur_med, drift_med)

                            if fatigue_since_rep is None and fatigue_index >= FATIGUE_WARN_INDEX:
                                fatigue_since_rep = rep_sum["rep"]

                            if fatigue_index >= FATIGUE_WARN_INDEX:
                                fatigue_text = f"FATIGUE WARNING: index {fatigue_index:.0f}/100"
                                fatigue_color = WARN_COLOR

                            if fatigue_index >= FATIGUE_STOP_INDEX:
                                fatigue_stop_streak += 1
                            else:
                                fatigue_stop_streak = 0

                            if fatigue_stop_streak >= FATIGUE_STOP_STREAK:
                                since = fatigue_since_rep if fatigue_since_rep is not None else rep_sum["rep"]
                                issues = top_set_issues(set_counts)
                                issues_str = ", ".join([f"{n} x{c}" for n, c in issues]) if issues else "no dominant issue"

                                msg = (
                                    f"Stop recommended. Strong fatigue detected since Rep {since}. "
                                    f"Top issues: {issues_str}. Please rest or reduce weight."
                                )

                                write_status({
                                    "state": "stop",
                                    "exercise": "bicep_curl",
                                    "rep_now": int(rep_sum["rep"]),
                                    "fatigue_index": float(fatigue_index),
                                    "since_rep": int(since),
                                    "message": msg,
                                    "details": comps,
                                    "set_summary": set_counts,
                                    "top_issues": issues,
                                })

                                cap.release()
                                cv2.destroyAllWindows()
                                return

                        # ---------------- ML softness (rolling baseline) ----------------
                        score_hist.append(float(score))

                        use_relative = (len(score_hist) >= ML_MIN_SCORES_FOR_REL)
                        score_ref = float(np.median(score_hist)) if use_relative else float(thr)

                        # Relative drop from your own recent typical score
                        ml_low_rel = use_relative and (score < (score_ref - ML_REL_DROP))

                        # Fallback (early reps): absolute threshold
                        ml_low_abs = (score < (thr - ML_MARGIN))

                        ml_low = ml_low_rel if use_relative else ml_low_abs

                        ml_low_streak = ml_low_streak + 1 if ml_low else 0
                        ml_tip = (ml_low_streak >= ML_LOW_STREAK_FOR_TIP)

                        rep_tips = []
                        if fatigue_text:
                            rep_tips.append("Fatigue trend - consider rest or lighter weight")

                        if baseline_ready:
                            if rep_sum["rom"] < 0.55 * baseline["rom"]:
                                rep_tips.append("ROM is dropping - lighten weight or rest")
                        else:
                            if rep_sum["rom"] < 45:
                                rep_tips.append("Try a fuller range of motion (if comfortable)")

                        if baseline_ready and rep_sum["duration"] > 1.8 * baseline["duration"]:
                            rep_tips.append("Tempo slowing - stay controlled")

                        if ml_tip:
                            rep_tips.append("Consistency drifting (ML)")

                        rep_bad_reason = rep_sum.get("rep_bad_reason", "")
                        rep_tip_reason = rep_sum.get("rep_tip_reason", "")

                        rep_n = int(rep_sum["rep"])
                        reasons = []

                        if rep_sum.get("rep_bad_seen", False):
                            reasons.append(rep_bad_reason or "unsafe form")
                        if rep_sum.get("rep_tip_seen", False) and rep_tip_reason:
                            reasons.append(rep_tip_reason)
                        for t in rep_tips[:2]:
                            reasons.append(t)

                        if rep_sum.get("rep_bad_seen", False):
                            last_rep_text = f"Rep {rep_n}: UNSAFE - {rep_bad_reason or 'adjust form'}"
                            last_rep_color = BAD_COLOR
                        else:
                            any_tip = rep_sum.get("rep_tip_seen", False) or ml_tip
                            if any_tip:
                                reason = rep_tip_reason if rep_tip_reason else (rep_tips[0] if rep_tips else "small adjustment")
                                last_rep_text = f"Rep {rep_n}: COACHING - {reason}"
                                last_rep_color = WARN_COLOR
                            else:
                                msg = random.choice(PRAISE_LINES)
                                if random.random() < 0.40:
                                    msg += " " + random.choice(GENERAL_TIPS)
                                last_rep_text = f"Rep {rep_n}: {msg}"
                                last_rep_color = GOOD_COLOR

                        rep_history.append({
                            "rep": rep_n,
                            "text": last_rep_text,
                            "reasons": reasons[:4],
                            "fatigue_index": float(fatigue_index),
                            "score": float(score),
                        })
                        rep_history = rep_history[-8:]

                        issues = top_set_issues(set_counts)
                        issues_str = ", ".join([f"{n} x{c}" for n, c in issues]) if issues else "no major issues"

                        write_status({
                            "state": "running",
                            "exercise": "bicep_curl",
                            "rep_now": rep_n,
                            "last_rep_text": last_rep_text,
                            "last_rep_reasons": reasons[:4],
                            "score": float(score),
                            "threshold": float(thr),
                            "fatigue_index": float(fatigue_index),
                            "fatigue_warning": bool(fatigue_text),
                            "message": "Active",
                            "baseline_ready": bool(baseline_ready),
                            "set_summary": set_counts,
                            "set_top_issues": issues,
                            "set_top_issues_text": issues_str,
                            "recent_reps": rep_history[-5:],
                            "fatigue_details": comps,
                        })

                else:
                    set_counts["low_conf"] += 1
                    feedback = f"Tracking quality low ({conf_mean:.2f})"
                    fb_color = WARN_COLOR

            cv2.putText(frame, feedback, (10, h - 110),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, fb_color, 2)

            if fatigue_text:
                cv2.putText(frame, fatigue_text, (10, h - 75),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, fatigue_color, 2)
            cv2.putText(frame, last_rep_text, (10, h - 35),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, last_rep_color, 2)

            cv2.imshow("LiftRight - Bicep Curl", frame)
            key = cv2.waitKey(1) & 0xFF
            if key == 27 or key == ord("q"):
                write_status({"state": "stopped", "message": "User closed the tracker."})
                break

    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
