import cv2
import numpy as np
import mediapipe as mp
import joblib
import time
from collections import deque
from pathlib import Path

# ---------------- CONFIG ----------------
PROJECT_ROOT = Path(__file__).resolve().parents[1]
MODEL_PKL = PROJECT_ROOT / "models" / "bicep_curl_ocsvm.pkl"

CAM_INDEX = 0
MIN_CONF = 0.5

# Rep detection thresholds (front-facing bicep curl)
TOP_THR = 75
BOT_THR = 155
SMOOTH_N = 7
MIN_REP_TIME = 0.35  # debounce seconds

# Continuous feedback thresholds (front-view heuristics)
TRUNK_BAD = 0.12           # normalized trunk offset magnitude
ELBOW_DRIFT_BAD = 0.18     # normalized |elbow_x - shoulder_x| / shoulder_width

GOOD_COLOR = (0, 255, 0)
WARN_COLOR = (0, 255, 255)
BAD_COLOR  = (0, 0, 255)
TEXT_COLOR = (240, 240, 240)

# ---------------- MEDIAPIPE ----------------
mp_pose = mp.solutions.pose
mp_draw = mp.solutions.drawing_utils

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
        self.trunk = []

    def update(self, elbow_angle, trunk_offset_norm):
        now = time.time()
        self.buf.append(float(elbow_angle))
        ang_s = float(np.median(self.buf))

        self.angles.append(ang_s)
        self.trunk.append(float(trunk_offset_norm))

        rep_done = False
        rep_summary = None

        if self.state == "down":
            if ang_s <= TOP_THR:
                self.state = "up"
        else:
            if ang_s >= BOT_THR:
                # debounce
                if (now - self.last_rep_t) >= MIN_REP_TIME and len(self.angles) >= 6:
                    self.rep_count += 1
                    self.last_rep_t = now
                    rep_done = True

                    angles = np.array(self.angles, dtype=np.float32)
                    trunk  = np.array(self.trunk, dtype=np.float32)

                    rep_summary = {
                        "rep": self.rep_count,
                        "min_angle": float(angles.min()),
                        "max_angle": float(angles.max()),
                        "rom": float(angles.max() - angles.min()),
                        "duration": float(now - self.rep_start_t),
                        "trunk_absmax": float(np.max(np.abs(trunk))),
                    }

                self.state = "down"
                self.reset_rep(now)

        return ang_s, rep_done, rep_summary

def main():
    # Load model bundle
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

    rep_counter = CurlRepCounter()
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

                # landmarks
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

                    # choose best arm per frame by elbow visibility (simple)
                    use_right = (REL[2] >= LEL[2])

                    if use_right:
                        elbow_angle = calculate_angle((RSH[0], RSH[1]), (REL[0], REL[1]), (RWR[0], RWR[1]))
                        elbow_drift = abs(REL[0] - RSH[0])
                    else:
                        elbow_angle = calculate_angle((LSH[0], LSH[1]), (LEL[0], LEL[1]), (LWR[0], LWR[1]))
                        elbow_drift = abs(LEL[0] - LSH[0])

                    elbow_drift_norm = safe_div(elbow_drift, shoulder_width)

                    # Continuous feedback (rules)
                    problems = []
                    if abs(trunk_offset_norm) > TRUNK_BAD:
                        problems.append("Avoid swinging / leaning")
                    if elbow_drift_norm > ELBOW_DRIFT_BAD:
                        problems.append("Keep elbow closer to shoulder line")

                    if not problems:
                        feedback = "Good form (rules)"
                        fb_color = GOOD_COLOR
                    elif len(problems) == 1:
                        feedback = problems[0]
                        fb_color = WARN_COLOR
                    else:
                        feedback = problems[0] + " + " + problems[1]
                        fb_color = BAD_COLOR

                    # Rep update
                    elbow_s, rep_done, rep_sum = rep_counter.update(elbow_angle, trunk_offset_norm)

                    # Draw skeleton
                    mp_draw.draw_landmarks(frame, res.pose_landmarks, mp_pose.POSE_CONNECTIONS)

                    # If rep completed -> score it with OCSVM
                    if rep_done and rep_sum:
                        # Build feature vector in the same order as training FEATURES
                        # Note: clip trunk_absmax to match training behavior
                        trunk_clip = min(rep_sum["trunk_absmax"], 0.3)

                        feat_map = {
                            "rom": rep_sum["rom"],
                            "duration": rep_sum["duration"],
                            "trunk_absmax": trunk_clip,
                            "min_angle": rep_sum["min_angle"],
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

                        print(last_rep_text, "score=", score)

                    # Overlay main stats
                    cv2.putText(frame, f"Reps: {rep_counter.rep_count}  State: {rep_counter.state}",
                                (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.8, TEXT_COLOR, 2)
                    cv2.putText(frame, f"Elbow(smooth): {elbow_s:.1f}",
                                (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.7, TEXT_COLOR, 2)
                    cv2.putText(frame, f"Conf: {conf_mean:.2f}",
                                (10, 90), cv2.FONT_HERSHEY_SIMPLEX, 0.7, TEXT_COLOR, 2)

                else:
                    feedback = f"Low pose confidence ({conf_mean:.2f})"
                    fb_color = WARN_COLOR

            # Feedback overlays (always show)
            cv2.putText(frame, feedback, (10, h - 60),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, fb_color, 2)

            cv2.putText(frame, last_rep_text, (10, h - 25),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, last_rep_color, 2)

            cv2.imshow("LiftRight - Bicep Curl (MVP)", frame)
            key = cv2.waitKey(1) & 0xFF
            if key == 27 or key == ord("q"):
                break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
