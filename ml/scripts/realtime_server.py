# liftright/ml/scripts/realtime_server.py
# Multi-exercise realtime server (bicep_curl, shoulder_press, lateral_raise)
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

VERSION = "realtime_server_multi_contract_v1_2026-01-22"

# ---------------- PATHS ----------------
PROJECT_ROOT = Path(__file__).resolve().parents[1]  # liftright/ml
MODEL_DIR = PROJECT_ROOT / "models"
OUT_DIR = PROJECT_ROOT / "outputs"
OUT_DIR.mkdir(parents=True, exist_ok=True)

STATUS_JSON_MAP = {
    "bicep_curl": OUT_DIR / "bicep_curl_status.json",
    "shoulder_press": OUT_DIR / "shoulder_press_status.json",
    "lateral_raise": OUT_DIR / "lateral_raise_status.json",
}

MODEL_PKL_MAP = {
    "bicep_curl": MODEL_DIR / "bicep_curl_ocsvm.pkl",
    "shoulder_press": MODEL_DIR / "shoulder_press_ocsvm.pkl",
    "lateral_raise": MODEL_DIR / "lateral_raise_ocsvm.pkl",
}

ALLOWED_EXERCISES = ["bicep_curl", "shoulder_press", "lateral_raise"]

# ---------------- SHARED CONFIG ----------------
DRAW_TEXT_OVERLAY = False  # server returns annotated frame already; keep overlays optional
MIN_CONF = 0.50

SMOOTH_N = 7
MIN_REP_TIME = 0.35

FATIGUE_WINDOW = 6
CALIB_REPS = 5

# ML softness (rolling baseline)
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
NEUTRAL_COLOR = (0, 200, 0)

mp_pose = mp.solutions.pose
mp_draw = mp.solutions.drawing_utils

PRAISE_LINES = [
    "Clean rep - controlled.",
    "Solid rep - keep it steady.",
    "Nice rep - good control.",
    "Smooth rep.",
    "Good rep - consistent tempo.",
]

GENERAL_TIPS_BC = [
    "Control the way down (slow eccentric).",
    "Keep wrists neutral.",
    "Relax the shoulders.",
    "Breathe out as you curl.",
    "Keep your upper arm steady.",
]

GENERAL_TIPS_SP = [
    "Brace your core before pressing.",
    "Keep wrists stacked over elbows.",
    "Control the way down (eccentric).",
    "Keep ribs down; avoid over-arching.",
    "Press evenly with both arms.",
]

GENERAL_TIPS_LR = [
    "Keep shoulders down and relaxed.",
    "Lead with elbows slightly.",
    "Control the way down (eccentric).",
    "Avoid swinging your torso.",
    "Stop around shoulder height.",
]

# =========================================================
# UTIL
# =========================================================
def write_status(exercise: str, payload: Dict[str, Any]) -> None:
    """Optional file mirror debug."""
    try:
        p = dict(payload)
        p["timestamp"] = time.time()
        path = STATUS_JSON_MAP.get(exercise)
        if path:
            path.write_text(json.dumps(p, indent=2), encoding="utf-8")
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

# =========================================================
# FATIGUE HELPERS (exercise specific)
# =========================================================
def fatigue_index_bc(baseline, rom_med, dur_med, drift_med):
    rom_ratio = safe_div(rom_med, baseline["rom"])
    dur_ratio = safe_div(dur_med, baseline["duration"])
    drift_delta = drift_med - baseline["drift"]

    c_rom = np.clip((0.70 - rom_ratio) / 0.70, 0.0, 1.0)
    c_dur = np.clip((dur_ratio - 1.25) / 1.25, 0.0, 1.0)
    c_drift = np.clip(drift_delta / 0.25, 0.0, 1.0)

    idx = (0.45 * c_rom + 0.25 * c_dur + 0.30 * c_drift) * 100.0
    comps = dict(rom_ratio=float(rom_ratio), dur_ratio=float(dur_ratio), drift_delta=float(drift_delta),
                 c_rom=float(c_rom), c_dur=float(c_dur), c_drift=float(c_drift))
    return float(idx), comps

def fatigue_index_sp(baseline, range_med, dur_med, stack_med):
    range_ratio = safe_div(range_med, baseline["range"])
    dur_ratio = safe_div(dur_med, baseline["duration"])
    stack_delta = stack_med - baseline["stack"]

    c_range = np.clip((0.70 - range_ratio) / 0.70, 0.0, 1.0)
    c_dur   = np.clip((dur_ratio - 1.25) / 1.25, 0.0, 1.0)
    c_stack = np.clip(stack_delta / 0.20, 0.0, 1.0)

    idx = (0.45 * c_range + 0.25 * c_dur + 0.30 * c_stack) * 100.0
    comps = dict(range_ratio=float(range_ratio), dur_ratio=float(dur_ratio), stack_delta=float(stack_delta),
                 c_range=float(c_range), c_dur=float(c_dur), c_stack=float(c_stack))
    return float(idx), comps

def fatigue_index_lr(baseline, range_med, dur_med, elbow_med):
    range_ratio = safe_div(range_med, baseline["range"])
    dur_ratio   = safe_div(dur_med, baseline["duration"])
    elbow_delta = baseline["elbow"] - elbow_med

    c_range = np.clip((0.70 - range_ratio) / 0.70, 0.0, 1.0)
    c_dur   = np.clip((dur_ratio - 1.25) / 1.25, 0.0, 1.0)
    c_elbow = np.clip(elbow_delta / 25.0, 0.0, 1.0)

    idx = (0.45 * c_range + 0.25 * c_dur + 0.30 * c_elbow) * 100.0
    comps = dict(range_ratio=float(range_ratio), dur_ratio=float(dur_ratio), elbow_delta=float(elbow_delta),
                 c_range=float(c_range), c_dur=float(c_dur), c_elbow=float(c_elbow))
    return float(idx), comps

# =========================================================
# REP COUNTERS
# =========================================================
# ---------------- BICEP CURL ----------------
BC_TOP_THR = 75
BC_BOT_THR = 155
BC_ELBOW_DRIFT_WARN = 0.35
BC_ELBOW_DRIFT_BAD  = 0.55
BC_ML_MARGIN = 0.030
BC_ML_LOW_STREAK_FOR_TIP = 3

class CurlRepCounter:
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
            if ang_s <= BC_TOP_THR:
                self.state = "up"
        else:
            if ang_s >= BC_BOT_THR:
                if (now - self.last_rep_t) >= MIN_REP_TIME and len(self.angles) >= 6:
                    self.rep_count += 1
                    self.last_rep_t = now
                    rep_done = True

                    angles = np.array(self.angles, dtype=np.float32)
                    drift  = np.array(self.drift, dtype=np.float32)
                    confs  = np.array(self.confs, dtype=np.float32)

                    rep_summary = {
                        "rep": self.rep_count,
                        "rom": float(angles.max() - angles.min()),
                        "duration": float(now - self.rep_start_t),
                        "elbow_drift_absmax": float(np.max(drift)) if len(drift) else 0.0,
                        "confidence_avg": float(np.mean(confs)) if len(confs) else 0.0,
                        "rep_tip_seen": bool(self.rep_tip_seen),
                        "rep_bad_seen": bool(self.rep_bad_seen),
                        "rep_tip_reason": str(self.rep_tip_reason),
                        "rep_bad_reason": str(self.rep_bad_reason),
                    }

                self.state = "down"
                self.reset_rep(now)

        return ang_s, rep_done, rep_summary

# ---------------- SHOULDER PRESS ----------------
SP_MAX_REP_TIME = 8.0
SP_BASELINE_FRAMES = 30
SP_UP_OFFSET = 0.25

SP_TRUNK_WARN = 0.13
SP_TRUNK_BAD  = 0.22
SP_ASYM_WARN  = 0.22
SP_ASYM_BAD   = 0.34
SP_WARN_STREAK = 6
SP_BAD_STREAK  = 4
SP_STACK_WARN = 0.25
SP_STACK_BAD  = 0.38

SP_ML_MARGIN = 0.050
SP_ML_LOW_STREAK_FOR_TIP = 4

