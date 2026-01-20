# ml/scripts/04_live_lateral_raise.py
import cv2
import numpy as np
import mediapipe as mp
import joblib
import time
import random
import json
from collections import deque
from pathlib import Path

# ---------------- PATHS ----------------
PROJECT_ROOT = Path(__file__).resolve().parents[1]
MODEL_PKL = PROJECT_ROOT / "models" / "lateral_raise_ocsvm.pkl"

OUT_DIR = PROJECT_ROOT / "outputs"
OUT_DIR.mkdir(parents=True, exist_ok=True)
STATUS_JSON = OUT_DIR / "lateral_raise_status.json"

# ---------------- CAMERA ----------------
CAM_INDEX = 0
MIN_CONF = 0.50

# ---------------- REP DETECTION ----------------
SMOOTH_N = 7
MIN_REP_TIME = 0.35
MAX_REP_TIME = 8.0
MIN_REP_FRAMES = 6

# Baseline tuning (fix: rep end was "too low")
BASELINE_FRAMES = 90      # ~3 sec calibration (more stable)
BASELINE_PCT = 25         # down-position cluster
BASELINE_CLAMP_LO = -0.35
BASELINE_CLAMP_HI = 0.10

DOWN_OFFSET = 0.04        # higher bottom threshold so you don't need to dead-hang
UP_OFFSET   = 0.25        # start of raise

# ---------------- COACHING THRESHOLDS ----------------
TRUNK_WARN = 0.12
TRUNK_BAD  = 0.20

ASYM_WARN = 0.18
ASYM_BAD  = 0.28

ELBOW_WARN = 120.0
ELBOW_BAD  = 95.0

# forward/back lean proxy (torso compression vs baseline)
TORSO_COMP_WARN_DROP = 0.04   # 10% shorter than baseline
TORSO_COMP_BAD_DROP  = 0.07   # 18% shorter than baseline
TORSO_COMP_MIN_BASE  = 0.60   # ignore if calibration is weird (very close camera)

WARN_STREAK = 6
BAD_STREAK  = 4

# ---------------- FATIGUE / PERSONALIZATION ----------------
CALIB_REPS = 5
FATIGUE_WINDOW = 6

# ML softness (do not override clean reps)
ML_MARGIN = 0.040
ML_LOW_STREAK_FOR_TIP = 3

# Rolling baseline so "ML drifting" clears if user recovers
ML_SCORE_WINDOW = 8
ML_REL_DROP = 0.020
ML_MIN_SCORES_FOR_REL = 4

# fatigue severity (0-100)
FATIGUE_WARN_INDEX = 55
FATIGUE_STOP_INDEX = 80
FATIGUE_STOP_STREAK = 2

# ---------------- UI COLORS ----------------
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
    "Keep shoulders down and relaxed.",
    "Lead with elbows slightly.",
    "Control the way down (eccentric).",
    "Avoid swinging your torso.",
    "Stop around shoulder height.",
]

# ---------------- MEDIAPIPE ----------------
mp_pose = mp.solutions.pose
mp_draw = mp.solutions.drawing_utils


def write_status(payload):
    try:
        payload = dict(payload)
        payload["timestamp"] = time.time()
        STATUS_JSON.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    except Exception:
        pass


def lm_xyv(landmarks, idx, w, h):
    lm = landmarks[idx]
    return (lm.x * w, lm.y * h, float(lm.visibility))


def safe_div(a, b, eps=1e-6):
    return float(a / (b + eps))


def median_or(x, fallback):
    x = [v for v in x if np.isfinite(v)]
    return float(np.median(x)) if len(x) else float(fallback)


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
    if pose_landmarks is None:
        return
    lm = pose_landmarks.landmark
    h, w = frame.shape[:2]
    ax, ay = int(lm[a].x * w), int(lm[a].y * h)
    bx, by = int(lm[b].x * w), int(lm[b].y * h)
    cv2.line(frame, (ax, ay), (bx, by), color, thickness)


