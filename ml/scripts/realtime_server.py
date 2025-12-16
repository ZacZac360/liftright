import base64
import time
import uuid
from dataclasses import dataclass, field
from typing import Dict, Any, List, Optional

import cv2
import numpy as np
import joblib
import mediapipe as mp

from fastapi import FastAPI
from pydantic import BaseModel

from pathlib import Path

# ---------------- CONFIG (shared) ----------------
MIN_CONF = 0.5

SMOOTH_N = 7
MIN_REP_TIME = 0.35
MAX_REP_TIME = 6.0

# BICEP CURL thresholds (your MVP)
BC_TOP_THR = 75
BC_BOT_THR = 155

# Press/Raise baseline-based thresholds (your MVP style)
BASELINE_FRAMES = 30
DOWN_OFFSET = 0.02
SP_UP_OFFSET = 0.25
LR_UP_OFFSET = 0.20

# continuous rules (tune later)
TRUNK_BAD = 0.12
ASYM_BAD = 0.25
ELBOW_DRIFT_BAD = 0.18          # bicep
ELBOW_TOO_BENT = 120.0          # lateral raise

# Fatigue heuristic (prototype)
FATIGUE_TRUNK_FLAG = 0.25
FATIGUE_ROM_FLAG   = 0.60

# Project paths
PROJECT_ROOT = Path(__file__).resolve().parents[2]  # .../liftright
MODEL_DIR = PROJECT_ROOT / "ml" / "models"

MODEL_PATHS = {
    "bicep_curl": MODEL_DIR / "bicep_curl_ocsvm.pkl",
    "shoulder_press": MODEL_DIR / "shoulder_press_ocsvm.pkl",
    "lateral_raise": MODEL_DIR / "lateral_raise_ocsvm.pkl",
}

# ---------------- MEDIAPIPE ----------------
mp_pose = mp.solutions.pose

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

def pt2(xyv):
    return [float(xyv[0]), float(xyv[1])]

def round2(x):
    return None if x is None else float(round(float(x), 2))

def decode_dataurl_to_bgr(dataurl: str) -> Optional[np.ndarray]:
    if not isinstance(dataurl, str) or not dataurl.startswith("data:"):
        return None
    try:
        _, b64 = dataurl.split(",", 1)
        raw = base64.b64decode(b64)
        arr = np.frombuffer(raw, dtype=np.uint8)
        img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
        return img
    except Exception:
        return None

# ---------------- MODEL LOADING (ALL 3) ----------------
MODELS: Dict[str, Optional[Dict[str, Any]]] = {}
for ex, p in MODEL_PATHS.items():
    if p.exists():
        MODELS[ex] = joblib.load(p)
    else:
        MODELS[ex] = None

def get_model_bundle(exercise_type: str) -> Dict[str, Any]:
    b = MODELS.get(exercise_type)
    if b is None:
        raise FileNotFoundError(f"Model file missing for {exercise_type}: {MODEL_PATHS.get(exercise_type)}")
    return b