class PressRepCounter:
    def __init__(self):
        self.buf = deque(maxlen=SMOOTH_N)
        self.state = "down"
        self.rep_count = 0
        self.last_rep_t = 0.0

        self.baseline_samples = []
        self.baseline_ready = False
        self.baseline = 0.10
        self.down_thr = 0.15
        self.up_thr = 0.45

        self.rep_arm = None
        self.reset_rep(time.time())

    def reset_rep(self, t):
        self.rep_start_t = t
        self.vals = []
        self.trunk = []
        self.stack = []
        self.confs = []

        self.rep_tip_seen = False
        self.rep_bad_seen = False
        self.rep_tip_reason = ""
        self.rep_bad_reason = ""
        self.rep_arm = None

    def update_baseline(self, wrist_rel_y):
        if self.baseline_ready:
            return
        self.baseline_samples.append(float(wrist_rel_y))
        if len(self.baseline_samples) >= SP_BASELINE_FRAMES:
            s = np.array(self.baseline_samples, dtype=np.float32)
            s = s[np.isfinite(s)]
            base_med = float(np.median(s)) if len(s) else 0.10

            s_sorted = np.sort(s) if len(s) else np.array([base_med], dtype=np.float32)
            upper_half = s_sorted[len(s_sorted)//2:]
            rack_guess = float(np.median(upper_half)) if len(upper_half) else base_med

            baseline = rack_guess if (base_med < 0.15 and rack_guess > base_med + 0.10) else base_med

            self.baseline = float(baseline)
            self.down_thr = max(0.15, self.baseline + 0.02)
            self.up_thr = self.down_thr + SP_UP_OFFSET
            self.baseline_ready = True

    def mark_feedback(self, bad_list, tip_list):
        if bad_list:
            self.rep_bad_seen = True
            if not self.rep_bad_reason:
                self.rep_bad_reason = str(bad_list[0])
        if tip_list:
            self.rep_tip_seen = True
            if not self.rep_tip_reason:
                self.rep_tip_reason = str(tip_list[0])

    def update(self, wrist_rel_y, trunk_offset_norm, wrist_stack_norm, arm_label, conf_mean):
        now = time.time()
        self.buf.append(float(wrist_rel_y))
        y_s = float(np.median(self.buf))

        self.update_baseline(y_s)

        if (now - self.rep_start_t) > SP_MAX_REP_TIME:
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
                self.rep_arm = arm_label
                self.reset_rep(now)
                self.vals.append(y_s)
                self.trunk.append(float(trunk_offset_norm))
                self.stack.append(float(wrist_stack_norm))
                self.confs.append(float(conf_mean))
            return y_s, False, None

        # collect only if matching locked arm
        if self.rep_arm is None or arm_label == self.rep_arm:
            self.vals.append(y_s)
            self.trunk.append(float(trunk_offset_norm))
            self.stack.append(float(wrist_stack_norm))
            self.confs.append(float(conf_mean))

        if y_s <= self.down_thr:
            if (now - self.last_rep_t) >= MIN_REP_TIME and len(self.vals) >= 6:
                self.rep_count += 1
                self.last_rep_t = now
                rep_done = True

                vals = np.array(self.vals, dtype=np.float32)
                trunk = np.array(self.trunk, dtype=np.float32)
                stack = np.array(self.stack, dtype=np.float32)
                confs = np.array(self.confs, dtype=np.float32)

                rep_summary = {
                    "rep": int(self.rep_count),
                    "wrist_rel_range": float(vals.max() - vals.min()),
                    "duration": float(now - self.rep_start_t),
                    "trunk_absmax": float(np.max(np.abs(trunk))) if len(trunk) else 0.0,
                    "wrist_drift_absmax": float(np.max(stack)) if len(stack) else 0.0,
                    "confidence_avg": float(np.mean(confs)) if len(confs) else 0.0,
                    "baseline": float(self.baseline),
                    "down_thr": float(self.down_thr),
                    "up_thr": float(self.up_thr),
                    "arm": str(self.rep_arm) if self.rep_arm else str(arm_label),
                    "rep_tip_seen": bool(self.rep_tip_seen),
                    "rep_bad_seen": bool(self.rep_bad_seen),
                    "rep_tip_reason": str(self.rep_tip_reason),
                    "rep_bad_reason": str(self.rep_bad_reason),
                    "n_frames": int(len(vals)),
                }

            self.state = "down"
            self.reset_rep(now)

        return y_s, rep_done, rep_summary

# ---------------- LATERAL RAISE ----------------
LR_MAX_REP_TIME = 8.0
LR_MIN_REP_FRAMES = 6

LR_BASELINE_FRAMES = 90
LR_BASELINE_PCT = 25
LR_BASELINE_CLAMP_LO = -0.35
LR_BASELINE_CLAMP_HI = 0.10
LR_DOWN_OFFSET = 0.04
LR_UP_OFFSET = 0.25

LR_TRUNK_WARN = 0.12
LR_TRUNK_BAD  = 0.20
LR_ASYM_WARN = 0.18
LR_ASYM_BAD  = 0.28
LR_ELBOW_WARN = 120.0
LR_ELBOW_BAD  = 95.0

LR_TORSO_COMP_WARN_DROP = 0.04
LR_TORSO_COMP_BAD_DROP  = 0.07
LR_TORSO_COMP_MIN_BASE  = 0.60

LR_WARN_STREAK = 6
LR_BAD_STREAK  = 4

LR_ML_MARGIN = 0.040
LR_ML_LOW_STREAK_FOR_TIP = 3

class LateralRepCounter:
    def __init__(self):
        self.buf = deque(maxlen=SMOOTH_N)
        self.state = "down"
        self.rep_count = 0
        self.last_rep_t = 0.0

        self.baseline_samples = []
        self.baseline_ready = False
        self.baseline = -0.10
        self.down_thr = -0.06
        self.up_thr = 0.19

        self.rep_arm = None
        self.reset_rep(time.time())

    def reset_rep(self, t):
        self.rep_start_t = t
        self.vals = []
        self.trunk = []
        self.elbow = []
        self.confs = []

        self.rep_tip_seen = False
        self.rep_bad_seen = False
        self.rep_tip_reason = ""
        self.rep_bad_reason = ""
        self.rep_arm = None

    def update_baseline(self, y_s):
        if self.baseline_ready:
            return
        self.baseline_samples.append(float(y_s))
        if len(self.baseline_samples) >= LR_BASELINE_FRAMES:
            s = np.array(self.baseline_samples, dtype=np.float32)
            s = s[np.isfinite(s)]
            base = float(np.percentile(s, LR_BASELINE_PCT)) if len(s) else -0.10
            base = float(np.clip(base, LR_BASELINE_CLAMP_LO, LR_BASELINE_CLAMP_HI))
            self.baseline = base
            self.down_thr = float(self.baseline + LR_DOWN_OFFSET)
            self.up_thr   = float(self.down_thr + LR_UP_OFFSET)
            self.baseline_ready = True

    def mark_feedback(self, bad_list, tip_list):
        if bad_list:
            self.rep_bad_seen = True
            if not self.rep_bad_reason:
                self.rep_bad_reason = str(bad_list[0])
        if tip_list:
            self.rep_tip_seen = True
            if not self.rep_tip_reason:
                self.rep_tip_reason = str(tip_list[0])

    def update(self, wrist_rel_y, trunk_offset_norm, elbow_angle, arm_label, conf_mean):
        now = time.time()
        self.buf.append(float(wrist_rel_y))
        y_s = float(np.median(self.buf))

        self.update_baseline(y_s)

        if (now - self.rep_start_t) > LR_MAX_REP_TIME:
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
                self.rep_arm = arm_label
                self.reset_rep(now)
                self.vals.append(y_s)
                self.trunk.append(float(trunk_offset_norm))
                self.elbow.append(float(elbow_angle))
                self.confs.append(float(conf_mean))
            return y_s, False, None

        if self.rep_arm is None or arm_label == self.rep_arm:
            self.vals.append(y_s)
            self.trunk.append(float(trunk_offset_norm))
            self.elbow.append(float(elbow_angle))
            self.confs.append(float(conf_mean))

        if y_s <= self.down_thr:
            if (now - self.last_rep_t) >= MIN_REP_TIME and len(self.vals) >= LR_MIN_REP_FRAMES:
                self.rep_count += 1
                self.last_rep_t = now
                rep_done = True

                vals  = np.array(self.vals, dtype=np.float32)
                trunk = np.array(self.trunk, dtype=np.float32)
                elbow = np.array(self.elbow, dtype=np.float32)
                confs = np.array(self.confs, dtype=np.float32)

                rep_summary = {
                    "rep": int(self.rep_count),
                    "wrist_rel_range": float(vals.max() - vals.min()),
                    "duration": float(now - self.rep_start_t),
                    "trunk_absmax": float(np.max(np.abs(trunk))) if len(trunk) else 0.0,
                    "elbow_min": float(np.min(elbow)) if len(elbow) else 180.0,
                    "confidence_avg": float(np.mean(confs)) if len(confs) else 0.0,
                    "baseline": float(self.baseline),
                    "down_thr": float(self.down_thr),
                    "up_thr": float(self.up_thr),
                    "arm": str(self.rep_arm) if self.rep_arm else str(arm_label),
                    "rep_tip_seen": bool(self.rep_tip_seen),
                    "rep_bad_seen": bool(self.rep_bad_seen),
                    "rep_tip_reason": str(self.rep_tip_reason),
                    "rep_bad_reason": str(self.rep_bad_reason),
                    "n_frames": int(len(vals)),
                }

            self.state = "down"
            self.reset_rep(now)

        return y_s, rep_done, rep_summary

# =========================================================
# SESSIONS
# =========================================================
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
        "elbow_warn_right": 0, "elbow_bad_right": 0,
        "elbow_warn_left": 0, "elbow_bad_left": 0,
        "low_conf": 0,
    })

    ml_low_streak: int = 0
    score_hist: deque = field(default_factory=lambda: deque(maxlen=ML_SCORE_WINDOW))

    fatigue_stop_streak: int = 0
    fatigue_index: float = 0.0
    fatigue_since_rep: Optional[int] = None
    fatigue_text: str = ""
    fatigue_details: Dict[str, Any] = field(default_factory=dict)

    last_rep_text: str = "-"
    last_rep_color: Tuple[int, int, int] = TEXT_COLOR

    reps: List[Dict[str, Any]] = field(default_factory=list)
    feedback: List[Dict[str, Any]] = field(default_factory=list)
    fatigue_flag: int = 0
    stopped: bool = False

    conf_last: float = 0.0


@dataclass
class ShoulderPressSession:
    session_token: str
    user_id: int
    log_id: int
    exercise_type: str = "shoulder_press"

    rep_counter: PressRepCounter = field(default_factory=PressRepCounter)

    set_counts: Dict[str, int] = field(default_factory=lambda: {
        "stack_warn_right": 0, "stack_bad_right": 0,
        "stack_warn_left": 0, "stack_bad_left": 0,
        "asym_warn": 0, "asym_bad": 0,
        "trunk_warn": 0, "trunk_bad": 0,
        "low_conf": 0,
    })

    recent: deque = field(default_factory=lambda: deque(maxlen=FATIGUE_WINDOW))
    calib: list = field(default_factory=list)
    baseline_ready: bool = False
    baseline: Dict[str, Optional[float]] = field(default_factory=lambda: {"range": None, "duration": None, "stack": None})

    ml_low_streak: int = 0
    score_hist: deque = field(default_factory=lambda: deque(maxlen=ML_SCORE_WINDOW))

    fatigue_stop_streak: int = 0
    fatigue_index: float = 0.0
    fatigue_since_rep: Optional[int] = None

    last_rep_text: str = "-"
    last_rep_color: Tuple[int, int, int] = TEXT_COLOR

    reps: List[Dict[str, Any]] = field(default_factory=list)
    feedback: List[Dict[str, Any]] = field(default_factory=list)
    fatigue_flag: int = 0
    stopped: bool = False

    conf_last: float = 0.0


