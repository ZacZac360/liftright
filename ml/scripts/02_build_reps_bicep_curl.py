# ml/scripts/02_build_reps_bicep_curl.py
import pandas as pd
import numpy as np
from pathlib import Path
from collections import deque

PROJECT_ROOT = Path(__file__).resolve().parents[1]
IN_CSV  = PROJECT_ROOT / "datasets" / "frames" / "all_exercises_frames.csv"
OUT_CSV = PROJECT_ROOT / "datasets" / "reps" / "bicep_curl_reps.csv"
OUT_CSV.parent.mkdir(parents=True, exist_ok=True)

TOP_THR = 75
BOT_THR = 155
SMOOTH_N = 7

# "Real thing" settings: keep quality, but don't over-filter style variance
MIN_REP_FRAMES = 8
MAX_REP_TIME = 8.0
MIN_CONF = 0.50   # was 0.65 in v2; too strict for real-world capture

ARMS = ["R", "L"]

def safe_div(a, b, eps=1e-6):
    return float(a / (b + eps))

def detect_reps_one_arm(df_vid, arm: str):
    angle_col = "R_elbow_angle" if arm == "R" else "L_elbow_angle"
    sh_x = "R_sh_x" if arm == "R" else "L_sh_x"
    el_x = "R_el_x" if arm == "R" else "L_el_x"

    buf = deque(maxlen=SMOOTH_N)
    state = "down"
    rep_id = 0
    reps = []

    current = None

    for _, r in df_vid.iterrows():
        if float(r.get("conf_mean", 0.0)) < MIN_CONF:
            continue

        ang = float(r[angle_col])
        buf.append(ang)
        ang_s = float(np.median(buf))

        shoulder_w = float(r.get("shoulder_width_px", 2.0))
        if shoulder_w < 2:
            shoulder_w = 2

        drift = abs(float(r[el_x]) - float(r[sh_x]))
        drift_norm = safe_div(drift, shoulder_w)

        # Start only after you actually initiate the curl (hit "up")
        if state == "down":
            if ang_s <= TOP_THR:
                state = "up"
                current = {"angles": [], "times": [], "trunk": [], "drift": []}

        if state == "up" and current is not None:
            current["angles"].append(ang_s)
            current["times"].append(float(r["time_sec"]))
            current["trunk"].append(float(r["trunk_offset_norm"]))
            current["drift"].append(float(drift_norm))

            # Safety reset: avoid giant stuck reps
            if (current["times"][-1] - current["times"][0]) > MAX_REP_TIME:
                state = "down"
                current = None
                buf.clear()
                continue

            # End rep on return to bottom
            if ang_s >= BOT_THR:
                if len(current["angles"]) >= MIN_REP_FRAMES:
                    rep_id += 1
                    angles = np.array(current["angles"], dtype=np.float32)
                    times  = np.array(current["times"], dtype=np.float32)
                    trunk  = np.array(current["trunk"], dtype=np.float32)
                    driftv = np.array(current["drift"], dtype=np.float32)

                    reps.append({
                        "arm": arm,
                        "rep_number": rep_id,
                        "min_angle": float(np.min(angles)),
                        "max_angle": float(np.max(angles)),
                        "rom": float(np.max(angles) - np.min(angles)),
                        "duration": float(times[-1] - times[0]),
                        "trunk_absmax": float(np.max(np.abs(trunk))),
                        "elbow_drift_absmax": float(np.max(driftv)),
                        "elbow_drift_mean": float(np.mean(driftv)),
                        "n_frames": int(len(angles)),
                    })

                state = "down"
                current = None

    return reps

def pick_best_arm(repR, repL):
    # Prefer more confident / stable reps. If your frames CSV has conf per-arm, use it.
    # Here we do a simple pick: bigger ROM wins; tie-breaker by lower drift.
    if repR is None and repL is None:
        return None
    if repR is None:
        return repL
    if repL is None:
        return repR

    if repR["rom"] > repL["rom"] + 2.0:
        return repR
    if repL["rom"] > repR["rom"] + 2.0:
        return repL

    return repR if repR["elbow_drift_absmax"] <= repL["elbow_drift_absmax"] else repL

def main():
    df = pd.read_csv(IN_CSV)
    df = df[df["exercise"] == "bicep_curl"].copy()
    df = df.sort_values(["video_id", "frame_idx"])

    out_rows = []
    for vid, df_vid in df.groupby("video_id"):
        repsR = detect_reps_one_arm(df_vid, "R")
        repsL = detect_reps_one_arm(df_vid, "L")
        max_reps = max(len(repsR), len(repsL))

        for i in range(max_reps):
            repR = repsR[i] if i < len(repsR) else None
            repL = repsL[i] if i < len(repsL) else None
            best = pick_best_arm(repR, repL)
            if best is None:
                continue
            best["video_id"] = vid
            best["participant_id"] = df_vid["participant_id"].iloc[0]
            out_rows.append(best)

    rep_df = pd.DataFrame(out_rows)
    rep_df.to_csv(OUT_CSV, index=False)
    print("Saved:", OUT_CSV, "| reps:", len(rep_df))
    print(rep_df.head())

if __name__ == "__main__":
    main()