# ---------------- REP COUNTERS ----------------
class CurlRepCounter:
    def __init__(self):
        from collections import deque
        self.state = "down"
        self.rep_count = 0
        self.last_rep_t = 0.0
        self.buf = deque(maxlen=SMOOTH_N)
        self.reset_rep(time.time())

    def reset_rep(self, t):
        self.rep_start_t = t
        self.angles = []
        self.trunk = []
        self.conf = []

    def update(self, elbow_angle, trunk_offset_norm, conf_mean):
        now = time.time()
        self.buf.append(float(elbow_angle))
        ang_s = float(np.median(self.buf))

        self.angles.append(ang_s)
        self.trunk.append(float(trunk_offset_norm))
        self.conf.append(float(conf_mean))

        # stuck safety
        if (now - self.rep_start_t) > MAX_REP_TIME:
            self.state = "down"
            self.reset_rep(now)
            self.buf.clear()
            return ang_s, False, None

        rep_done = False
        rep_summary = None

        if self.state == "down":
            if ang_s <= BC_TOP_THR:
                self.state = "up"
        else:
            if ang_s >= BC_BOT_THR:
                if (now - self.last_rep_t) >= MIN_REP_TIME and len(self.angles) >= 6:
                    self.rep_count += 1
                    self.last_rep_t = now
                    rep_done = True

                    angles = np.array(self.angles, dtype=np.float32)
                    trunk  = np.array(self.trunk, dtype=np.float32)
                    confs  = np.array(self.conf, dtype=np.float32)

                    rep_summary = {
                        "rep_index": self.rep_count,
                        "min_angle": float(angles.min()),
                        "max_angle": float(angles.max()),
                        "rom": float(angles.max() - angles.min()),
                        "duration_s": float(now - self.rep_start_t),
                        "trunk_absmax": float(np.max(np.abs(trunk))),
                        "confidence_avg": float(np.mean(confs)) if len(confs) else None,
                    }

                self.state = "down"
                self.reset_rep(now)

        return ang_s, rep_done, rep_summary