@dataclass
class LateralRaiseSession:
    session_token: str
    user_id: int
    log_id: int
    exercise_type: str = "lateral_raise"

    rep_counter: LateralRepCounter = field(default_factory=LateralRepCounter)

    set_counts: Dict[str, int] = field(default_factory=lambda: {
        "trunk_warn": 0, "trunk_bad": 0,
        "tilt_warn": 0, "tilt_bad": 0,
        "asym_warn": 0, "asym_bad": 0,
        "elbow_warn_right": 0, "elbow_bad_right": 0,
        "elbow_warn_left": 0, "elbow_bad_left": 0,
        "low_conf": 0,
    })

    recent: deque = field(default_factory=lambda: deque(maxlen=FATIGUE_WINDOW))
    calib: list = field(default_factory=list)
    baseline_ready: bool = False
    baseline: Dict[str, Optional[float]] = field(default_factory=lambda: {"range": None, "duration": None, "elbow": None})

    ml_low_streak: int = 0
    score_hist: deque = field(default_factory=lambda: deque(maxlen=ML_SCORE_WINDOW))

    fatigue_stop_streak: int = 0
    fatigue_index: float = 0.0
    fatigue_since_rep: Optional[int] = None

    last_rep_text: str = "-"
    last_rep_color: Tuple[int, int, int] = TEXT_COLOR

    # torso compression calibration
    torso_h_samples: list = field(default_factory=list)
    torso_h0: Optional[float] = None

    # streaks
    trunk_streak: int = 0
    tilt_streak: int = 0
    asym_streak: int = 0
    elbow_streak_R: int = 0
    elbow_streak_L: int = 0

    reps: List[Dict[str, Any]] = field(default_factory=list)
    feedback: List[Dict[str, Any]] = field(default_factory=list)
    fatigue_flag: int = 0
    stopped: bool = False

    conf_last: float = 0.0

# =========================================================
# PIPELINES
# =========================================================
class ModelBundle:
    def __init__(self, exercise: str):
        bundle = joblib.load(MODEL_PKL_MAP[exercise])
        self.scaler = bundle["scaler"]
        self.model = bundle["model"]
        self.feats = bundle["features"]
        self.thr = float(bundle["threshold"])
        self.exercise = bundle.get("exercise", exercise)

def model_score(bundle: ModelBundle, feat_map: Dict[str, float]) -> float:
    missing = [f for f in bundle.feats if f not in feat_map]
    if missing:
        # fail soft: fill missing with 0.0 so it doesn't crash
        for f in missing:
            feat_map[f] = 0.0
    x = np.array([[feat_map[f] for f in bundle.feats]], dtype=np.float32)
    xs = bundle.scaler.transform(x)
    return float(bundle.model.decision_function(xs)[0])

# ---------------- BICEP PIPE ----------------
class BicepCurlPipeline:
    def __init__(self):
        self.bundle = ModelBundle("bicep_curl")
        self.pose = mp_pose.Pose(
            static_image_mode=False, model_complexity=0, smooth_landmarks=False,
            enable_segmentation=False, min_detection_confidence=0.5, min_tracking_confidence=0.5
        )

    def highlight(self, frame_bgr, pose_landmarks, right_elbow_level, left_elbow_level):
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

    def top_issues(self, set_counts):
        items = []
        rt = set_counts["elbow_bad_right"] + set_counts["elbow_warn_right"]
        lt = set_counts["elbow_bad_left"] + set_counts["elbow_warn_left"]
        if rt: items.append(("right elbow drift", rt))
        if lt: items.append(("left elbow drift", lt))
        if set_counts["low_conf"]: items.append(("tracking low", set_counts["low_conf"]))
        items.sort(key=lambda x: x[1], reverse=True)
        return items[:2]

    def process(self, frame_bgr: np.ndarray, sess: BicepCurlSession) -> Tuple[np.ndarray, Dict[str, Any]]:
        h, w = frame_bgr.shape[:2]
        res = self.pose.process(cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB))

        feedback = "Tracking..."
        fb_color = TEXT_COLOR
        feedback_level = "none"

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

                if right_drift_norm > BC_ELBOW_DRIFT_BAD:
                    right_elbow_level = 2
                    sess.set_counts["elbow_bad_right"] += 1
                elif right_drift_norm > BC_ELBOW_DRIFT_WARN:
                    right_elbow_level = 1
                    sess.set_counts["elbow_warn_right"] += 1

                if left_drift_norm > BC_ELBOW_DRIFT_BAD:
                    left_elbow_level = 2
                    sess.set_counts["elbow_bad_left"] += 1
                elif left_drift_norm > BC_ELBOW_DRIFT_WARN:
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

                self.highlight(frame_bgr, res.pose_landmarks, right_elbow_level, left_elbow_level)

                if bad:
                    feedback = "UNSAFE: " + bad[0]
                    fb_color = BAD_COLOR
                    feedback_level = "unsafe"
                elif tips:
                    feedback = "COACHING: " + tips[0]
                    fb_color = WARN_COLOR
                    feedback_level = "warning"
                else:
                    feedback = "STATUS: Stable"
                    fb_color = GOOD_COLOR
                    feedback_level = "good"

                if sess.rep_counter.state == "up":
                    sess.rep_counter.mark_feedback(bad, tips)

                _, rep_done, rep_sum = sess.rep_counter.update(
                    elbow_angle_for_rep, elbow_drift_for_rep, conf_mean
                )

                if rep_done and rep_sum:
                    drift_clip = min(rep_sum["elbow_drift_absmax"], 0.70)
                    feat_map = {"rom": rep_sum["rom"], "duration": rep_sum["duration"], "elbow_drift_absmax": drift_clip}
                    if "trunk_absmax" in self.bundle.feats:
                        feat_map["trunk_absmax"] = 0.0

                    score = model_score(self.bundle, feat_map)

                    sess.recent.append({"rom": rep_sum["rom"], "duration": rep_sum["duration"], "drift": drift_clip, "score": score})

                    if not sess.baseline_ready and not rep_sum["rep_bad_seen"]:
                        sess.calib.append(sess.recent[-1])
                        if len(sess.calib) >= CALIB_REPS:
                            sess.baseline["rom"] = median_or([r["rom"] for r in sess.calib], 120.0)
                            sess.baseline["duration"] = median_or([r["duration"] for r in sess.calib], 1.5)
                            sess.baseline["drift"] = median_or([r["drift"] for r in sess.calib], 0.14)
                            sess.baseline_ready = True

                    sess.fatigue_text = ""
                    sess.fatigue_details = {}
                    if sess.baseline_ready and len(sess.recent) >= 4:
                        last3 = list(sess.recent)[-3:]
                        rom_med = median_or([r["rom"] for r in last3], sess.baseline["rom"])
                        dur_med = median_or([r["duration"] for r in last3], sess.baseline["duration"])
                        drift_med = median_or([r["drift"] for r in last3], sess.baseline["drift"])
                        sess.fatigue_index, comps = fatigue_index_bc(sess.baseline, rom_med, dur_med, drift_med)
                        sess.fatigue_details = comps

                        if sess.fatigue_since_rep is None and sess.fatigue_index >= FATIGUE_WARN_INDEX:
                            sess.fatigue_since_rep = int(rep_sum["rep"])

                        if sess.fatigue_index >= FATIGUE_WARN_INDEX:
                            sess.fatigue_text = f"FATIGUE WARNING: index {sess.fatigue_index:.0f}/100"

                        sess.fatigue_stop_streak = sess.fatigue_stop_streak + 1 if sess.fatigue_index >= FATIGUE_STOP_INDEX else 0

                        if sess.fatigue_stop_streak >= FATIGUE_STOP_STREAK:
                            sess.fatigue_flag = 1
                            sess.stopped = True
                            since = sess.fatigue_since_rep if sess.fatigue_since_rep is not None else int(rep_sum["rep"])
                            issues = self.top_issues(sess.set_counts)
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

                    # ML softness
                    sess.score_hist.append(float(score))
                    use_relative = (len(sess.score_hist) >= ML_MIN_SCORES_FOR_REL)
                    score_ref = float(np.median(sess.score_hist)) if use_relative else float(self.bundle.thr)
                    ml_low_rel = use_relative and (score < (score_ref - ML_REL_DROP))
                    ml_low_abs = (score < (self.bundle.thr - BC_ML_MARGIN))
                    ml_low = ml_low_rel if use_relative else ml_low_abs
                    sess.ml_low_streak = sess.ml_low_streak + 1 if ml_low else 0
                    ml_tip = (sess.ml_low_streak >= BC_ML_LOW_STREAK_FOR_TIP)

                    rep_tips = []
                    if sess.fatigue_text:
                        rep_tips.append("Fatigue trend - consider rest or lighter weight")
                    if sess.baseline_ready:
                        if rep_sum["rom"] < 0.55 * sess.baseline["rom"]:
                            rep_tips.append("ROM is dropping - lighten weight or rest")
                        if rep_sum["duration"] > 1.8 * sess.baseline["duration"]:
                            rep_tips.append("Tempo slowing - stay controlled")
                    else:
                        if rep_sum["rom"] < 45:
                            rep_tips.append("Try a fuller range of motion (if comfortable)")
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

                    if rep_sum.get("rep_bad_seen", False):
                        sess.last_rep_text = f"Rep {rep_n}: UNSAFE - {rep_bad_reason or 'adjust form'}"
                        sess.last_rep_color = BAD_COLOR
                    else:
                        any_tip = rep_sum.get("rep_tip_seen", False) or ml_tip or bool(rep_tips)
                        if any_tip:
                            reason = rep_tip_reason if rep_tip_reason else (rep_tips[0] if rep_tips else "small adjustment")
                            sess.last_rep_text = f"Rep {rep_n}: COACHING - {reason}"
                            sess.last_rep_color = WARN_COLOR
                        else:
                            msg = random.choice(PRAISE_LINES)
                            if random.random() < 0.40:
                                msg += " " + random.choice(GENERAL_TIPS_BC)
                            sess.last_rep_text = f"Rep {rep_n}: {msg}"
                            sess.last_rep_color = GOOD_COLOR

                    rep_bad = bool(rep_sum.get("rep_bad_seen", False))
                    rep_warn = (not rep_bad) and (bool(rep_sum.get("rep_tip_seen", False)) or bool(ml_tip) or bool(rep_tips))
                    form_label_db = "bad" if rep_bad else "good"
                    label_ui = "bad" if rep_bad else ("warning" if rep_warn else "good")

                    sess.reps.append({
                        "rep_index": rep_n,
                        "duration_ms": int(round(rep_sum["duration"] * 1000)),
                        "rom_score": float(rep_sum["rom"]),
                        "trunk_sway": 0.0,
                        "confidence_avg": float(rep_sum.get("confidence_avg", 0.0)),
                        "form_label": form_label_db,
                        "anomaly_score": float(score),
                        "meta": {
                            "label_ui": label_ui,
                            "is_warning": bool(rep_warn),
                            "elbow_drift_absmax": float(drift_clip),
                            "rep_tip_seen": bool(rep_sum.get("rep_tip_seen", False)),
                            "rep_bad_seen": bool(rep_sum.get("rep_bad_seen", False)),
                            "reasons": reasons[:4],
                            "fatigue_index": float(sess.fatigue_index),
                        }
                    })

                    if rep_bad:
                        sess.feedback.append({
                            "feedback_type": "posture",
                            "severity": "danger",
                            "feedback_text": rep_bad_reason or "Unsafe form detected",
                            "meta": {"rep": rep_n, "all": reasons[:4]}
                        })
                    elif reasons:
                        sess.feedback.append({
                            "feedback_type": "posture",
                            "severity": "warning" if "COACHING" in sess.last_rep_text else "info",
                            "feedback_text": reasons[0],
                            "meta": {"rep": rep_n, "all": reasons[:4]}
                        })

                    issues = self.top_issues(sess.set_counts)
                    issues_str = ", ".join([f"{n} x{c}" for n, c in issues]) if issues else "no major issues"
                    write_status("bicep_curl", {
                        "state": "stop" if sess.stopped else "running",
                        "phase": "stop" if sess.stopped else str(getattr(sess.rep_counter, "state", "down")),
                        "exercise": "bicep_curl",
                        "rep_now": rep_n,
                        "last_rep_text": sess.last_rep_text,
                        "last_rep_reasons": reasons[:4],
                        "score": float(score),
                        "threshold": float(self.bundle.thr),
                        "fatigue_index": float(sess.fatigue_index),
                        "fatigue_warning": bool(sess.fatigue_text),
                        "baseline_ready": bool(sess.baseline_ready),
                        "set_summary": sess.set_counts,
                        "set_top_issues_text": issues_str,
                        "fatigue_details": sess.fatigue_details,
                    })

            else:
                sess.set_counts["low_conf"] += 1
                feedback = f"Tracking quality low ({conf_mean:.2f})"
                fb_color = WARN_COLOR
                feedback_level = "none"

        else:
            sess.set_counts["low_conf"] += 1
            feedback = "No pose detected"
            fb_color = WARN_COLOR
            feedback_level = "none"

        if DRAW_TEXT_OVERLAY:
            cv2.putText(frame_bgr, feedback, (10, h - 110), cv2.FONT_HERSHEY_SIMPLEX, 0.8, fb_color, 2)
            if sess.fatigue_text:
                cv2.putText(frame_bgr, sess.fatigue_text, (10, h - 75), cv2.FONT_HERSHEY_SIMPLEX, 0.7, WARN_COLOR, 2)
            cv2.putText(frame_bgr, sess.last_rep_text, (10, h - 35), cv2.FONT_HERSHEY_SIMPLEX, 0.8, sess.last_rep_color, 2)

        status = {
            # session-level state (do NOT change meaning)
            "state": "stop" if sess.stopped else "running",

            # rep-phase (THIS is what your UI needs)
            "phase": "stop" if sess.stopped else str(getattr(sess.rep_counter, "state", "down")),

            "exercise": "bicep_curl",
            "rep_now": int(sess.rep_counter.rep_count),
            "last_rep_text": sess.last_rep_text,
            "fatigue_index": float(sess.fatigue_index),
            "fatigue_warning": bool(sess.fatigue_text),
            "baseline_ready": bool(sess.baseline_ready),
            "conf": float(sess.conf_last),
            "live_feedback_level": str(feedback_level),
            "live_feedback_text": str(feedback),
        }
        return frame_bgr, status

