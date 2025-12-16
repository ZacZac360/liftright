import cv2
import numpy as np
import mediapipe as mp
import joblib
import time
from collections import deque
from pathlib import Path

# ---------------- CONFIG ----------------
PROJECT_ROOT = Path(__file__).resolve().parents[1]
MODEL_PKL = PROJECT_ROOT / "models" / "shoulder_press_ocsvm.pkl"

CAM_INDEX = 0
MIN_CONF = 0.5

# smoothing + debounce
SMOOTH_N = 7
MIN_REP_TIME = 0.35

# adaptive thresholding (per session)
BASELINE_FRAMES = 30      # ~1 sec
DOWN_OFFSET = 0.02        # baseline + offset
UP_OFFSET = 0.25          # down_thr + offset

# safety reset if we get stuck
MAX_REP_TIME = 6.0

# continuous feedback thresholds (heuristics)
TRUNK_BAD = 0.12          # leaning/swinging
ASYM_BAD  = 0.25          # L/R wrist height mismatch (normalized)

GOOD_COLOR = (0, 255, 0)
WARN_COLOR = (0, 255, 255)
BAD_COLOR  = (0, 0, 255)
TEXT_COLOR = (240, 240, 240)

# ---------------- MEDIAPIPE ----------------
mp_pose = mp.solutions.pose
mp_draw = mp.solutions.drawing_utils

def lm_xyv(landmarks, idx, w, h):
    lm = landmarks[idx]
    return (lm.x * w, lm.y * h, float(lm.visibility))

def safe_div(a, b, eps=1e-6):
    return float(a / (b + eps))

