import pandas as pd
import numpy as np
from pathlib import Path
from collections import deque

# ---------------- CONFIG ----------------
PROJECT_ROOT = Path(__file__).resolve().parents[1]
IN_CSV  = PROJECT_ROOT / "datasets" / "frames" / "all_exercises_frames.csv"
OUT_CSV = PROJECT_ROOT / "datasets" / "reps" / "bicep_curl_reps.csv"
OUT_CSV.parent.mkdir(parents=True, exist_ok=True)

# Rep detection thresholds (front-facing bicep curl)
TOP_THR = 75
BOT_THR = 155
SMOOTH_N = 7
MIN_REP_FRAMES = 6

ARMS = ["R", "L"]

# ---------------- HELPERS ----------------
def detect_reps_one_arm(df_vid, arm: str):
    buf = deque(maxlen=SMOOTH_N)
    state = "down"
    rep_id = 0
    current = None
    reps = []

    angle_col = "R_elbow_angle" if arm == "R" else "L_elbow_angle"

    for _, r in df_vid.iterrows():
        angle = float(r[angle_col])
        buf.append(angle)
        angle_s = float(np.median(buf))

        if current is None:
            current = {"angles": [], "times": [], "trunk": [], "conf": []}

        current["angles"].append(angle_s)
        current["times"].append(float(r["time_sec"]))
        current["trunk"].append(float(r["trunk_offset_norm"]))
        current["conf"].append(float(r["conf_mean"]))

        if state == "down":
            if angle_s <= TOP_THR:
                state = "up"
        else:
            if angle_s >= BOT_THR:
                if len(current["angles"]) >= MIN_REP_FRAMES:
                    rep_id += 1
                    angles = np.array(current["angles"], dtype=np.float32)
                    times  = np.array(current["times"], dtype=np.float32)
                    trunk  = np.array(current["trunk"], dtype=np.float32)
                    conf   = np.array(current["conf"], dtype=np.float32)

                    reps.append({
                        "arm": arm,
                        "rep_number": rep_id,
                        "min_angle": float(angles.min()),
                        "max_angle": float(angles.max()),
                        "rom": float(angles.max() - angles.min()),
                        "duration": float(times[-1] - times[0]),
                        "trunk_mean": float(trunk.mean()),
                        "trunk_absmax": float(np.max(np.abs(trunk))),
                        "conf_mean": float(conf.mean()),
                        "n_frames": int(len(angles)),
                    })

                current = None
                state = "down"

    return reps

def pick_best_arm(repR, repL):
    """
    Choose which arm to keep for a given rep index.
    MVP rule: higher conf_mean wins; tie-breaker by larger ROM.
    """
    if repR is None and repL is None:
        return None
    if repR is None:
        return repL
    if repL is None:
        return repR

    # primary: confidence
    if repR["conf_mean"] > repL["conf_mean"] + 1e-6:
        return repR
    if repL["conf_mean"] > repR["conf_mean"] + 1e-6:
        return repL

    # tie-breaker: ROM (prefer cleaner full movement)
    if repR["rom"] >= repL["rom"]:
        return repR
    return repL

# ---------------- MAIN ----------------
def main():
    df = pd.read_csv(IN_CSV)
    df = df[df["exercise"] == "bicep_curl"].copy()
    df = df.sort_values(["video_id", "frame_idx"])

    out_rows = []

    for vid, df_vid in df.groupby("video_id"):
        print("Processing video:", vid)

        reps_by_arm = {arm: detect_reps_one_arm(df_vid, arm) for arm in ARMS}
        rlist = reps_by_arm["R"]
        llist = reps_by_arm["L"]

        # align rep indices (rep 1 with rep 1, etc.)
        max_reps = max(len(rlist), len(llist))

        for i in range(max_reps):
            repR = rlist[i] if i < len(rlist) else None
            repL = llist[i] if i < len(llist) else None
            best = pick_best_arm(repR, repL)
            if best is None:
                continue

            best["video_id"] = vid
            best["participant_id"] = df_vid["participant_id"].iloc[0]
            out_rows.append(best)

    if not out_rows:
        print("No reps detected.")
        return

    rep_df = pd.DataFrame(out_rows)
    rep_df.to_csv(OUT_CSV, index=False)

    print("\nSaved:", OUT_CSV)
    print("Total reps (best-arm):", len(rep_df))
    print(rep_df.head())

if __name__ == "__main__":
    main()