# ---------------- SHOULDER PRESS PIPE ----------------
class ShoulderPressPipeline:
    def __init__(self):
        self.bundle = ModelBundle("shoulder_press")
        self.pose = mp_pose.Pose(
            static_image_mode=False, model_complexity=0, smooth_landmarks=False,
            enable_segmentation=False, min_detection_confidence=0.5, min_tracking_confidence=0.5
        )

    def highlight(self, frame, plm, right_stack_level, left_stack_level, trunk_level, asym_level):
        if plm is None:
            return
        if right_stack_level > 0:
            c = WARN_COLOR if right_stack_level == 1 else BAD_COLOR
            draw_segment(frame, plm, mp_pose.PoseLandmark.RIGHT_SHOULDER, mp_pose.PoseLandmark.RIGHT_ELBOW, c)
            draw_segment(frame, plm, mp_pose.PoseLandmark.RIGHT_ELBOW, mp_pose.PoseLandmark.RIGHT_WRIST, c)
        if left_stack_level > 0:
            c = WARN_COLOR if left_stack_level == 1 else BAD_COLOR
            draw_segment(frame, plm, mp_pose.PoseLandmark.LEFT_SHOULDER, mp_pose.PoseLandmark.LEFT_ELBOW, c)
            draw_segment(frame, plm, mp_pose.PoseLandmark.LEFT_ELBOW, mp_pose.PoseLandmark.LEFT_WRIST, c)
        if trunk_level > 0:
            c = WARN_COLOR if trunk_level == 1 else BAD_COLOR
            draw_segment(frame, plm, mp_pose.PoseLandmark.LEFT_SHOULDER, mp_pose.PoseLandmark.LEFT_HIP, c, thickness=5)
            draw_segment(frame, plm, mp_pose.PoseLandmark.RIGHT_SHOULDER, mp_pose.PoseLandmark.RIGHT_HIP, c, thickness=5)
        if asym_level > 0:
            c = WARN_COLOR if asym_level == 1 else BAD_COLOR
            draw_segment(frame, plm, mp_pose.PoseLandmark.LEFT_SHOULDER, mp_pose.PoseLandmark.LEFT_WRIST, c, thickness=4)
            draw_segment(frame, plm, mp_pose.PoseLandmark.RIGHT_SHOULDER, mp_pose.PoseLandmark.RIGHT_WRIST, c, thickness=4)

    def top_issues(self, set_counts):
        items = []
        if set_counts["stack_bad_right"] + set_counts["stack_warn_right"] > 0:
            items.append(("right wrist stack", set_counts["stack_bad_right"] + set_counts["stack_warn_right"]))
        if set_counts["stack_bad_left"] + set_counts["stack_warn_left"] > 0:
            items.append(("left wrist stack", set_counts["stack_bad_left"] + set_counts["stack_warn_left"]))
        if set_counts["asym_bad"] + set_counts["asym_warn"] > 0:
            items.append(("arm asymmetry", set_counts["asym_bad"] + set_counts["asym_warn"]))
        if set_counts["trunk_bad"] + set_counts["trunk_warn"] > 0:
            items.append(("trunk lean/arch", set_counts["trunk_bad"] + set_counts["trunk_warn"]))
        if set_counts["low_conf"] > 0:
            items.append(("tracking low", set_counts["low_conf"]))
        items.sort(key=lambda x: x[1], reverse=True)
        return items[:2]

    def process(self, frame_bgr: np.ndarray, sess: ShoulderPressSession) -> Tuple[np.ndarray, Dict[str, Any]]:
        h, w = frame_bgr.shape[:2]
        res = self.pose.process(cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB))

        feedback = "Tracking..."
        fb_color = TEXT_COLOR
        feedback_level = "none"

        right_stack_level = 0
        left_stack_level = 0
        trunk_level = 0
        asym_level = 0

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

                mid_sh_x = (LSH[0] + RSH[0]) / 2.0
                mid_hp_x = (LHP[0] + RHP[0]) / 2.0
                trunk_offset_norm = safe_div((mid_sh_x - mid_hp_x), shoulder_width)

                yR = safe_div((RSH[1] - RWR[1]), shoulder_width)
                yL = safe_div((LSH[1] - LWR[1]), shoulder_width)

                stackR = safe_div(abs(RWR[0] - REL[0]), shoulder_width)
                stackL = safe_div(abs(LWR[0] - LEL[0]), shoulder_width)

                use_right = (RWR[2] >= LWR[2])
                arm_label = "R" if use_right else "L"
                wrist_rel_y = yR if use_right else yL
                wrist_stack = stackR if use_right else stackL

                bad = []
                tips = []

                # trunk rule
                if abs(trunk_offset_norm) > SP_TRUNK_BAD:
                    trunk_level = 2
                    sess.set_counts["trunk_bad"] += 1
                    bad.append("Avoid leaning / back arch")
                elif abs(trunk_offset_norm) > SP_TRUNK_WARN:
                    trunk_level = 1
                    sess.set_counts["trunk_warn"] += 1
                    tips.append("Brace core; reduce lean")

                # asym rule
                asym = abs(yR - yL)
                if asym > SP_ASYM_BAD:
                    asym_level = 2
                    sess.set_counts["asym_bad"] += 1
                    bad.append("Keep arms even")
                elif asym > SP_ASYM_WARN:
                    asym_level = 1
                    sess.set_counts["asym_warn"] += 1
                    tips.append("Press more evenly")

                # stack per side
                if stackR > SP_STACK_BAD:
                    right_stack_level = 2
                    sess.set_counts["stack_bad_right"] += 1
                elif stackR > SP_STACK_WARN:
                    right_stack_level = 1
                    sess.set_counts["stack_warn_right"] += 1

                if stackL > SP_STACK_BAD:
                    left_stack_level = 2
                    sess.set_counts["stack_bad_left"] += 1
                elif stackL > SP_STACK_WARN:
                    left_stack_level = 1
                    sess.set_counts["stack_warn_left"] += 1

                worst_stack = max(right_stack_level, left_stack_level)
                if worst_stack == 2:
                    if right_stack_level == 2 and left_stack_level == 2:
                        bad.append("Wrists not stacked (both)")
                    elif right_stack_level == 2:
                        bad.append("Wrist not stacked (right)")
                    else:
                        bad.append("Wrist not stacked (left)")
                elif worst_stack == 1:
                    if right_stack_level == 1 and left_stack_level == 1:
                        tips.append("Stack wrists over elbows (both)")
                    elif right_stack_level == 1:
                        tips.append("Stack wrist over elbow (right)")
                    else:
                        tips.append("Stack wrist over elbow (left)")

                self.highlight(frame_bgr, res.pose_landmarks, right_stack_level, left_stack_level, trunk_level, asym_level)

                if bad:
                    feedback = "UNSAFE: " + bad[0]
                    fb_color = BAD_COLOR
                    feedback_level = "unsafe"
                elif tips:
                    feedback = "COACHING: " + tips[0]
                    fb_color = WARN_COLOR
                    feedback_level = "warning"
                else:
                    feedback = "STATUS: Stable"
                    fb_color = GOOD_COLOR
                    feedback_level = "good"

                if sess.rep_counter.state == "up":
                    sess.rep_counter.mark_feedback(bad, tips)

                _, rep_done, rep_sum = sess.rep_counter.update(
                    wrist_rel_y=wrist_rel_y,
                    trunk_offset_norm=trunk_offset_norm,
                    wrist_stack_norm=wrist_stack,
                    arm_label=arm_label,
                    conf_mean=conf_mean
                )

                if rep_done and rep_sum:
                    feat_map = {
                        "wrist_rel_range": float(rep_sum["wrist_rel_range"]),
                        "duration": float(rep_sum["duration"]),
                        "trunk_absmax": min(float(rep_sum["trunk_absmax"]), 0.55),
                        "wrist_drift_absmax": min(float(rep_sum["wrist_drift_absmax"]), 0.60),
                    }
                    score = model_score(self.bundle, feat_map)

                    sess.recent.append({
                        "range": rep_sum["wrist_rel_range"],
                        "duration": rep_sum["duration"],
                        "stack": min(rep_sum["wrist_drift_absmax"], 0.60),
                        "score": score
                    })

                    if (not sess.baseline_ready) and (not rep_sum.get("rep_bad_seen", False)):
                        sess.calib.append(sess.recent[-1])
                        if len(sess.calib) >= CALIB_REPS:
                            sess.baseline["range"] = median_or([r["range"] for r in sess.calib], 0.35)
                            sess.baseline["duration"] = median_or([r["duration"] for r in sess.calib], 1.6)
                            sess.baseline["stack"] = median_or([r["stack"] for r in sess.calib], 0.16)
                            sess.baseline_ready = True

                    comps = {}
                    if sess.baseline_ready and len(sess.recent) >= 4:
                        last3 = list(sess.recent)[-3:]
                        range_med = median_or([r["range"] for r in last3], sess.baseline["range"])
                        dur_med   = median_or([r["duration"] for r in last3], sess.baseline["duration"])
                        stack_med = median_or([r["stack"] for r in last3], sess.baseline["stack"])

                        sess.fatigue_index, comps = fatigue_index_sp(sess.baseline, range_med, dur_med, stack_med)

                        if sess.fatigue_since_rep is None and sess.fatigue_index >= FATIGUE_WARN_INDEX:
                            sess.fatigue_since_rep = rep_sum["rep"]

                        sess.fatigue_stop_streak = sess.fatigue_stop_streak + 1 if sess.fatigue_index >= FATIGUE_STOP_INDEX else 0

                        if sess.fatigue_stop_streak >= FATIGUE_STOP_STREAK:
                            sess.fatigue_flag = 1
                            sess.stopped = True
                            since = sess.fatigue_since_rep if sess.fatigue_since_rep is not None else rep_sum["rep"]
                            issues = self.top_issues(sess.set_counts)
                            issues_str = ", ".join([f"{n} x{c}" for n, c in issues]) if issues else "no dominant issue"
                            msg = (
                                f"Stop recommended. Strong fatigue detected since Rep {since}. "
                                f"Top issues: {issues_str}. Please rest or reduce weight."
                            )
                            sess.feedback.append({
                                "feedback_type": "fatigue",
                                "severity": "warning",
                                "feedback_text": msg,
                                "meta": {"since_rep": int(since), "top_issues": issues, "fatigue_index": float(sess.fatigue_index), "details": comps}
                            })

                    # ML softness
                    sess.score_hist.append(float(score))
                    use_relative = (len(sess.score_hist) >= ML_MIN_SCORES_FOR_REL)
                    score_ref = float(np.median(sess.score_hist)) if use_relative else float(self.bundle.thr)
                    ml_low_rel = use_relative and (score < (score_ref - ML_REL_DROP))
                    ml_low_abs = (score < (self.bundle.thr - SP_ML_MARGIN))
                    ml_low = ml_low_rel if use_relative else ml_low_abs
                    sess.ml_low_streak = sess.ml_low_streak + 1 if ml_low else 0
                    ml_tip = (sess.ml_low_streak >= SP_ML_LOW_STREAK_FOR_TIP)

                    rep_tips = []
                    if sess.baseline_ready and rep_sum["wrist_rel_range"] < 0.55 * sess.baseline["range"]:
                        rep_tips.append("Range dropping - lighten weight or rest")
                    if sess.baseline_ready and rep_sum["duration"] > 1.8 * sess.baseline["duration"]:
                        rep_tips.append("Tempo slowing - stay controlled")
                    if ml_tip:
                        rep_tips.append("Consistency drifting (ML)")
                    if sess.fatigue_index >= FATIGUE_WARN_INDEX:
                        rep_tips.append("Fatigue trend - consider rest")

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

                    # Text
                    rep_bad = bool(rep_sum.get("rep_bad_seen", False))
                    rep_warn = (not rep_bad) and (bool(rep_sum.get("rep_tip_seen", False)) or ml_tip or bool(rep_tips))

                    if rep_bad:
                        sess.last_rep_text = f"Rep {rep_n}: UNSAFE - {rep_bad_reason or 'adjust form'}"
                        sess.last_rep_color = BAD_COLOR
                    elif rep_warn:
                        reason = rep_tip_reason if rep_tip_reason else (rep_tips[0] if rep_tips else "small adjustment")
                        sess.last_rep_text = f"Rep {rep_n}: COACHING - {reason}"
                        sess.last_rep_color = WARN_COLOR
                    else:
                        msg = random.choice(PRAISE_LINES)
                        if random.random() < 0.40:
                            msg += " " + random.choice(GENERAL_TIPS_SP)
                        sess.last_rep_text = f"Rep {rep_n}: {msg}"
                        sess.last_rep_color = GOOD_COLOR

                    form_label_db = "bad" if rep_bad else "good"
                    label_ui = "bad" if rep_bad else ("warning" if rep_warn else "good")

                    sess.reps.append({
                        "rep_index": rep_n,
                        "duration_ms": int(round(rep_sum["duration"] * 1000)),
                        "rom_score": float(rep_sum["wrist_rel_range"]),
                        "trunk_sway": float(rep_sum["trunk_absmax"]),
                        "confidence_avg": float(rep_sum.get("confidence_avg", 0.0)),
                        "form_label": form_label_db,
                        "anomaly_score": float(score),
                        "meta": {
                            "label_ui": label_ui,
                            "is_warning": bool(rep_warn),
                            "wrist_stack_absmax": float(rep_sum["wrist_drift_absmax"]),
                            "reasons": reasons[:4],
                            "fatigue_index": float(sess.fatigue_index),
                            "arm": rep_sum.get("arm", "?")
                        }
                    })

                    if rep_bad:
                        sess.feedback.append({
                            "feedback_type": "posture",
                            "severity": "danger",
                            "feedback_text": rep_bad_reason or "Unsafe form detected",
                            "meta": {"rep": rep_n, "all": reasons[:4]}
                        })
                    elif reasons:
                        sess.feedback.append({
                            "feedback_type": "posture",
                            "severity": "warning" if "COACHING" in sess.last_rep_text else "info",
                            "feedback_text": reasons[0],
                            "meta": {"rep": rep_n, "all": reasons[:4]}
                        })

                    issues = self.top_issues(sess.set_counts)
                    issues_str = ", ".join([f"{n} x{c}" for n, c in issues]) if issues else "no major issues"
                    write_status("shoulder_press", {
                        "state": "stop" if sess.stopped else "running",
                        "phase": "stop" if sess.stopped else str(getattr(sess.rep_counter, "state", "down")),
                        "exercise": "shoulder_press",
                        "rep_now": rep_n,
                        "last_rep_text": sess.last_rep_text,
                        "score": float(score),
                        "threshold": float(self.bundle.thr),
                        "fatigue_index": float(sess.fatigue_index),
                        "baseline_ready": bool(sess.baseline_ready),
                        "set_top_issues_text": issues_str,
                        "fatigue_details": comps,
                    })

            else:
                sess.set_counts["low_conf"] += 1
                feedback = f"Low pose confidence ({conf_mean:.2f})"
                fb_color = WARN_COLOR
                feedback_level = "none"
        else:
            sess.set_counts["low_conf"] += 1
            feedback = "No pose detected"
            fb_color = WARN_COLOR
            feedback_level = "none"

        if DRAW_TEXT_OVERLAY:
            cv2.putText(frame_bgr, feedback, (10, h - 110), cv2.FONT_HERSHEY_SIMPLEX, 0.8, fb_color, 2)
            cv2.putText(frame_bgr, sess.last_rep_text, (10, h - 35), cv2.FONT_HERSHEY_SIMPLEX, 0.8, sess.last_rep_color, 2)

        status = {
            "state": "stop" if sess.stopped else "running",
            "phase": "stop" if sess.stopped else str(getattr(sess.rep_counter, "state", "down")),
            "exercise": "shoulder_press",
            "rep_now": int(sess.rep_counter.rep_count),
            "last_rep_text": sess.last_rep_text,
            "fatigue_index": float(sess.fatigue_index),
            "fatigue_warning": bool(sess.fatigue_index >= FATIGUE_WARN_INDEX),
            "baseline_ready": bool(sess.baseline_ready),
            "conf": float(sess.conf_last),
            "live_feedback_level": str(feedback_level),
            "live_feedback_text": str(feedback),
        }
        return frame_bgr, status