def highlight_issues(frame, pose_landmarks,
                     trunk_level, tilt_level, asym_level,
                     elbow_level_right, elbow_level_left):
    """
    trunk_level: side-to-side trunk offset
    tilt_level:  forward/back lean (torso compression)
    asym_level:  arm symmetry
    elbow levels: curling/upright-row cheating per side
    """
    if pose_landmarks is None:
        return

    if trunk_level > 0 or tilt_level > 0:
        level = max(trunk_level, tilt_level)
        c = WARN_COLOR if level == 1 else BAD_COLOR
        draw_segment(frame, pose_landmarks, mp_pose.PoseLandmark.LEFT_SHOULDER,  mp_pose.PoseLandmark.LEFT_HIP,  c, thickness=5)
        draw_segment(frame, pose_landmarks, mp_pose.PoseLandmark.RIGHT_SHOULDER, mp_pose.PoseLandmark.RIGHT_HIP, c, thickness=5)

    if asym_level > 0:
        c = WARN_COLOR if asym_level == 1 else BAD_COLOR
        draw_segment(frame, pose_landmarks, mp_pose.PoseLandmark.LEFT_SHOULDER,  mp_pose.PoseLandmark.LEFT_WRIST,  c, thickness=4)
        draw_segment(frame, pose_landmarks, mp_pose.PoseLandmark.RIGHT_SHOULDER, mp_pose.PoseLandmark.RIGHT_WRIST, c, thickness=4)

    if elbow_level_right > 0:
        c = WARN_COLOR if elbow_level_right == 1 else BAD_COLOR
        draw_segment(frame, pose_landmarks, mp_pose.PoseLandmark.RIGHT_SHOULDER, mp_pose.PoseLandmark.RIGHT_ELBOW, c)
        draw_segment(frame, pose_landmarks, mp_pose.PoseLandmark.RIGHT_ELBOW,    mp_pose.PoseLandmark.RIGHT_WRIST, c)

    if elbow_level_left > 0:
        c = WARN_COLOR if elbow_level_left == 1 else BAD_COLOR
        draw_segment(frame, pose_landmarks, mp_pose.PoseLandmark.LEFT_SHOULDER, mp_pose.PoseLandmark.LEFT_ELBOW, c)
        draw_segment(frame, pose_landmarks, mp_pose.PoseLandmark.LEFT_ELBOW,    mp_pose.PoseLandmark.LEFT_WRIST, c)