class PressRepCounter:
    """
    Shoulder press based on wrist_rel_y = (shoulder_y - wrist_y) / shoulder_width
    baseline learned from first second, rep = down->up->down (rack-to-press-to-rack).
    """
    def __init__(self):
        from collections import deque
        self.buf = deque(maxlen=SMOOTH_N)
        self.state = "down"
        self.rep_count = 0
        self.last_rep_t = 0.0

        self.baseline_samples = []
        self.baseline_ready = False
        self.baseline = 0.10
        self.down_thr = 0.10
        self.up_thr = 0.35

        self.reset_rep(time.time())

    def reset_rep(self, t):
        self.rep_start_t = t
        self.vals = []
        self.trunk = []
        self.conf = []
        self.max_wrist_rel_y = -999.0

    def update_baseline(self, y_s: float):
        if self.baseline_ready:
            return
        self.baseline_samples.append(float(y_s))
        if len(self.baseline_samples) >= BASELINE_FRAMES:
            s = np.array(self.baseline_samples, dtype=np.float32)
            s = s[np.isfinite(s)]
            base_med = float(np.median(s)) if len(s) else 0.10

            # rack guess: median of upper half (helps when starting arms-down then moving to rack)
            s_sorted = np.sort(s) if len(s) else s
            upper_half = s_sorted[len(s_sorted)//2:] if len(s_sorted) else []
            rack_guess = float(np.median(upper_half)) if len(upper_half) else base_med

            if base_med < 0.15 and rack_guess > base_med + 0.10:
                baseline = rack_guess
            else:
                baseline = base_med

            self.baseline = float(baseline)
            self.down_thr = max(0.15, self.baseline - 0.05)  # rack-return threshold
            self.up_thr   = self.down_thr + SP_UP_OFFSET

            self.baseline_ready = True

    def update(self, wrist_rel_y: float, trunk_offset_norm: float, conf_mean: float):
        now = time.time()
        self.buf.append(float(wrist_rel_y))
        y_s = float(np.median(self.buf))

        self.update_baseline(y_s)

        self.vals.append(y_s)
        self.trunk.append(float(trunk_offset_norm))
        self.conf.append(float(conf_mean))
        self.max_wrist_rel_y = max(self.max_wrist_rel_y, y_s)

        # stuck safety
        if (now - self.rep_start_t) > MAX_REP_TIME:
            self.state = "down"
            self.reset_rep(now)
            self.buf.clear()
            return y_s, False, None

        if not self.baseline_ready:
            return y_s, False, None

        rep_done = False
        rep_summary = None

        if self.state == "down":
            if y_s >= self.up_thr:
                self.state = "up"
        else:
            if y_s <= self.down_thr:
                if (now - self.last_rep_t) >= MIN_REP_TIME and len(self.vals) >= 6:
                    self.rep_count += 1
                    self.last_rep_t = now
                    rep_done = True

                    vals = np.array(self.vals, dtype=np.float32)
                    trunk = np.array(self.trunk, dtype=np.float32)

                    rep_summary = {
                        "rep_index": self.rep_count,
                        "min_wrist_rel_y": float(vals.min()),
                        "max_wrist_rel_y": float(vals.max()),
                        "wrist_rel_range": float(vals.max() - vals.min()),
                        "duration_s": float(now - self.rep_start_t),
                        "trunk_absmax": float(np.max(np.abs(trunk))),
                        "baseline": float(self.baseline),
                        "down_thr": float(self.down_thr),
                        "up_thr": float(self.up_thr),
                    }

                self.state = "down"
                self.reset_rep(now)

        return y_s, rep_done, rep_summary

class LateralRepCounter:
    """
    Lateral raise based on wrist_rel_y baseline; rep = down->up->down.
    Also stores elbow angle minimum during rep.
    """
    def __init__(self):
        from collections import deque
        self.buf = deque(maxlen=SMOOTH_N)
        self.state = "down"
        self.rep_count = 0
        self.last_rep_t = 0.0

        self.baseline_samples = []
        self.baseline_ready = False
        self.baseline = 0.05
        self.down_thr = 0.05
        self.up_thr = 0.25

        self.reset_rep(time.time())

    def reset_rep(self, t):
        self.rep_start_t = t
        self.vals = []
        self.trunk = []
        self.elbow = []
        self.conf = []
        self.max_wrist_rel_y = -999.0

    def update_baseline(self, y_s: float):
        if self.baseline_ready:
            return
        self.baseline_samples.append(float(y_s))
        if len(self.baseline_samples) >= BASELINE_FRAMES:
            s = np.array(self.baseline_samples, dtype=np.float32)
            s = s[np.isfinite(s)]
            base = float(np.median(s)) if len(s) else 0.05

            self.baseline = float(base)
            self.down_thr = max(0.02, self.baseline + DOWN_OFFSET)
            self.up_thr   = self.down_thr + LR_UP_OFFSET
            self.baseline_ready = True

    def update(self, wrist_rel_y: float, trunk_offset_norm: float, elbow_angle: float, conf_mean: float):
        now = time.time()
        self.buf.append(float(wrist_rel_y))
        y_s = float(np.median(self.buf))

        self.update_baseline(y_s)

        self.vals.append(y_s)
        self.trunk.append(float(trunk_offset_norm))
        self.elbow.append(float(elbow_angle))
        self.conf.append(float(conf_mean))
        self.max_wrist_rel_y = max(self.max_wrist_rel_y, y_s)

        # stuck safety
        if (now - self.rep_start_t) > MAX_REP_TIME:
            self.state = "down"
            self.reset_rep(now)
            self.buf.clear()
            return y_s, False, None

        if not self.baseline_ready:
            return y_s, False, None

        rep_done = False
        rep_summary = None

        if self.state == "down":
            if y_s >= self.up_thr:
                self.state = "up"
        else:
            if y_s <= self.down_thr:
                if (now - self.last_rep_t) >= MIN_REP_TIME and len(self.vals) >= 6:
                    self.rep_count += 1
                    self.last_rep_t = now
                    rep_done = True

                    vals = np.array(self.vals, dtype=np.float32)
                    trunk = np.array(self.trunk, dtype=np.float32)
                    elbow = np.array(self.elbow, dtype=np.float32)

                    rep_summary = {
                        "rep_index": self.rep_count,
                        "min_wrist_rel_y": float(vals.min()),
                        "max_wrist_rel_y": float(vals.max()),
                        "wrist_rel_range": float(vals.max() - vals.min()),
                        "duration_s": float(now - self.rep_start_t),
                        "trunk_absmax": float(np.max(np.abs(trunk))),
                        "elbow_min": float(np.min(elbow)) if len(elbow) else None,
                        "baseline": float(self.baseline),
                        "down_thr": float(self.down_thr),
                        "up_thr": float(self.up_thr),
                    }

                self.state = "down"
                self.reset_rep(now)

        return y_s, rep_done, rep_summary

# ---------------- SESSION STATE ----------------
@dataclass
class LiveSession:
    session_token: str
    exercise_type: str
    user_id: int
    log_id: int
    started_t: float = field(default_factory=time.time)

    rep_counter: Any = None

    reps: List[Dict[str, Any]] = field(default_factory=list)
    feedback: List[Dict[str, Any]] = field(default_factory=list)

    reps_good: int = 0
    reps_bad: int = 0
    form_error_count: int = 0
    fatigue_flag: int = 0

    last_rep_text: str = "—"
    last_rep_score: Optional[float] = None

sessions: Dict[str, LiveSession] = {}

pose = mp_pose.Pose(
    static_image_mode=False,
    model_complexity=1,
    smooth_landmarks=True,
    enable_segmentation=False,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5,
)

# ---------------- FASTAPI ----------------
app = FastAPI(title="LiftRight Realtime Server")

class StartIn(BaseModel):
    exercise_type: str
    log_id: int
    user_id: int

class FrameIn(BaseModel):
    session_token: str
    frame_dataurl: str

class FinishIn(BaseModel):
    session_token: str

@app.post("/start")
def start(payload: StartIn):
    ex = payload.exercise_type

    if ex not in ("bicep_curl", "shoulder_press", "lateral_raise"):
        return {"session_token": "", "message": "Invalid exercise_type."}

    try:
        _ = get_model_bundle(ex)
    except Exception as e:
        return {"session_token": "", "message": str(e)}

    token = uuid.uuid4().hex

    sess = LiveSession(
        session_token=token,
        exercise_type=ex,
        user_id=payload.user_id,
        log_id=payload.log_id,
    )

    if ex == "bicep_curl":
        sess.rep_counter = CurlRepCounter()
    elif ex == "shoulder_press":
        sess.rep_counter = PressRepCounter()
    elif ex == "lateral_raise":
        sess.rep_counter = LateralRepCounter()

    sessions[token] = sess
    return {"session_token": token}

@app.post("/frame")
def frame(payload: FrameIn):
    sess = sessions.get(payload.session_token)
    if not sess:
        return {"message": "Invalid session_token."}

    img = decode_dataurl_to_bgr(payload.frame_dataurl)
    if img is None:
        return {"message": "Bad frame."}

    h, w = img.shape[:2]
    rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    res = pose.process(rgb)

    feedback = "No pose"
    fb_sev = "warning"
    conf_mean = None

    reps_count = sess.rep_counter.rep_count if sess.rep_counter else 0
    state = sess.rep_counter.state if sess.rep_counter else "—"

    elbow_s = None  # bicep only
    skeleton = None
    guides = None

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

        # overlay geometry always if landmarks exist
        skeleton = {
            "left_shoulder": pt2(LSH),
            "right_shoulder": pt2(RSH),
            "left_elbow": pt2(LEL),
            "right_elbow": pt2(REL),
            "left_wrist": pt2(LWR),
            "right_wrist": pt2(RWR),
            "left_hip": pt2(LHP),
            "right_hip": pt2(RHP),
        }

        shoulder_mid = [float((LSH[0] + RSH[0]) / 2.0), float((LSH[1] + RSH[1]) / 2.0)]
        hip_mid      = [float((LHP[0] + RHP[0]) / 2.0), float((LHP[1] + RHP[1]) / 2.0)]
        shoulder_width = float(max(abs(LSH[0] - RSH[0]), 2.0))

        guides = {
            "shoulder_mid": shoulder_mid,
            "hip_mid": hip_mid,
            "shoulder_width": shoulder_width,
            "threshold_lines": None,  # filled when baseline ready for SP/LR
        }

        if conf_mean >= MIN_CONF:
            # trunk offset
            mid_sh_x = (LSH[0] + RSH[0]) / 2.0
            mid_hp_x = (LHP[0] + RHP[0]) / 2.0
            trunk_offset_norm = safe_div((mid_sh_x - mid_hp_x), shoulder_width)

            # wrist_rel_y for SP/LR (both arms)
            R_wrist_rel_y = safe_div((RSH[1] - RWR[1]), shoulder_width)
            L_wrist_rel_y = safe_div((LSH[1] - LWR[1]), shoulder_width)
            wrist_asym = float(abs(R_wrist_rel_y - L_wrist_rel_y))

            # choose best side by wrist visibility
            use_right = (RWR[2] >= LWR[2])

            # compute elbow angle for chosen arm (for bicep + lateral)
            if use_right:
                elbow_angle = calculate_angle((RSH[0], RSH[1]), (REL[0], REL[1]), (RWR[0], RWR[1]))
                elbow_drift = abs(REL[0] - RSH[0])
                wrist_rel_y = float(R_wrist_rel_y)
            else:
                elbow_angle = calculate_angle((LSH[0], LSH[1]), (LEL[0], LEL[1]), (LWR[0], LWR[1]))
                elbow_drift = abs(LEL[0] - LSH[0])
                wrist_rel_y = float(L_wrist_rel_y)

            elbow_drift_norm = safe_div(elbow_drift, shoulder_width)

            # ---------------- rules per exercise ----------------
            problems = []

            if abs(trunk_offset_norm) > TRUNK_BAD:
                problems.append("Avoid swinging / leaning")

            if sess.exercise_type in ("shoulder_press", "lateral_raise"):
                if wrist_asym > ASYM_BAD:
                    problems.append("Keep both arms even")

            if sess.exercise_type == "bicep_curl":
                if elbow_drift_norm > ELBOW_DRIFT_BAD:
                    problems.append("Keep elbow closer to shoulder line")

            if sess.exercise_type == "lateral_raise":
                if elbow_angle < ELBOW_TOO_BENT:
                    problems.append("Keep arms straighter (avoid upright-row)")

            if not problems:
                feedback = "Good form (rules)"
                fb_sev = "good"
            elif len(problems) == 1:
                feedback = problems[0]
                fb_sev = "warning"
                sess.form_error_count += 1
            else:
                feedback = problems[0] + " + " + problems[1]
                fb_sev = "danger"
                sess.form_error_count += 2

            # ---------------- live logic per exercise ----------------
            if sess.exercise_type == "bicep_curl":
                elbow_s, rep_done, rep_sum = sess.rep_counter.update(elbow_angle, trunk_offset_norm, conf_mean)
                reps_count = sess.rep_counter.rep_count
                state = sess.rep_counter.state

                if rep_done and rep_sum:
                    bundle = get_model_bundle("bicep_curl")
                    scaler = bundle["scaler"]
                    model  = bundle["model"]
                    feats  = bundle["features"]
                    thr    = float(bundle["threshold"])

                    trunk_clip = min(rep_sum["trunk_absmax"], 0.3)

                    feat_map = {
                        "rom": rep_sum["rom"],
                        "duration": rep_sum["duration_s"],
                        "trunk_absmax": trunk_clip,
                        "min_angle": rep_sum["min_angle"],
                    }

                    x = np.array([[feat_map[f] for f in feats]], dtype=np.float32)
                    xs = scaler.transform(x)
                    score = float(model.decision_function(xs)[0])

                    is_good = score >= thr
                    if is_good:
                        sess.reps_good += 1
                        sess.last_rep_text = f"Rep {rep_sum['rep_index']}: GOOD"
                    else:
                        sess.reps_bad += 1
                        sess.last_rep_text = f"Rep {rep_sum['rep_index']}: POSSIBLE DEVIATION"
                    sess.last_rep_score = score

                    if rep_sum["trunk_absmax"] > FATIGUE_TRUNK_FLAG:
                        sess.fatigue_flag = 1

                    sess.reps.append({
                        "rep_index": int(rep_sum["rep_index"]),
                        "duration_ms": int(rep_sum["duration_s"] * 1000),
                        "rom_score": float(rep_sum["rom"]),            # degrees for now
                        "trunk_sway": float(rep_sum["trunk_absmax"]),
                        "confidence_avg": float(rep_sum["confidence_avg"] or 0.0),
                        "form_label": "good" if is_good else "bad",
                        "anomaly_score": float(score),
                    })

                    sess.feedback.append({
                        "feedback_type": "posture",
                        "severity": "info" if is_good else "warning",
                        "feedback_text": sess.last_rep_text,
                    })

            elif sess.exercise_type == "shoulder_press":
                y_s, rep_done, rep_sum = sess.rep_counter.update(wrist_rel_y, trunk_offset_norm, conf_mean)
                reps_count = sess.rep_counter.rep_count
                state = sess.rep_counter.state

                # expose threshold guide lines when baseline ready
                if sess.rep_counter.baseline_ready:
                    down_thr = float(sess.rep_counter.down_thr)
                    up_thr = float(sess.rep_counter.up_thr)
                    # convert wrist_rel_y thresholds into pixel Y lines for overlay:
                    # wrist_y = shoulder_y - wrist_rel_y * shoulder_width
                    shoulder_y = float(shoulder_mid[1])
                    sw = float(shoulder_width)
                    guides["threshold_lines"] = {
                        "down_y": float(shoulder_y - down_thr * sw),
                        "up_y": float(shoulder_y - up_thr * sw),
                    }

                if rep_done and rep_sum:
                    bundle = get_model_bundle("shoulder_press")
                    scaler = bundle["scaler"]
                    model  = bundle["model"]
                    feats  = bundle["features"]
                    thr    = float(bundle["threshold"])

                    trunk_clip = min(rep_sum["trunk_absmax"], 0.3)

                    feat_map = {
                        "wrist_rel_range": rep_sum["wrist_rel_range"],
                        "duration": rep_sum["duration_s"],
                        "trunk_absmax": trunk_clip,
                        "max_wrist_rel_y": rep_sum["max_wrist_rel_y"],
                    }

                    x = np.array([[feat_map[f] for f in feats]], dtype=np.float32)
                    xs = scaler.transform(x)
                    score = float(model.decision_function(xs)[0])

                    is_good = score >= thr
                    if is_good:
                        sess.reps_good += 1
                        sess.last_rep_text = f"Rep {rep_sum['rep_index']}: GOOD"
                    else:
                        sess.reps_bad += 1
                        sess.last_rep_text = f"Rep {rep_sum['rep_index']}: POSSIBLE DEVIATION"
                    sess.last_rep_score = score

                    if rep_sum["trunk_absmax"] > FATIGUE_TRUNK_FLAG:
                        sess.fatigue_flag = 1

                    sess.reps.append({
                        "rep_index": int(rep_sum["rep_index"]),
                        "duration_ms": int(rep_sum["duration_s"] * 1000),
                        "rom_score": float(rep_sum["wrist_rel_range"]),  # proxy for now
                        "trunk_sway": float(rep_sum["trunk_absmax"]),
                        "confidence_avg": float(conf_mean or 0.0),
                        "form_label": "good" if is_good else "bad",
                        "anomaly_score": float(score),
                    })

                    sess.feedback.append({
                        "feedback_type": "posture",
                        "severity": "info" if is_good else "warning",
                        "feedback_text": sess.last_rep_text,
                    })

            elif sess.exercise_type == "lateral_raise":
                y_s, rep_done, rep_sum = sess.rep_counter.update(wrist_rel_y, trunk_offset_norm, elbow_angle, conf_mean)
                reps_count = sess.rep_counter.rep_count
                state = sess.rep_counter.state

                if sess.rep_counter.baseline_ready:
                    down_thr = float(sess.rep_counter.down_thr)
                    up_thr = float(sess.rep_counter.up_thr)
                    shoulder_y = float(shoulder_mid[1])
                    sw = float(shoulder_width)
                    guides["threshold_lines"] = {
                        "down_y": float(shoulder_y - down_thr * sw),
                        "up_y": float(shoulder_y - up_thr * sw),
                    }

                if rep_done and rep_sum:
                    bundle = get_model_bundle("lateral_raise")
                    scaler = bundle["scaler"]
                    model  = bundle["model"]
                    feats  = bundle["features"]
                    thr    = float(bundle["threshold"])

                    trunk_clip = min(rep_sum["trunk_absmax"], 0.3)

                    feat_map = {
                        "wrist_rel_range": rep_sum["wrist_rel_range"],
                        "duration": rep_sum["duration_s"],
                        "trunk_absmax": trunk_clip,
                        "elbow_min": rep_sum["elbow_min"],
                    }

                    x = np.array([[feat_map[f] for f in feats]], dtype=np.float32)
                    xs = scaler.transform(x)
                    score = float(model.decision_function(xs)[0])

                    is_good = score >= thr
                    if is_good:
                        sess.reps_good += 1
                        sess.last_rep_text = f"Rep {rep_sum['rep_index']}: GOOD"
                    else:
                        sess.reps_bad += 1
                        sess.last_rep_text = f"Rep {rep_sum['rep_index']}: POSSIBLE DEVIATION"
                    sess.last_rep_score = score

                    if rep_sum["trunk_absmax"] > FATIGUE_TRUNK_FLAG:
                        sess.fatigue_flag = 1

                    sess.reps.append({
                        "rep_index": int(rep_sum["rep_index"]),
                        "duration_ms": int(rep_sum["duration_s"] * 1000),
                        "rom_score": float(rep_sum["wrist_rel_range"]),
                        "trunk_sway": float(rep_sum["trunk_absmax"]),
                        "confidence_avg": float(conf_mean or 0.0),
                        "form_label": "good" if is_good else "bad",
                        "anomaly_score": float(score),
                    })

                    sess.feedback.append({
                        "feedback_type": "posture",
                        "severity": "info" if is_good else "warning",
                        "feedback_text": sess.last_rep_text,
                    })

        else:
            feedback = f"Low pose confidence ({conf_mean:.2f})"
            fb_sev = "warning"

    return {
        "exercise_type": sess.exercise_type,
        "frame_w": int(w),
        "frame_h": int(h),

        "reps": int(reps_count),
        "state": state,
        "conf": round2(conf_mean),
        "elbow_smooth": None if elbow_s is None else float(round(float(elbow_s), 1)),

        "feedback": feedback,
        "feedback_severity": fb_sev,

        "last_rep_text": sess.last_rep_text,
        "last_rep_score": None if sess.last_rep_score is None else float(round(float(sess.last_rep_score), 3)),

        "skeleton": skeleton,
        "guides": guides,
    }

@app.post("/finish")
def finish(payload: FinishIn):
    sess = sessions.pop(payload.session_token, None)
    if not sess:
        return {"message": "Invalid session_token."}

    reps_total = sess.rep_counter.rep_count if sess.rep_counter else 0

    if sess.fatigue_flag == 1:
        sess.feedback.append({
            "feedback_type": "fatigue",
            "severity": "warning",
            "feedback_text": "Fatigue indicators detected. Consider rest/reduced load.",
        })

    return {
        "reps_total": int(reps_total),
        "reps_good": int(sess.reps_good),
        "reps_bad": int(sess.reps_bad),
        "form_error_count": int(sess.form_error_count),
        "fatigue_flag": int(sess.fatigue_flag),
        "reps": sess.reps,
        "feedback": sess.feedback,
    }
