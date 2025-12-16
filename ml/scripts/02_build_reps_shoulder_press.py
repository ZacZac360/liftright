import pandas as pd
import numpy as np
from pathlib import Path
from collections import deque

# ---------------- CONFIG ----------------
PROJECT_ROOT = Path(__file__).resolve().parents[1]
IN_CSV  = PROJECT_ROOT / "datasets" / "frames" / "all_exercises_frames.csv"
OUT_CSV = PROJECT_ROOT / "datasets" / "reps" / "shoulder_press_reps.csv"
OUT_CSV.parent.mkdir(parents=True, exist_ok=True)

# Shoulder press rep thresholds (front-facing, using wrist_rel_y)
# wrist_rel_y = (shoulder_y - wrist_y) / shoulder_width
# higher = wrist higher above shoulder line
UP_THR   = 0.35   # pressed up
DOWN_THR = 0.15   # back down

SMOOTH_N = 7
MIN_REP_FRAMES = 6
MAX_REP_TIME = 6.0      # prevent stuck 500-frame reps

# Adaptive threshold offsets (relative to baseline rack position)
DOWN_OFFSET = 0.02      # "back to rack" threshold = baseline + this
UP_OFFSET   = 0.35      # "pressed overhead" threshold = down_thr + this

BASELINE_FRAMES = 30    # ~1 sec at ~30fps


def detect_reps_one_arm(df_vid, arm: str):
    from collections import deque
    buf = deque(maxlen=SMOOTH_N)

    wrist_col = "R_wrist_rel_y" if arm == "R" else "L_wrist_rel_y"

    # ----- compute baseline from first second -----
    first = df_vid.head(BASELINE_FRAMES)
    base_vals = first[wrist_col].astype(float).values
    baseline = float(np.median(base_vals)) if len(base_vals) else 0.10

    down_thr = max(0.05, baseline + DOWN_OFFSET)
    up_thr   = down_thr + UP_OFFSET

    # state machine: we only count a rep after seeing "up" then returning "down"
    state = "down"
    rep_id = 0
    current = None
    reps = []

    for _, r in df_vid.iterrows():
        y = float(r[wrist_col])
        buf.append(y)
        y_s = float(np.median(buf))

        if current is None:
            current = {"vals": [], "times": [], "trunk": [], "conf": []}

        current["vals"].append(y_s)
        current["times"].append(float(r["time_sec"]))
        current["trunk"].append(float(r["trunk_offset_norm"]))
        current["conf"].append(float(r["conf_mean"]))

        # Safety reset: avoid giant reps if we get stuck
        if (current["times"][-1] - current["times"][0]) > MAX_REP_TIME:
            current = None
            state = "down"
            buf.clear()
            continue

        if state == "down":
            if y_s >= up_thr:
                state = "up"
        else:  # state == "up"
            if y_s <= down_thr:
                if len(current["vals"]) >= MIN_REP_FRAMES:
                    rep_id += 1
                    vals  = np.array(current["vals"], dtype=np.float32)
                    times = np.array(current["times"], dtype=np.float32)
                    trunk = np.array(current["trunk"], dtype=np.float32)
                    conf  = np.array(current["conf"], dtype=np.float32)

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
                    })

                current = None
                state = "down"

    return reps

def pick_best_arm(repR, repL):
    # same idea as bicep curl: higher confidence wins, tie → bigger range
    if repR is None and repL is None:
        return None
    if repR is None:
        return repL
    if repL is None:
        return repR

    if repR["conf_mean"] > repL["conf_mean"] + 1e-6:
        return repR
    if repL["conf_mean"] > repR["conf_mean"] + 1e-6:
        return repL

    if repR["wrist_rel_range"] >= repL["wrist_rel_range"]:
        return repR
    return repL

def main():
    df = pd.read_csv(IN_CSV)

    df = df[df["exercise"] == "shoulder_press"].copy()
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
        print("No reps detected. If you get this, we just tune UP_THR/DOWN_THR.")
        return

    rep_df = pd.DataFrame(out_rows)
    rep_df.to_csv(OUT_CSV, index=False)

    print("\nSaved:", OUT_CSV)
    print("Total reps (best-arm):", len(rep_df))
    print(rep_df.head())

if __name__ == "__main__":
    main()
