import os
import cv2
import numpy as np
import pandas as pd
import mediapipe as mp
from pathlib import Path

# ---------------- CONFIG ----------------
PROJECT_ROOT = Path(__file__).resolve().parents[1]   # .../ml
VIDEOS_DIR   = PROJECT_ROOT / "videos"
OUT_DIR      = PROJECT_ROOT / "datasets" / "frames"
OUT_DIR.mkdir(parents=True, exist_ok=True)

EXERCISES = ["bicep_curl", "lateral_raise", "shoulder_press"]

MIN_DET_CONF = 0.5
MIN_TRK_CONF = 0.5

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

def extract_video(video_path: Path, exercise: str):
    """
    Extract per-frame pose-based features from a single video.
    Returns list of dict rows.
    """
    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        print("!! Could not open:", video_path)
        return []

    fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    rows = []

    # participant_id from filename prefix: benj_bicep.mp4 -> benj
    base = video_path.stem
    participant_id = base.split("_")[0].strip().lower()

    with mp_pose.Pose(
        static_image_mode=False,
        model_complexity=1,
        smooth_landmarks=True,
        enable_segmentation=False,
        min_detection_confidence=MIN_DET_CONF,
        min_tracking_confidence=MIN_TRK_CONF,
    ) as pose:

        frame_idx = 0
        while True:
            ret, frame = cap.read()
            if not ret:
                break

            h, w = frame.shape[:2]
            t = frame_idx / fps

            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            res = pose.process(rgb)

            if not res.pose_landmarks:
                frame_idx += 1
                continue

            lm = res.pose_landmarks.landmark

            # Key landmarks (x,y in pixels + visibility)
            LSH = lm_xyv(lm, mp_pose.PoseLandmark.LEFT_SHOULDER,  w, h)
            RSH = lm_xyv(lm, mp_pose.PoseLandmark.RIGHT_SHOULDER, w, h)
            LEL = lm_xyv(lm, mp_pose.PoseLandmark.LEFT_ELBOW,     w, h)
            REL = lm_xyv(lm, mp_pose.PoseLandmark.RIGHT_ELBOW,    w, h)
            LWR = lm_xyv(lm, mp_pose.PoseLandmark.LEFT_WRIST,     w, h)
            RWR = lm_xyv(lm, mp_pose.PoseLandmark.RIGHT_WRIST,    w, h)
            LHP = lm_xyv(lm, mp_pose.PoseLandmark.LEFT_HIP,       w, h)
            RHP = lm_xyv(lm, mp_pose.PoseLandmark.RIGHT_HIP,      w, h)

            confs = [LSH[2], RSH[2], LEL[2], REL[2], LWR[2], RWR[2], LHP[2], RHP[2]]
            conf_mean = float(np.mean(confs))

            # Normalize by shoulder width (stable for front view)
            shoulder_width = abs(LSH[0] - RSH[0])
            if shoulder_width < 1:
                frame_idx += 1
                continue

            mid_sh_x = (LSH[0] + RSH[0]) / 2.0
            mid_hp_x = (LHP[0] + RHP[0]) / 2.0
            trunk_offset_norm = safe_div((mid_sh_x - mid_hp_x), shoulder_width)

            # Right-arm angles (we’ll store both arms so we can choose later)
            right_elbow_angle = calculate_angle(
                (RSH[0], RSH[1]),
                (REL[0], REL[1]),
                (RWR[0], RWR[1])
            )
            left_elbow_angle = calculate_angle(
                (LSH[0], LSH[1]),
                (LEL[0], LEL[1]),
                (LWR[0], LWR[1])
            )

            # Wrist relative height to shoulder line (positive = wrist above shoulder)
            right_wrist_rel_y = safe_div((RSH[1] - RWR[1]), shoulder_width)
            left_wrist_rel_y  = safe_div((LSH[1] - LWR[1]), shoulder_width)

            row = {
                "exercise": exercise,
                "video_id": base,
                "participant_id": participant_id,
                "frame_idx": frame_idx,
                "time_sec": t,
                "fps": fps,
                "conf_mean": conf_mean,

                "shoulder_width_px": float(shoulder_width),
                "trunk_offset_norm": trunk_offset_norm,

                "R_elbow_angle": float(right_elbow_angle),
                "L_elbow_angle": float(left_elbow_angle),

                "R_wrist_rel_y": float(right_wrist_rel_y),
                "L_wrist_rel_y": float(left_wrist_rel_y),

                # raw landmark x (normalized in future if needed)
                "R_sh_x": float(RSH[0]),
                "R_el_x": float(REL[0]),
                "R_wr_x": float(RWR[0]),
                "L_sh_x": float(LSH[0]),
                "L_el_x": float(LEL[0]),
                "L_wr_x": float(LWR[0]),
            }
            rows.append(row)

            frame_idx += 1

    cap.release()
    return rows

def main():
    all_rows = []

    for ex in EXERCISES:
        ex_dir = VIDEOS_DIR / ex
        if not ex_dir.exists():
            print("Missing:", ex_dir)
            continue

        vids = sorted([p for p in ex_dir.iterdir() if p.suffix.lower() in [".mp4", ".mov", ".mkv", ".avi"]])
        print(f"\n== {ex} ({len(vids)} videos) ==")

        for vp in vids:
            print("  extracting:", vp.name)
            rows = extract_video(vp, ex)
            all_rows.extend(rows)

    if not all_rows:
        print("No rows extracted. Check paths / videos.")
        return

    df = pd.DataFrame(all_rows)

    out_csv = OUT_DIR / "all_exercises_frames.csv"
    df.to_csv(out_csv, index=False)
    print("\nSaved:", out_csv)
    print("Rows:", len(df), "Cols:", len(df.columns))

if __name__ == "__main__":
    main()
