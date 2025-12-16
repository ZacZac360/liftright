import cv2
import numpy as np
import mediapipe as mp
import joblib
import time
from collections import deque
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
MODEL_PKL = PROJECT_ROOT / "models" / "lateral_raise_ocsvm.pkl"

CAM_INDEX = 0
MIN_CONF = 0.5

SMOOTH_N = 7
MIN_REP_TIME = 0.35
MAX_REP_TIME = 6.0

BASELINE_FRAMES = 30
DOWN_OFFSET = 0.02
UP_OFFSET   = 0.20

# continuous rules (tune later)
TRUNK_BAD = 0.12
ASYM_BAD  = 0.25         # L/R wrist height mismatch
ELBOW_TOO_BENT = 120.0   # lateral raise shouldn’t turn into upright row curls

GOOD_COLOR = (0, 255, 0)
WARN_COLOR = (0, 255, 255)
BAD_COLOR  = (0, 0, 255)
TEXT_COLOR = (240, 240, 240)

mp_pose = mp.solutions.pose
mp_draw = mp.solutions.drawing_utils

def lm_xyv(landmarks, idx, w, h):
    lm = landmarks[idx]
    return (lm.x * w, lm.y * h, float(lm.visibility))

def safe_div(a, b, eps=1e-6):
    return float(a / (b + eps))

