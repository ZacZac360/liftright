import pandas as pd
import numpy as np
from pathlib import Path
from collections import deque

# ---------------- CONFIG ----------------
PROJECT_ROOT = Path(__file__).resolve().parents[1]
IN_CSV  = PROJECT_ROOT / "datasets" / "frames" / "all_exercises_frames.csv"
OUT_CSV = PROJECT_ROOT / "datasets" / "reps" / "lateral_raise_reps.csv"
OUT_CSV.parent.mkdir(parents=True, exist_ok=True)

SMOOTH_N = 7
MIN_REP_FRAMES = 6
MAX_REP_TIME = 6.0

# Baseline calibration: first ~1 sec
BASELINE_FRAMES = 30

# Lateral raise: wrists usually end up ~near shoulder height (wrist_rel_y around 0 to 0.3-ish)
# We'll do adaptive thresholds relative to baseline.
DOWN_OFFSET = 0.02     # down_thr = baseline + this
UP_OFFSET   = 0.20     # up_thr   = down_thr + this  (tune 0.18-0.30 if needed)

ARMS = ["R", "L"]

def detect_reps_one_arm(df_vid, arm: str):
    buf = deque(maxlen=SMOOTH_N)
    wrist_col = "R_wrist_rel_y" if arm == "R" else "L_wrist_rel_y"

    # ----- baseline from first second -----
    first = df_vid.head(BASELINE_FRAMES)
    base_vals = first[wrist_col].astype(float).values
    base_vals = base_vals[np.isfinite(base_vals)]
    baseline = float(np.median(base_vals)) if len(base_vals) else 0.05

    down_thr = max(0.02, baseline + DOWN_OFFSET)
    up_thr   = down_thr + UP_OFFSET

    state = "down"
    rep_id = 0
    current = None
    reps = []

    for _, r in df_vid.iterrows():
        y = float(r[wrist_col])
        if not np.isfinite(y):
            continue

        buf.append(y)
        y_s = float(np.median(buf))

        if current is None:
            current = {"vals": [], "times": [], "trunk": [], "conf": [], "elbow": []}

        current["vals"].append(y_s)
        current["times"].append(float(r["time_sec"]))
        current["trunk"].append(float(r["trunk_offset_norm"]))
        current["conf"].append(float(r["conf_mean"]))

        # elbow angle feature (helps catch “turning into upright row” / too much bend)
        elbow_col = "R_elbow_angle" if arm == "R" else "L_elbow_angle"
        current["elbow"].append(float(r[elbow_col]))

        # Safety reset if stuck
        if (current["times"][-1] - current["times"][0]) > MAX_REP_TIME:
            current = None
            state = "down"
            buf.clear()
            continue

        if state == "down":
            if y_s >= up_thr:
                state = "up"
        else:  # up
            if y_s <= down_thr:
                if len(current["vals"]) >= MIN_REP_FRAMES:
                    rep_id += 1
                    vals  = np.array(current["vals"], dtype=np.float32)
                    times = np.array(current["times"], dtype=np.float32)
                    trunk = np.array(current["trunk"], dtype=np.float32)
                    conf  = np.array(current["conf"], dtype=np.float32)
                    elbow = np.array(current["elbow"], dtype=np.float32)

                    reps.append({
                        "arm": arm,
                        "rep_number": rep_id,
                        "baseline": baseline,
                        "down_thr": down_thr,
                        "up_thr": up_thr,

                        "min_wrist_rel_y": float(vals.min()),
                        "max_wrist_rel_y": float(vals.max()),
                        "wrist_rel_range": float(vals.max() - vals.min()),
                        "duration": float(times[-1] - times[0]),

                        "trunk_mean": float(trunk.mean()),
                        "trunk_absmax": float(np.max(np.abs(trunk))),
                        "conf_mean": float(conf.mean()),
                        "n_frames": int(len(vals)),

                        "elbow_mean": float(np.mean(elbow)),
                        "elbow_min": float(np.min(elbow)),
                    })

                current = None
                state = "down"

    return reps

def pick_best_arm(repR, repL):
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

    # tie: bigger movement
    if repR["wrist_rel_range"] >= repL["wrist_rel_range"]:
        return repR
    return repL

def main():
    df = pd.read_csv(IN_CSV)
    df = df[df["exercise"] == "lateral_raise"].copy()
    df = df.sort_values(["video_id", "frame_idx"])

    out_rows = []

    for vid, df_vid in df.groupby("video_id"):
        print("Processing video:", vid)

        rlist = detect_reps_one_arm(df_vid, "R")
        llist = detect_reps_one_arm(df_vid, "L")
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
        print("No reps detected. Try raising UP_OFFSET (e.g., 0.25) or lowering DOWN_OFFSET.")
        return

    rep_df = pd.DataFrame(out_rows)
    rep_df.to_csv(OUT_CSV, index=False)

    print("\nSaved:", OUT_CSV)
    print("Total reps (best-arm):", len(rep_df))
    print(rep_df.head())

if __name__ == "__main__":
    main()