class LateralRepCounter:
    """
    Gold-standard style:
      - baseline via percentile on early frames (clamped)
      - down->up->down state machine
      - per-rep memory (tip/bad seen)
      - locks arm label once rep starts
    """
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

        self.rep_tip_seen = False
        self.rep_bad_seen = False
        self.rep_tip_reason = ""
        self.rep_bad_reason = ""

        self.rep_arm = None

    def update_baseline(self, y_s):
        if self.baseline_ready:
            return
        self.baseline_samples.append(float(y_s))
        if len(self.baseline_samples) >= BASELINE_FRAMES:
            s = np.array(self.baseline_samples, dtype=np.float32)
            s = s[np.isfinite(s)]
            base = float(np.percentile(s, BASELINE_PCT)) if len(s) else -0.10
            base = float(np.clip(base, BASELINE_CLAMP_LO, BASELINE_CLAMP_HI))

            self.baseline = base
            self.down_thr = float(self.baseline + DOWN_OFFSET)
            self.up_thr   = float(self.down_thr + UP_OFFSET)
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

    def update(self, wrist_rel_y, trunk_offset_norm, elbow_angle, arm_label):
        now = time.time()

        self.buf.append(float(wrist_rel_y))
        y_s = float(np.median(self.buf))

        self.update_baseline(y_s)

        # stuck safety reset
        if (now - self.rep_start_t) > MAX_REP_TIME:
            self.state = "down"
            self.reset_rep(now)
            self.buf.clear()
            return y_s, False, None

        if not self.baseline_ready:
            return y_s, False, None

        rep_done = False
        rep_summary = None

        # Start rep
        if self.state == "down":
            if y_s >= self.up_thr:
                self.state = "up"
                self.rep_arm = arm_label
                self.reset_rep(now)

                self.vals.append(y_s)
                self.trunk.append(float(trunk_offset_norm))
                self.elbow.append(float(elbow_angle))
            return y_s, False, None

        # Collect while up (only if matches locked arm)
        if self.rep_arm is None or arm_label == self.rep_arm:
            self.vals.append(y_s)
            self.trunk.append(float(trunk_offset_norm))
            self.elbow.append(float(elbow_angle))

        # End rep
        if y_s <= self.down_thr:
            if (now - self.last_rep_t) >= MIN_REP_TIME and len(self.vals) >= MIN_REP_FRAMES:
                self.rep_count += 1
                self.last_rep_t = now
                rep_done = True

                vals  = np.array(self.vals, dtype=np.float32)
                trunk = np.array(self.trunk, dtype=np.float32)
                elbow = np.array(self.elbow, dtype=np.float32)

                rep_summary = {
                    "rep": int(self.rep_count),
                    "min_wrist_rel_y": float(vals.min()),
                    "max_wrist_rel_y": float(vals.max()),
                    "wrist_rel_range": float(vals.max() - vals.min()),
                    "duration": float(now - self.rep_start_t),
                    "trunk_absmax": float(np.max(np.abs(trunk))) if len(trunk) else 0.0,
                    "elbow_min": float(np.min(elbow)) if len(elbow) else 180.0,

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


def compute_fatigue_index(baseline, range_med, dur_med, elbow_med):
    range_ratio = safe_div(range_med, baseline["range"])
    dur_ratio   = safe_div(dur_med, baseline["duration"])
    elbow_delta = baseline["elbow"] - elbow_med

    c_range = np.clip((0.70 - range_ratio) / 0.70, 0.0, 1.0)
    c_dur   = np.clip((dur_ratio - 1.25) / 1.25, 0.0, 1.0)
    c_elbow = np.clip(elbow_delta / 25.0, 0.0, 1.0)

    idx = (0.45 * c_range + 0.25 * c_dur + 0.30 * c_elbow) * 100.0
    comps = {
        "range_ratio": float(range_ratio),
        "dur_ratio": float(dur_ratio),
        "elbow_delta": float(elbow_delta),
        "c_range": float(c_range),
        "c_dur": float(c_dur),
        "c_elbow": float(c_elbow),
    }
    return float(idx), comps


def top_set_issues(set_counts):
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


def main():
    write_status({"state": "running", "message": "Lateral raise tracking active."})

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

    rep_counter = LateralRepCounter()

    set_counts = {
        "trunk_warn": 0, "trunk_bad": 0,
        "tilt_warn": 0, "tilt_bad": 0,
        "asym_warn": 0, "asym_bad": 0,
        "elbow_warn_right": 0, "elbow_bad_right": 0,
        "elbow_warn_left": 0, "elbow_bad_left": 0,
        "low_conf": 0,
    }

    recent = deque(maxlen=FATIGUE_WINDOW)
    calib_reps = []
    baseline_ready = False
    baseline = {"range": None, "duration": None, "elbow": None}

    score_hist = deque(maxlen=ML_SCORE_WINDOW)
    ml_low_streak = 0

    fatigue_stop_streak = 0
    fatigue_since_rep = None

    last_rep_text = "-"
    last_rep_color = TEXT_COLOR
    fatigue_text = ""
    fatigue_color = TEXT_COLOR
    fatigue_index = 0.0
    rep_history = []

    trunk_streak = 0
    tilt_streak = 0
    asym_streak = 0
    elbow_streak_R = 0
    elbow_streak_L = 0

    # forward/back lean calibration (torso compression)
    torso_h_samples = []
    torso_h0 = None

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

                draw_skeleton_neutral(frame, res.pose_landmarks)

                if conf_mean >= MIN_CONF:
                    shoulder_width = abs(LSH[0] - RSH[0])
                    if shoulder_width < 2:
                        shoulder_width = 2

                    bad = []
                    tips = []

                    # trunk side-to-side offset
                    mid_sh_x = (LSH[0] + RSH[0]) / 2.0
                    mid_hp_x = (LHP[0] + RHP[0]) / 2.0
                    trunk_offset_norm = safe_div((mid_sh_x - mid_hp_x), shoulder_width)

                    # midpoints
                    mid_sh = ((LSH[0] + RSH[0]) / 2.0, (LSH[1] + RSH[1]) / 2.0)
                    mid_hp = ((LHP[0] + RHP[0]) / 2.0, (LHP[1] + RHP[1]) / 2.0)

                    # forward/back lean proxy: torso "compression"
                    torso_h_norm = abs(mid_sh[1] - mid_hp[1]) / shoulder_width

                    # calibrate torso_h0 during early frames
                    if torso_h0 is None:
                        torso_h_samples.append(float(torso_h_norm))
                        if len(torso_h_samples) >= BASELINE_FRAMES:
                            torso_h0 = float(np.median(torso_h_samples))
                            if torso_h0 < TORSO_COMP_MIN_BASE:
                                torso_h0 = TORSO_COMP_MIN_BASE

                    # wrists relative heights
                    yR = safe_div((RSH[1] - RWR[1]), shoulder_width)
                    yL = safe_div((LSH[1] - LWR[1]), shoulder_width)

                    # elbow angles
                    angR = calculate_angle((RSH[0], RSH[1]), (REL[0], REL[1]), (RWR[0], RWR[1]))
                    angL = calculate_angle((LSH[0], LSH[1]), (LEL[0], LEL[1]), (LWR[0], LWR[1]))

                    # choose arm by wrist visibility; rep counter locks it
                    use_right = (RWR[2] >= LWR[2])
                    arm_label = "R" if use_right else "L"
                    wrist_rel_y = yR if use_right else yL
                    elbow_angle = angR if use_right else angL

                    # ---------------- rules with streaking ----------------
                    # trunk side-to-side
                    if abs(trunk_offset_norm) > TRUNK_BAD:
                        trunk_streak += 1
                    elif abs(trunk_offset_norm) > TRUNK_WARN:
                        trunk_streak = max(trunk_streak, 1)
                    else:
                        trunk_streak = 0

                    if trunk_streak >= BAD_STREAK:
                        trunk_level = 2
                        set_counts["trunk_bad"] += 1
                        bad.append("Avoid leaning / swinging (side-to-side)")
                    elif trunk_streak >= WARN_STREAK:
                        trunk_level = 1
                        set_counts["trunk_warn"] += 1
                        tips.append("Reduce torso swing")

                    # forward/back lean via torso compression drop
                    if torso_h0 is not None:
                        drop = (torso_h0 - torso_h_norm) / (torso_h0 + 1e-6)

                        if drop > TORSO_COMP_BAD_DROP:
                            tilt_streak += 1
                        elif drop > TORSO_COMP_WARN_DROP:
                            tilt_streak = max(tilt_streak, 1)
                        else:
                            tilt_streak = 0

                        if tilt_streak >= BAD_STREAK:
                            tilt_level = 2
                            set_counts["tilt_bad"] += 1
                            bad.append("Don't hinge forward/back (stay upright)")
                        elif tilt_streak >= WARN_STREAK:
                            tilt_level = 1
                            set_counts["tilt_warn"] += 1
                            tips.append("Stay upright (avoid forward lean)")

                    # asymmetry
                    asym = abs(yR - yL)
                    if asym > ASYM_BAD:
                        asym_streak += 1
                    elif asym > ASYM_WARN:
                        asym_streak = max(asym_streak, 1)
                    else:
                        asym_streak = 0

                    if asym_streak >= BAD_STREAK:
                        asym_level = 2
                        set_counts["asym_bad"] += 1
                        bad.append("Raise both arms evenly")
                    elif asym_streak >= WARN_STREAK:
                        asym_level = 1
                        set_counts["asym_warn"] += 1
                        tips.append("Even out both arms")

                    # elbow bend per side
                    if angR < ELBOW_BAD:
                        elbow_streak_R += 1
                    elif angR < ELBOW_WARN:
                        elbow_streak_R = max(elbow_streak_R, 1)
                    else:
                        elbow_streak_R = 0

                    if elbow_streak_R >= BAD_STREAK:
                        elbow_level_right = 2
                        set_counts["elbow_bad_right"] += 1
                    elif elbow_streak_R >= WARN_STREAK:
                        elbow_level_right = 1
                        set_counts["elbow_warn_right"] += 1

                    if angL < ELBOW_BAD:
                        elbow_streak_L += 1
                    elif angL < ELBOW_WARN:
                        elbow_streak_L = max(elbow_streak_L, 1)
                    else:
                        elbow_streak_L = 0

                    if elbow_streak_L >= BAD_STREAK:
                        elbow_level_left = 2
                        set_counts["elbow_bad_left"] += 1
                    elif elbow_streak_L >= WARN_STREAK:
                        elbow_level_left = 1
                        set_counts["elbow_warn_left"] += 1

                    # decide text
                    if bad:
                        feedback = "UNSAFE: " + bad[0]
                        fb_color = BAD_COLOR
                    elif tips:
                        feedback = "COACHING: " + tips[0]
                        fb_color = WARN_COLOR
                    else:
                        worst_elbow = max(elbow_level_left, elbow_level_right)
                        if worst_elbow == 2:
                            feedback = "UNSAFE: Don't curl (elbow too bent)"
                            fb_color = BAD_COLOR
                        elif worst_elbow == 1:
                            feedback = "COACHING: Keep arms straighter"
                            fb_color = WARN_COLOR
                        else:
                            feedback = "STATUS: Stable"
                            fb_color = GOOD_COLOR

                    highlight_issues(frame, res.pose_landmarks,
                                     trunk_level, tilt_level, asym_level,
                                     elbow_level_right, elbow_level_left)

                    # remember issues during rep
                    if rep_counter.state == "up":
                        rep_bad = list(bad)
                        rep_tips = list(tips)
                        worst_elbow = max(elbow_level_left, elbow_level_right)
                        if worst_elbow == 2:
                            rep_bad.append("Don't curl (elbow too bent)")
                        elif worst_elbow == 1:
                            rep_tips.append("Keep arms straighter")
                        rep_counter.mark_feedback(rep_bad, rep_tips)

                    # rep update
                    y_s, rep_done, rep_sum = rep_counter.update(
                        wrist_rel_y=wrist_rel_y,
                        trunk_offset_norm=trunk_offset_norm,
                        elbow_angle=elbow_angle,
                        arm_label=arm_label
                    )

                    # rep complete => ML + fatigue + JSON
                    if rep_done and rep_sum:
                        trunk_clip = min(rep_sum["trunk_absmax"], 0.55)
                        elbow_clip = float(np.clip(rep_sum["elbow_min"], 60.0, 180.0))

                        feat_map = {
                            "wrist_rel_range": rep_sum["wrist_rel_range"],
                            "duration": rep_sum["duration"],
                            "trunk_absmax": trunk_clip,
                            "elbow_min": elbow_clip,
                        }

                        missing = [f for f in feats if f not in feat_map]
                        if missing:
                            print("Model expects missing features:", missing)
                            continue

                        x = np.array([[feat_map[f] for f in feats]], dtype=np.float32)
                        xs = scaler.transform(x)
                        score = float(model.decision_function(xs)[0])

                        recent.append({
                            "range": rep_sum["wrist_rel_range"],
                            "duration": rep_sum["duration"],
                            "elbow": elbow_clip,
                            "score": score
                        })

                        # baseline calibration (good reps only)
                        if (not baseline_ready) and (not rep_sum.get("rep_bad_seen", False)):
                            calib_reps.append(recent[-1])
                            if len(calib_reps) >= CALIB_REPS:
                                baseline["range"] = median_or([r["range"] for r in calib_reps], 0.35)
                                baseline["duration"] = median_or([r["duration"] for r in calib_reps], 1.6)
                                baseline["elbow"] = median_or([r["elbow"] for r in calib_reps], 145.0)
                                baseline_ready = True
                                fatigue_text = ""
                                fatigue_color = TEXT_COLOR

                        # fatigue compute
                        comps = {}
                        fatigue_text = ""
                        fatigue_color = TEXT_COLOR
                        if baseline_ready and len(recent) >= 4:
                            last3 = list(recent)[-3:]
                            range_med = median_or([r["range"] for r in last3], baseline["range"])
                            dur_med   = median_or([r["duration"] for r in last3], baseline["duration"])
                            elbow_med = median_or([r["elbow"] for r in last3], baseline["elbow"])

                            fatigue_index, comps = compute_fatigue_index(baseline, range_med, dur_med, elbow_med)

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
                                    "exercise": "lateral_raise",
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

                        # ML softness (rolling baseline)
                        score_hist.append(float(score))
                        use_relative = (len(score_hist) >= ML_MIN_SCORES_FOR_REL)
                        score_ref = float(np.median(score_hist)) if use_relative else float(thr)

                        ml_low_rel = use_relative and (score < (score_ref - ML_REL_DROP))
                        ml_low_abs = (score < (thr - ML_MARGIN))
                        ml_low = ml_low_rel if use_relative else ml_low_abs

                        ml_low_streak = ml_low_streak + 1 if ml_low else 0
                        ml_tip = (ml_low_streak >= ML_LOW_STREAK_FOR_TIP)

                        rep_tips = []
                        if fatigue_text:
                            rep_tips.append("Fatigue trend - consider rest or lighter weight")
                        if baseline_ready and rep_sum["wrist_rel_range"] < 0.55 * baseline["range"]:
                            rep_tips.append("Range dropping - lighten weight or rest")
                        if baseline_ready and rep_sum["duration"] > 1.8 * baseline["duration"]:
                            rep_tips.append("Tempo slowing - stay controlled")
                        if baseline_ready and rep_sum["elbow_min"] < (baseline["elbow"] - 18.0):
                            rep_tips.append("Arms bending more - avoid upright-row motion")
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
                            any_tip = rep_sum.get("rep_tip_seen", False) or ml_tip or bool(rep_tips)
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
                            "arm": rep_sum.get("arm", "?"),
                        })
                        rep_history = rep_history[-8:]

                        issues = top_set_issues(set_counts)
                        issues_str = ", ".join([f"{n} x{c}" for n, c in issues]) if issues else "no major issues"

                        write_status({
                            "state": "running",
                            "exercise": "lateral_raise",
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

                    # Debug overlay (optional): helps validate lean detection quickly
                    if torso_h0 is not None:
                        cv2.putText(frame, f"torso_h={torso_h_norm:.2f} base={torso_h0:.2f}",
                                    (10, 120), cv2.FONT_HERSHEY_SIMPLEX, 0.6, TEXT_COLOR, 2)

                else:
                    set_counts["low_conf"] += 1
                    feedback = f"Low pose confidence ({conf_mean:.2f})"
                    fb_color = WARN_COLOR

            cv2.putText(frame, feedback, (10, h - 110),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, fb_color, 2)

            if fatigue_text:
                cv2.putText(frame, fatigue_text, (10, h - 75),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.7, fatigue_color, 2)

            cv2.putText(frame, last_rep_text, (10, h - 35),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, last_rep_color, 2)

            cv2.imshow("LiftRight - Lateral Raise", frame)
            key = cv2.waitKey(1) & 0xFF
            if key == 27 or key == ord("q"):
                write_status({"state": "stopped", "message": "User closed the tracker."})
                break

    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