# ---------------- LATERAL RAISE PIPE ----------------
class LateralRaisePipeline:
    def __init__(self):
        self.bundle = ModelBundle("lateral_raise")
        self.pose = mp_pose.Pose(
            static_image_mode=False, model_complexity=0, smooth_landmarks=False,
            enable_segmentation=False, min_detection_confidence=0.5, min_tracking_confidence=0.5
        )

    def highlight(self, frame, plm, trunk_level, tilt_level, asym_level, elbow_level_right, elbow_level_left):
        if plm is None:
            return
        # trunk lines if trunk/tilt
        if trunk_level > 0 or tilt_level > 0:
            level = max(trunk_level, tilt_level)
            c = WARN_COLOR if level == 1 else BAD_COLOR
            draw_segment(frame, plm, mp_pose.PoseLandmark.LEFT_SHOULDER,  mp_pose.PoseLandmark.LEFT_HIP,  c, thickness=5)
            draw_segment(frame, plm, mp_pose.PoseLandmark.RIGHT_SHOULDER, mp_pose.PoseLandmark.RIGHT_HIP, c, thickness=5)
        # asym arms
        if asym_level > 0:
            c = WARN_COLOR if asym_level == 1 else BAD_COLOR
            draw_segment(frame, plm, mp_pose.PoseLandmark.LEFT_SHOULDER,  mp_pose.PoseLandmark.LEFT_WRIST,  c, thickness=4)
            draw_segment(frame, plm, mp_pose.PoseLandmark.RIGHT_SHOULDER, mp_pose.PoseLandmark.RIGHT_WRIST, c, thickness=4)
        # elbow highlights
        if elbow_level_right > 0:
            c = WARN_COLOR if elbow_level_right == 1 else BAD_COLOR
            draw_segment(frame, plm, mp_pose.PoseLandmark.RIGHT_SHOULDER, mp_pose.PoseLandmark.RIGHT_ELBOW, c)
            draw_segment(frame, plm, mp_pose.PoseLandmark.RIGHT_ELBOW,    mp_pose.PoseLandmark.RIGHT_WRIST, c)
        if elbow_level_left > 0:
            c = WARN_COLOR if elbow_level_left == 1 else BAD_COLOR
            draw_segment(frame, plm, mp_pose.PoseLandmark.LEFT_SHOULDER, mp_pose.PoseLandmark.LEFT_ELBOW, c)
            draw_segment(frame, plm, mp_pose.PoseLandmark.LEFT_ELBOW,    mp_pose.PoseLandmark.LEFT_WRIST, c)

    def top_issues(self, set_counts):
        items = []
        if set_counts["trunk_bad"] + set_counts["trunk_warn"] > 0:
            items.append(("side lean/swing", set_counts["trunk_bad"] + set_counts["trunk_warn"]))
        if set_counts["tilt_bad"] + set_counts["tilt_warn"] > 0:
            items.append(("forward/back lean", set_counts["tilt_bad"] + set_counts["tilt_warn"]))
        if set_counts["asym_bad"] + set_counts["asym_warn"] > 0:
            items.append(("arm asymmetry", set_counts["asym_bad"] + set_counts["asym_warn"]))
        if set_counts["elbow_bad_right"] + set_counts["elbow_warn_right"] > 0:
            items.append(("right elbow bend", set_counts["elbow_bad_right"] + set_counts["elbow_warn_right"]))
        if set_counts["elbow_bad_left"] + set_counts["elbow_warn_left"] > 0:
            items.append(("left elbow bend", set_counts["elbow_bad_left"] + set_counts["elbow_warn_left"]))
        if set_counts["low_conf"] > 0:
            items.append(("tracking low", set_counts["low_conf"]))
        items.sort(key=lambda x: x[1], reverse=True)
        return items[:2]

    def process(self, frame_bgr: np.ndarray, sess: LateralRaiseSession) -> Tuple[np.ndarray, Dict[str, Any]]:
        h, w = frame_bgr.shape[:2]
        res = self.pose.process(cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB))

        feedback = "Tracking..."
        fb_color = TEXT_COLOR
        feedback_level = "none"

        trunk_level = 0
        tilt_level = 0
        asym_level = 0
        elbow_level_right = 0
        elbow_level_left = 0

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

                bad = []
                tips = []

                mid_sh_x = (LSH[0] + RSH[0]) / 2.0
                mid_hp_x = (LHP[0] + RHP[0]) / 2.0
                trunk_offset_norm = safe_div((mid_sh_x - mid_hp_x), shoulder_width)

                mid_sh = ((LSH[0] + RSH[0]) / 2.0, (LSH[1] + RSH[1]) / 2.0)
                mid_hp = ((LHP[0] + RHP[0]) / 2.0, (LHP[1] + RHP[1]) / 2.0)
                torso_h_norm = abs(mid_sh[1] - mid_hp[1]) / shoulder_width

                # torso baseline
                if sess.torso_h0 is None:
                    sess.torso_h_samples.append(float(torso_h_norm))
                    if len(sess.torso_h_samples) >= LR_BASELINE_FRAMES:
                        sess.torso_h0 = float(np.median(sess.torso_h_samples))
                        if sess.torso_h0 < LR_TORSO_COMP_MIN_BASE:
                            sess.torso_h0 = LR_TORSO_COMP_MIN_BASE

                yR = safe_div((RSH[1] - RWR[1]), shoulder_width)
                yL = safe_div((LSH[1] - LWR[1]), shoulder_width)

                angR = calculate_angle((RSH[0], RSH[1]), (REL[0], REL[1]), (RWR[0], RWR[1]))
                angL = calculate_angle((LSH[0], LSH[1]), (LEL[0], LEL[1]), (LWR[0], LWR[1]))

                use_right = (RWR[2] >= LWR[2])
                arm_label = "R" if use_right else "L"
                wrist_rel_y = yR if use_right else yL
                elbow_angle = angR if use_right else angL

                # trunk streak
                if abs(trunk_offset_norm) > LR_TRUNK_BAD:
                    sess.trunk_streak += 1
                elif abs(trunk_offset_norm) > LR_TRUNK_WARN:
                    sess.trunk_streak = max(sess.trunk_streak, 1)
                else:
                    sess.trunk_streak = 0

                if sess.trunk_streak >= LR_BAD_STREAK:
                    trunk_level = 2
                    sess.set_counts["trunk_bad"] += 1
                    bad.append("Avoid leaning / swinging (side-to-side)")
                elif sess.trunk_streak >= LR_WARN_STREAK:
                    trunk_level = 1
                    sess.set_counts["trunk_warn"] += 1
                    tips.append("Reduce torso swing")

                # tilt via torso compression
                if sess.torso_h0 is not None:
                    drop = (sess.torso_h0 - torso_h_norm) / (sess.torso_h0 + 1e-6)
                    if drop > LR_TORSO_COMP_BAD_DROP:
                        sess.tilt_streak += 1
                    elif drop > LR_TORSO_COMP_WARN_DROP:
                        sess.tilt_streak = max(sess.tilt_streak, 1)
                    else:
                        sess.tilt_streak = 0

                    if sess.tilt_streak >= LR_BAD_STREAK:
                        tilt_level = 2
                        sess.set_counts["tilt_bad"] += 1
                        bad.append("Don't hinge forward/back (stay upright)")
                    elif sess.tilt_streak >= LR_WARN_STREAK:
                        tilt_level = 1
                        sess.set_counts["tilt_warn"] += 1
                        tips.append("Stay upright (avoid forward lean)")

                # asym
                asym = abs(yR - yL)
                if asym > LR_ASYM_BAD:
                    sess.asym_streak += 1
                elif asym > LR_ASYM_WARN:
                    sess.asym_streak = max(sess.asym_streak, 1)
                else:
                    sess.asym_streak = 0

                if sess.asym_streak >= LR_BAD_STREAK:
                    asym_level = 2
                    sess.set_counts["asym_bad"] += 1
                    bad.append("Raise both arms evenly")
                elif sess.asym_streak >= LR_WARN_STREAK:
                    asym_level = 1
                    sess.set_counts["asym_warn"] += 1
                    tips.append("Even out both arms")

                # elbow bend
                if angR < LR_ELBOW_BAD:
                    sess.elbow_streak_R += 1
                elif angR < LR_ELBOW_WARN:
                    sess.elbow_streak_R = max(sess.elbow_streak_R, 1)
                else:
                    sess.elbow_streak_R = 0

                if sess.elbow_streak_R >= LR_BAD_STREAK:
                    elbow_level_right = 2
                    sess.set_counts["elbow_bad_right"] += 1
                elif sess.elbow_streak_R >= LR_WARN_STREAK:
                    elbow_level_right = 1
                    sess.set_counts["elbow_warn_right"] += 1

                if angL < LR_ELBOW_BAD:
                    sess.elbow_streak_L += 1
                elif angL < LR_ELBOW_WARN:
                    sess.elbow_streak_L = max(sess.elbow_streak_L, 1)
                else:
                    sess.elbow_streak_L = 0

                if sess.elbow_streak_L >= LR_BAD_STREAK:
                    elbow_level_left = 2
                    sess.set_counts["elbow_bad_left"] += 1
                elif sess.elbow_streak_L >= LR_WARN_STREAK:
                    elbow_level_left = 1
                    sess.set_counts["elbow_warn_left"] += 1

                # decide feedback line
                if bad:
                    feedback = "UNSAFE: " + bad[0]
                    fb_color = BAD_COLOR
                    feedback_level = "unsafe"
                elif tips:
                    feedback = "COACHING: " + tips[0]
                    fb_color = WARN_COLOR
                    feedback_level = "warning"
                else:
                    worst_elbow = max(elbow_level_left, elbow_level_right)
                    if worst_elbow == 2:
                        feedback = "UNSAFE: Don't curl (elbow too bent)"
                        fb_color = BAD_COLOR
                        feedback_level = "unsafe"
                    elif worst_elbow == 1:
                        feedback = "COACHING: Keep arms straighter"
                        fb_color = WARN_COLOR
                        feedback_level = "warning"
                    else:
                        feedback = "STATUS: Stable"
                        fb_color = GOOD_COLOR
                        feedback_level = "good"

                self.highlight(frame_bgr, res.pose_landmarks, trunk_level, tilt_level, asym_level, elbow_level_right, elbow_level_left)

                # remember issues during rep
                if sess.rep_counter.state == "up":
                    rep_bad = list(bad)
                    rep_tips = list(tips)
                    worst_elbow = max(elbow_level_left, elbow_level_right)
                    if worst_elbow == 2:
                        rep_bad.append("Don't curl (elbow too bent)")
                    elif worst_elbow == 1:
                        rep_tips.append("Keep arms straighter")
                    sess.rep_counter.mark_feedback(rep_bad, rep_tips)

                _, rep_done, rep_sum = sess.rep_counter.update(
                    wrist_rel_y=wrist_rel_y,
                    trunk_offset_norm=trunk_offset_norm,
                    elbow_angle=elbow_angle,
                    arm_label=arm_label,
                    conf_mean=conf_mean
                )

                if rep_done and rep_sum:
                    trunk_clip = min(rep_sum["trunk_absmax"], 0.55)
                    elbow_clip = float(np.clip(rep_sum["elbow_min"], 60.0, 180.0))

                    feat_map = {
                        "wrist_rel_range": float(rep_sum["wrist_rel_range"]),
                        "duration": float(rep_sum["duration"]),
                        "trunk_absmax": float(trunk_clip),
                        "elbow_min": float(elbow_clip),
                    }
                    score = model_score(self.bundle, feat_map)

                    sess.recent.append({
                        "range": rep_sum["wrist_rel_range"],
                        "duration": rep_sum["duration"],
                        "elbow": elbow_clip,
                        "score": score
                    })

                    # baseline from good reps
                    if (not sess.baseline_ready) and (not rep_sum.get("rep_bad_seen", False)):
                        sess.calib.append(sess.recent[-1])
                        if len(sess.calib) >= CALIB_REPS:
                            sess.baseline["range"] = median_or([r["range"] for r in sess.calib], 0.35)
                            sess.baseline["duration"] = median_or([r["duration"] for r in sess.calib], 1.6)
                            sess.baseline["elbow"] = median_or([r["elbow"] for r in sess.calib], 145.0)
                            sess.baseline_ready = True

                    comps = {}
                    if sess.baseline_ready and len(sess.recent) >= 4:
                        last3 = list(sess.recent)[-3:]
                        range_med = median_or([r["range"] for r in last3], sess.baseline["range"])
                        dur_med   = median_or([r["duration"] for r in last3], sess.baseline["duration"])
                        elbow_med = median_or([r["elbow"] for r in last3], sess.baseline["elbow"])

                        sess.fatigue_index, comps = fatigue_index_lr(sess.baseline, range_med, dur_med, elbow_med)

                        if sess.fatigue_since_rep is None and sess.fatigue_index >= FATIGUE_WARN_INDEX:
                            sess.fatigue_since_rep = rep_sum["rep"]

                        sess.fatigue_stop_streak = sess.fatigue_stop_streak + 1 if sess.fatigue_index >= FATIGUE_STOP_INDEX else 0

                        if sess.fatigue_stop_streak >= FATIGUE_STOP_STREAK:
                            sess.fatigue_flag = 1
                            sess.stopped = True
                            since = sess.fatigue_since_rep if sess.fatigue_since_rep is not None else rep_sum["rep"]
                            issues = self.top_issues(sess.set_counts)
                            issues_str = ", ".join([f"{n} x{c}" for n, c in issues]) if issues else "no dominant issue"
                            msg = (
                                f"Stop recommended. Strong fatigue detected since Rep {since}. "
                                f"Top issues: {issues_str}. Please rest or reduce weight."
                            )
                            sess.feedback.append({
                                "feedback_type": "fatigue",
                                "severity": "warning",
                                "feedback_text": msg,
                                "meta": {"since_rep": int(since), "top_issues": issues, "fatigue_index": float(sess.fatigue_index), "details": comps}
                            })

                    # ML softness (relative)
                    sess.score_hist.append(float(score))
                    use_relative = (len(sess.score_hist) >= ML_MIN_SCORES_FOR_REL)
                    score_ref = float(np.median(sess.score_hist)) if use_relative else float(self.bundle.thr)
                    ml_low_rel = use_relative and (score < (score_ref - ML_REL_DROP))
                    ml_low_abs = (score < (self.bundle.thr - LR_ML_MARGIN))
                    ml_low = ml_low_rel if use_relative else ml_low_abs
                    sess.ml_low_streak = sess.ml_low_streak + 1 if ml_low else 0
                    ml_tip = (sess.ml_low_streak >= LR_ML_LOW_STREAK_FOR_TIP)

                    rep_tips = []
                    if sess.baseline_ready and rep_sum["wrist_rel_range"] < 0.55 * sess.baseline["range"]:
                        rep_tips.append("Range dropping - lighten weight or rest")
                    if sess.baseline_ready and rep_sum["duration"] > 1.8 * sess.baseline["duration"]:
                        rep_tips.append("Tempo slowing - stay controlled")
                    if sess.baseline_ready and elbow_clip < (sess.baseline["elbow"] - 18.0):
                        rep_tips.append("Arms bending more - avoid upright-row motion")
                    if ml_tip:
                        rep_tips.append("Consistency drifting (ML)")
                    if sess.fatigue_index >= FATIGUE_WARN_INDEX:
                        rep_tips.append("Fatigue trend - consider rest")

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

                    rep_bad = bool(rep_sum.get("rep_bad_seen", False))
                    rep_warn = (not rep_bad) and (bool(rep_sum.get("rep_tip_seen", False)) or ml_tip or bool(rep_tips))

                    if rep_bad:
                        sess.last_rep_text = f"Rep {rep_n}: UNSAFE - {rep_bad_reason or 'adjust form'}"
                        sess.last_rep_color = BAD_COLOR
                    elif rep_warn:
                        reason = rep_tip_reason if rep_tip_reason else (rep_tips[0] if rep_tips else "small adjustment")
                        sess.last_rep_text = f"Rep {rep_n}: COACHING - {reason}"
                        sess.last_rep_color = WARN_COLOR
                    else:
                        msg = random.choice(PRAISE_LINES)
                        if random.random() < 0.40:
                            msg += " " + random.choice(GENERAL_TIPS_LR)
                        sess.last_rep_text = f"Rep {rep_n}: {msg}"
                        sess.last_rep_color = GOOD_COLOR

                    form_label_db = "bad" if rep_bad else "good"
                    label_ui = "bad" if rep_bad else ("warning" if rep_warn else "good")

                    sess.reps.append({
                        "rep_index": rep_n,
                        "duration_ms": int(round(rep_sum["duration"] * 1000)),
                        "rom_score": float(rep_sum["wrist_rel_range"]),
                        "trunk_sway": float(rep_sum["trunk_absmax"]),
                        "confidence_avg": float(rep_sum.get("confidence_avg", 0.0)),
                        "form_label": form_label_db,
                        "anomaly_score": float(score),
                        "meta": {
                            "label_ui": label_ui,
                            "is_warning": bool(rep_warn),
                            "elbow_min": float(elbow_clip),
                            "reasons": reasons[:4],
                            "fatigue_index": float(sess.fatigue_index),
                            "arm": rep_sum.get("arm", "?")
                        }
                    })

                    if rep_bad:
                        sess.feedback.append({
                            "feedback_type": "posture",
                            "severity": "danger",
                            "feedback_text": rep_bad_reason or "Unsafe form detected",
                            "meta": {"rep": rep_n, "all": reasons[:4]}
                        })
                    elif reasons:
                        sess.feedback.append({
                            "feedback_type": "posture",
                            "severity": "warning" if "COACHING" in sess.last_rep_text else "info",
                            "feedback_text": reasons[0],
                            "meta": {"rep": rep_n, "all": reasons[:4]}
                        })

                    issues = self.top_issues(sess.set_counts)
                    issues_str = ", ".join([f"{n} x{c}" for n, c in issues]) if issues else "no major issues"
                    write_status("lateral_raise", {
                        "state": "stop" if sess.stopped else "running",
                        "phase": "stop" if sess.stopped else str(getattr(sess.rep_counter, "state", "down")),
                        "exercise": "lateral_raise",
                        "rep_now": rep_n,
                        "last_rep_text": sess.last_rep_text,
                        "score": float(score),
                        "threshold": float(self.bundle.thr),
                        "fatigue_index": float(sess.fatigue_index),
                        "baseline_ready": bool(sess.baseline_ready),
                        "set_top_issues_text": issues_str,
                        "fatigue_details": comps,
                    })

            else:
                sess.set_counts["low_conf"] += 1
                feedback = f"Low pose confidence ({conf_mean:.2f})"
                fb_color = WARN_COLOR
                feedback_level = "none"

        else:
            sess.set_counts["low_conf"] += 1
            feedback = "No pose detected"
            fb_color = WARN_COLOR
            feedback_level = "none"

        if DRAW_TEXT_OVERLAY:
            cv2.putText(frame_bgr, feedback, (10, h - 110), cv2.FONT_HERSHEY_SIMPLEX, 0.8, fb_color, 2)
            cv2.putText(frame_bgr, sess.last_rep_text, (10, h - 35), cv2.FONT_HERSHEY_SIMPLEX, 0.8, sess.last_rep_color, 2)

        status = {
            "state": "stop" if sess.stopped else "running",
            "phase": "stop" if sess.stopped else str(getattr(sess.rep_counter, "state", "down")),
            "exercise": "lateral_raise",
            "rep_now": int(sess.rep_counter.rep_count),
            "last_rep_text": sess.last_rep_text,
            "fatigue_index": float(sess.fatigue_index),
            "fatigue_warning": bool(sess.fatigue_index >= FATIGUE_WARN_INDEX),
            "baseline_ready": bool(sess.baseline_ready),
            "conf": float(sess.conf_last),
            "live_feedback_level": str(feedback_level),
            "live_feedback_text": str(feedback),
        }
        return frame_bgr, status