class LateralRepCounter:
    def __init__(self):
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
        self.max_wrist_rel_y = -999.0

    def update_baseline(self, y_s):
        if self.baseline_ready:
            return
        self.baseline_samples.append(float(y_s))
        if len(self.baseline_samples) >= BASELINE_FRAMES:
            s = np.array(self.baseline_samples, dtype=np.float32)
            s = s[np.isfinite(s)]
            base = float(np.median(s)) if len(s) else 0.05

            self.baseline = base
            self.down_thr = max(0.02, self.baseline + DOWN_OFFSET)
            self.up_thr   = self.down_thr + UP_OFFSET
            self.baseline_ready = True

    def update(self, wrist_rel_y, trunk_offset_norm, elbow_angle):
        now = time.time()

        self.buf.append(float(wrist_rel_y))
        y_s = float(np.median(self.buf))

        self.update_baseline(y_s)

        self.vals.append(y_s)
        self.trunk.append(float(trunk_offset_norm))
        self.elbow.append(float(elbow_angle))
        self.max_wrist_rel_y = max(self.max_wrist_rel_y, y_s)

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

        if self.state == "down":
            if y_s >= self.up_thr:
                self.state = "up"
        else:  # up
            if y_s <= self.down_thr:
                if (now - self.last_rep_t) >= MIN_REP_TIME and len(self.vals) >= 6:
                    self.rep_count += 1
                    self.last_rep_t = now
                    rep_done = True

                    vals  = np.array(self.vals, dtype=np.float32)
                    trunk = np.array(self.trunk, dtype=np.float32)
                    elbow = np.array(self.elbow, dtype=np.float32)

                    rep_summary = {
                        "rep": self.rep_count,
                        "min_wrist_rel_y": float(vals.min()),
                        "max_wrist_rel_y": float(vals.max()),
                        "wrist_rel_range": float(vals.max() - vals.min()),
                        "duration": float(now - self.rep_start_t),
                        "trunk_absmax": float(np.max(np.abs(trunk))),
                        "elbow_min": float(np.min(elbow)),
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

    rep_counter = LateralRepCounter()
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
                LEL = lm_xyv(lm, mp_pose.PoseLandmark.LEFT_ELBOW,     w, h)
                REL = lm_xyv(lm, mp_pose.PoseLandmark.RIGHT_ELBOW,    w, h)
                LWR = lm_xyv(lm, mp_pose.PoseLandmark.LEFT_WRIST,     w, h)
                RWR = lm_xyv(lm, mp_pose.PoseLandmark.RIGHT_WRIST,    w, h)
                LHP = lm_xyv(lm, mp_pose.PoseLandmark.LEFT_HIP,       w, h)
                RHP = lm_xyv(lm, mp_pose.PoseLandmark.RIGHT_HIP,      w, h)

                conf_mean = float(np.mean([LSH[2], RSH[2], LEL[2], REL[2], LWR[2], RWR[2], LHP[2], RHP[2]]))

                if conf_mean >= MIN_CONF:
                    shoulder_width = abs(LSH[0] - RSH[0])
                    if shoulder_width < 2:
                        shoulder_width = 2

                    mid_sh_x = (LSH[0] + RSH[0]) / 2.0
                    mid_hp_x = (LHP[0] + RHP[0]) / 2.0
                    trunk_offset_norm = safe_div((mid_sh_x - mid_hp_x), shoulder_width)

                    # wrist relative heights (positive = above shoulder line)
                    R_wrist_rel_y = safe_div((RSH[1] - RWR[1]), shoulder_width)
                    L_wrist_rel_y = safe_div((LSH[1] - LWR[1]), shoulder_width)

                    # choose arm by wrist visibility
                    use_right = (RWR[2] >= LWR[2])
                    wrist_rel_y = R_wrist_rel_y if use_right else L_wrist_rel_y

                    # elbow angle for that arm
                    if use_right:
                        # angle at elbow: shoulder-elbow-wrist
                        a = np.array([RSH[0], RSH[1]], dtype=np.float32)
                        b = np.array([REL[0], REL[1]], dtype=np.float32)
                        c = np.array([RWR[0], RWR[1]], dtype=np.float32)
                    else:
                        a = np.array([LSH[0], LSH[1]], dtype=np.float32)
                        b = np.array([LEL[0], LEL[1]], dtype=np.float32)
                        c = np.array([LWR[0], LWR[1]], dtype=np.float32)

                    ba = a - b
                    bc = c - b
                    denom = (np.linalg.norm(ba) * np.linalg.norm(bc) + 1e-6)
                    cosang = float(np.dot(ba, bc) / denom)
                    cosang = float(np.clip(cosang, -1.0, 1.0))
                    elbow_angle = float(np.degrees(np.arccos(cosang)))

                    # continuous rules
                    problems = []
                    if abs(trunk_offset_norm) > TRUNK_BAD:
                        problems.append("Avoid leaning / swinging")
                    if abs(R_wrist_rel_y - L_wrist_rel_y) > ASYM_BAD:
                        problems.append("Raise both arms evenly")
                    if elbow_angle < ELBOW_TOO_BENT:
                        problems.append("Don’t curl (too much elbow bend)")

                    if not problems:
                        feedback = "Good form (rules)"
                        fb_color = GOOD_COLOR
                    elif len(problems) == 1:
                        feedback = problems[0]
                        fb_color = WARN_COLOR
                    else:
                        feedback = problems[0] + " + " + problems[1]
                        fb_color = BAD_COLOR

                    # rep update
                    y_s, rep_done, rep_sum = rep_counter.update(wrist_rel_y, trunk_offset_norm, elbow_angle)

                    mp_draw.draw_landmarks(frame, res.pose_landmarks, mp_pose.POSE_CONNECTIONS)

                    if rep_done and rep_sum:
                        trunk_clip = min(rep_sum["trunk_absmax"], 0.3)
                        feat_map = {
                            "wrist_rel_range": rep_sum["wrist_rel_range"],
                            "duration": rep_sum["duration"],
                            "trunk_absmax": trunk_clip,
                            "elbow_min": rep_sum["elbow_min"],
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
                              "| down=", rep_sum["down_thr"], "up=", rep_sum["up_thr"])

                    base_txt = "Calibrating..." if not rep_counter.baseline_ready else f"down={rep_counter.down_thr:.2f} up={rep_counter.up_thr:.2f}"
                    cv2.putText(frame, f"Reps: {rep_counter.rep_count}  State: {rep_counter.state}",
                                (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.8, TEXT_COLOR, 2)
                    cv2.putText(frame, f"WristRel(smooth): {y_s:.2f}  {base_txt}",
                                (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.7, TEXT_COLOR, 2)
                    cv2.putText(frame, f"Elbow: {elbow_angle:.0f}  Conf: {conf_mean:.2f}",
                                (10, 90), cv2.FONT_HERSHEY_SIMPLEX, 0.7, TEXT_COLOR, 2)

                else:
                    feedback = f"Low pose confidence ({conf_mean:.2f})"
                    fb_color = WARN_COLOR

            cv2.putText(frame, feedback, (10, h - 60),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, fb_color, 2)
            cv2.putText(frame, last_rep_text, (10, h - 25),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, last_rep_color, 2)

            cv2.imshow("LiftRight - Lateral Raise (MVP)", frame)
            key = cv2.waitKey(1) & 0xFF
            if key == 27 or key == ord("q"):
                break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