class PressRepCounter:
    """
    Shoulder press rep counter based on wrist relative height (wrist_rel_y).
    - Learns baseline from first second of frames.
    - Counts rep after: down -> up -> down.
    """
    def __init__(self):
        self.buf = deque(maxlen=SMOOTH_N)
        self.state = "down"
        self.rep_count = 0
        self.last_rep_t = 0.0

        self.baseline_samples = []
        self.baseline_ready = False
        self.baseline = 0.10
        self.down_thr = 0.10
        self.up_thr = 0.45

        self.reset_rep(time.time())

    def reset_rep(self, t):
        self.rep_start_t = t
        self.vals = []
        self.trunk = []
        self.max_wrist_rel_y = -999.0

    def update_baseline(self, wrist_rel_y):
        if self.baseline_ready:
            return
        self.baseline_samples.append(float(wrist_rel_y))

        if len(self.baseline_samples) >= BASELINE_FRAMES:
            s = np.array(self.baseline_samples, dtype=np.float32)
            s = s[np.isfinite(s)]

            # raw baseline
            base_med = float(np.median(s))

            # "rack guess": median of the upper half of early samples
            s_sorted = np.sort(s)
            upper_half = s_sorted[len(s_sorted)//2:]
            rack_guess = float(np.median(upper_half)) if len(upper_half) else base_med

            # If baseline is very low, assume we started arms-down and use rack_guess
            if base_med < 0.15 and rack_guess > base_med + 0.10:
                baseline = rack_guess
            else:
                baseline = base_med

            self.baseline = float(baseline)

            # Down should be around rack, not arms-at-sides
            self.down_thr = max(0.15, self.baseline - 0.05)   # rack return threshold
            self.up_thr   = self.down_thr + UP_OFFSET

            self.baseline_ready = True

    def update(self, wrist_rel_y, trunk_offset_norm):
        now = time.time()

        # smooth wrist height
        self.buf.append(float(wrist_rel_y))
        y_s = float(np.median(self.buf))

        # baseline calibration
        self.update_baseline(y_s)

        # collect per-rep signals
        self.vals.append(y_s)
        self.trunk.append(float(trunk_offset_norm))
        self.max_wrist_rel_y = max(self.max_wrist_rel_y, y_s)

        # safety reset if stuck too long
        if (now - self.rep_start_t) > MAX_REP_TIME:
            self.state = "down"
            self.reset_rep(now)
            self.buf.clear()
            return y_s, False, None

        rep_done = False
        rep_summary = None

        # if baseline isn't ready yet, don't count reps
        if not self.baseline_ready:
            return y_s, False, None

        if self.state == "down":
            if y_s >= self.up_thr:
                self.state = "up"
        else:  # up
            if y_s <= self.down_thr:
                if (now - self.last_rep_t) >= MIN_REP_TIME and len(self.vals) >= 6:
                    self.rep_count += 1
                    self.last_rep_t = now
                    rep_done = True

                    vals = np.array(self.vals, dtype=np.float32)
                    trunk = np.array(self.trunk, dtype=np.float32)

                    rep_summary = {
                        "rep": self.rep_count,
                        "min_wrist_rel_y": float(vals.min()),
                        "max_wrist_rel_y": float(vals.max()),
                        "wrist_rel_range": float(vals.max() - vals.min()),
                        "duration": float(now - self.rep_start_t),
                        "trunk_absmax": float(np.max(np.abs(trunk))),
                        "baseline": float(self.baseline),
                        "down_thr": float(self.down_thr),
                        "up_thr": float(self.up_thr),
                    }

                self.state = "down"
                self.reset_rep(now)

        return y_s, rep_done, rep_summary

def main():
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
        return

    rep_counter = PressRepCounter()
    last_rep_text = "—"
    last_rep_color = TEXT_COLOR

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

            feedback = "No pose"
            fb_color = TEXT_COLOR

            if res.pose_landmarks:
                lm = res.pose_landmarks.landmark

                LSH = lm_xyv(lm, mp_pose.PoseLandmark.LEFT_SHOULDER,  w, h)
                RSH = lm_xyv(lm, mp_pose.PoseLandmark.RIGHT_SHOULDER, w, h)
                LWR = lm_xyv(lm, mp_pose.PoseLandmark.LEFT_WRIST,     w, h)
                RWR = lm_xyv(lm, mp_pose.PoseLandmark.RIGHT_WRIST,    w, h)
                LHP = lm_xyv(lm, mp_pose.PoseLandmark.LEFT_HIP,       w, h)
                RHP = lm_xyv(lm, mp_pose.PoseLandmark.RIGHT_HIP,      w, h)

                conf_mean = float(np.mean([LSH[2], RSH[2], LWR[2], RWR[2], LHP[2], RHP[2]]))

                if conf_mean >= MIN_CONF:
                    shoulder_width = abs(LSH[0] - RSH[0])
                    if shoulder_width < 2:
                        shoulder_width = 2

                    # trunk offset (lean/swing proxy)
                    mid_sh_x = (LSH[0] + RSH[0]) / 2.0
                    mid_hp_x = (LHP[0] + RHP[0]) / 2.0
                    trunk_offset_norm = safe_div((mid_sh_x - mid_hp_x), shoulder_width)

                    # wrist relative heights (positive = wrist above shoulder)
                    R_wrist_rel_y = safe_div((RSH[1] - RWR[1]), shoulder_width)
                    L_wrist_rel_y = safe_div((LSH[1] - LWR[1]), shoulder_width)

                    # choose arm by wrist visibility (simple per-frame)
                    use_right = (RWR[2] >= LWR[2])
                    wrist_rel_y = R_wrist_rel_y if use_right else L_wrist_rel_y

                    # continuous feedback rules
                    problems = []
                    if abs(trunk_offset_norm) > TRUNK_BAD:
                        problems.append("Avoid leaning / back arch")
                    if abs(R_wrist_rel_y - L_wrist_rel_y) > ASYM_BAD:
                        problems.append("Keep arms even")

                    if not problems:
                        feedback = "Good form (rules)"
                        fb_color = GOOD_COLOR
                    elif len(problems) == 1:
                        feedback = problems[0]
                        fb_color = WARN_COLOR
                    else:
                        feedback = problems[0] + " + " + problems[1]
                        fb_color = BAD_COLOR

                    # update rep counter
                    y_s, rep_done, rep_sum = rep_counter.update(wrist_rel_y, trunk_offset_norm)

                    # draw skeleton
                    mp_draw.draw_landmarks(frame, res.pose_landmarks, mp_pose.POSE_CONNECTIONS)

                    # rep scoring (model)
                    if rep_done and rep_sum:
                        trunk_clip = min(rep_sum["trunk_absmax"], 0.3)

                        feat_map = {
                            "wrist_rel_range": rep_sum["wrist_rel_range"],
                            "duration": rep_sum["duration"],
                            "trunk_absmax": trunk_clip,
                            "max_wrist_rel_y": rep_sum["max_wrist_rel_y"],
                        }

                        x = np.array([[feat_map[f] for f in feats]], dtype=np.float32)
                        xs = scaler.transform(x)
                        score = float(model.decision_function(xs)[0])

                        if score >= thr:
                            last_rep_text = f"Rep {rep_sum['rep']}: GOOD"
                            last_rep_color = GOOD_COLOR
                        else:
                            last_rep_text = f"Rep {rep_sum['rep']}: POSSIBLE DEVIATION"
                            last_rep_color = BAD_COLOR

                        print(last_rep_text, "score=", score,
                              "| baseline=", rep_sum["baseline"],
                              "down=", rep_sum["down_thr"],
                              "up=", rep_sum["up_thr"])

                    # HUD
                    base_txt = "Calibrating..." if not rep_counter.baseline_ready else f"down={rep_counter.down_thr:.2f} up={rep_counter.up_thr:.2f}"
                    cv2.putText(frame, f"Reps: {rep_counter.rep_count}  State: {rep_counter.state}",
                                (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.8, TEXT_COLOR, 2)
                    cv2.putText(frame, f"WristRel(smooth): {y_s:.2f}  {base_txt}",
                                (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.7, TEXT_COLOR, 2)
                    cv2.putText(frame, f"Conf: {conf_mean:.2f}",
                                (10, 90), cv2.FONT_HERSHEY_SIMPLEX, 0.7, TEXT_COLOR, 2)

                else:
                    feedback = f"Low pose confidence ({conf_mean:.2f})"
                    fb_color = WARN_COLOR

            # Feedback overlays
            cv2.putText(frame, feedback, (10, h - 60),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, fb_color, 2)
            cv2.putText(frame, last_rep_text, (10, h - 25),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, last_rep_color, 2)

            cv2.imshow("LiftRight - Shoulder Press (MVP)", frame)
            key = cv2.waitKey(1) & 0xFF
            if key == 27 or key == ord("q"):
                break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