# =========================================================
# GLOBAL PIPELINES + SESSION STORE
# =========================================================
PIPE_BC = BicepCurlPipeline()
PIPE_SP = ShoulderPressPipeline()
PIPE_LR = LateralRaisePipeline()

# Lightweight pose model for onboarding gate (no session)
GATE_POSE = mp_pose.Pose(
    static_image_mode=False,
    model_complexity=0,
    smooth_landmarks=False,
    enable_segmentation=False,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

SESSIONS: Dict[str, Any] = {}

def _lm_ok(lm, idx, edge=0.02, vis_thr=0.55):
    """Landmark must be visible enough and not too close to the frame edge."""
    try:
        p = lm[idx]
        if getattr(p, "visibility", 0.0) < vis_thr:
            return False
        if p.x < edge or p.x > (1.0 - edge):
            return False
        if p.y < edge or p.y > (1.0 - edge):
            return False
        return True
    except Exception:
        return False

def gate_eval(frame_bgr):
    """Return gate info for client-side onboarding."""
    if frame_bgr is None:
        return {"pose_found": False, "frame_ok": False, "parts": {}, "wrist": {}}

    h, w = frame_bgr.shape[:2]
    rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
    res = GATE_POSE.process(rgb)

    if not res.pose_landmarks:
        return {
            "pose_found": False,
            "frame_ok": False,
            "parts": {"shoulders": False, "hips": False, "elbows": False, "wrists": False},
            "wrist": {}
        }

    lm = res.pose_landmarks.landmark

    # Required upper-body landmarks
    LSH = mp_pose.PoseLandmark.LEFT_SHOULDER.value
    RSH = mp_pose.PoseLandmark.RIGHT_SHOULDER.value
    LHP = mp_pose.PoseLandmark.LEFT_HIP.value
    RHP = mp_pose.PoseLandmark.RIGHT_HIP.value
    LEL = mp_pose.PoseLandmark.LEFT_ELBOW.value
    REL = mp_pose.PoseLandmark.RIGHT_ELBOW.value
    LWR = mp_pose.PoseLandmark.LEFT_WRIST.value
    RWR = mp_pose.PoseLandmark.RIGHT_WRIST.value

    shoulders_ok = _lm_ok(lm, LSH) and _lm_ok(lm, RSH)
    hips_ok      = _lm_ok(lm, LHP) and _lm_ok(lm, RHP)
    elbows_ok    = _lm_ok(lm, LEL) and _lm_ok(lm, REL)
    wrists_ok    = _lm_ok(lm, LWR) and _lm_ok(lm, RWR)

    # Simple framing check:
    # only require the main upper-body region needed for exercise tracking
    frame_ok = shoulders_ok and hips_ok

    # Provide wrist coords to allow client to confirm "hands up" + "hands to side" over time
    lw = lm[LWR]; rw = lm[RWR]
    wrist = {
        "lx": float(lw.x), "ly": float(lw.y),
        "rx": float(rw.x), "ry": float(rw.y),
        "min_x": float(min(lw.x, rw.x)),
        "max_x": float(max(lw.x, rw.x)),
        "min_y": float(min(lw.y, rw.y)),
    }

    return {
        "pose_found": True,
        "frame_ok": bool(frame_ok),
        "parts": {
            "shoulders": bool(shoulders_ok),
            "hips": bool(hips_ok),
            "elbows": bool(elbows_ok),
            "wrists": bool(wrists_ok),
        },
        "wrist": wrist
    }

# =========================================================
# FASTAPI CONTRACT
# =========================================================
class StartReq(BaseModel):
    exercise_type: str
    log_id: int
    user_id: int

class FrameReq(BaseModel):
    session_token: str
    frame_dataurl: str

class GateReq(BaseModel):
    frame_dataurl: str

class FinishReq(BaseModel):
    session_token: str

app = FastAPI(title="LiftRight Realtime Server", version=VERSION)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"ok": True, "version": VERSION, "exercises": ALLOWED_EXERCISES}

@app.post("/gate")
def gate(req: GateReq):
    img = decode_dataurl_to_bgr(req.frame_dataurl)
    if img is None:
        return {"ok": False, "error": "Could not decode frame_dataurl."}

    g = gate_eval(img)
    return {"ok": True, "gate": g}

@app.post("/start")
def start(req: StartReq):
    ex = (req.exercise_type or "").strip().lower()
    if ex not in ALLOWED_EXERCISES:
        return {"ok": False, "error": "Invalid exercise_type."}

    token = uuid.uuid4().hex

    if ex == "bicep_curl":
        sess = BicepCurlSession(session_token=token, user_id=int(req.user_id), log_id=int(req.log_id))
    elif ex == "shoulder_press":
        sess = ShoulderPressSession(session_token=token, user_id=int(req.user_id), log_id=int(req.log_id))
    else:
        sess = LateralRaiseSession(session_token=token, user_id=int(req.user_id), log_id=int(req.log_id))

    SESSIONS[token] = sess
    write_status(ex, {"state": "running", "exercise": ex, "message": "Session started", "log_id": sess.log_id})
    return {"session_token": token}

@app.post("/frame")
def frame(req: FrameReq):
    frame_t0 = time.perf_counter()

    token = (req.session_token or "").strip()
    sess = SESSIONS.get(token)
    if not sess:
        return {"ok": False, "error": "Invalid session_token."}

    img = decode_dataurl_to_bgr(req.frame_dataurl)
    if img is None:
        return {"ok": False, "error": "Could not decode frame_dataurl."}

    ex = getattr(sess, "exercise_type", "bicep_curl")

    if ex == "bicep_curl":
        annotated, status = PIPE_BC.process(img, sess)
    elif ex == "shoulder_press":
        annotated, status = PIPE_SP.process(img, sess)
    else:
        annotated, status = PIPE_LR.process(img, sess)

    frame_t1 = time.perf_counter()
    ml_processing_ms = (frame_t1 - frame_t0) * 1000.0

    status["ml_processing_ms"] = ml_processing_ms

    print(f"[LiftRight Metrics] /frame ML processing: {ml_processing_ms:.2f} ms")

    return {
        "annotated_frame_dataurl": bgr_to_dataurl_jpeg(annotated, quality=80),
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
    reps_warn = sum(1 for r in sess.reps if bool((r.get("meta") or {}).get("is_warning")))
    reps_good = reps_total - reps_bad
    form_error_count = sum(1 for f in sess.feedback if f.get("severity") == "danger")

    payload = {
        "reps_total": int(reps_total),
        "reps_good": int(reps_good),
        "reps_bad": int(reps_bad),
        "reps_warn": int(reps_warn),
        "form_error_count": int(form_error_count),
        "fatigue_flag": int(getattr(sess, "fatigue_flag", 0)),
        "reps": sess.reps,
        "feedback": sess.feedback,
    }

    ex = getattr(sess, "exercise_type", "unknown")
    write_status(ex, {"state": "finished", "exercise": ex, "message": "Session finished", "reps_total": reps_total})
    return payload

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=5101, log_level="info")
