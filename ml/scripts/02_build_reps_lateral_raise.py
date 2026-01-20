# ml/scripts/02_build_reps_lateral_raise.py
import pandas as pd
import numpy as np
from pathlib import Path
from collections import deque

PROJECT_ROOT = Path(__file__).resolve().parents[1]
IN_CSV  = PROJECT_ROOT / "datasets" / "frames" / "all_exercises_frames.csv"
OUT_CSV = PROJECT_ROOT / "datasets" / "reps" / "lateral_raise_reps.csv"
OUT_CSV.parent.mkdir(parents=True, exist_ok=True)

SMOOTH_N = 7
MIN_REP_FRAMES = 6
MAX_REP_TIME = 8.0     # match bicep/press "real thing" lenience
MIN_CONF = 0.50

# Robust baseline settings (match shoulder press philosophy, adapted for lateral raise)
BASELINE_FRAMES = 400   # ~13 sec at ~30 fps
BASELINE_PCT    = 25    # down-position tends to be the lower cluster

# Adaptive threshold offsets relative to baseline (down)
DOWN_OFFSET = 0.02
UP_OFFSET   = 0.25      # lateral raise: tune 0.22–0.30 depending on your vids

ARMS = ["R", "L"]

def safe_div(a, b, eps=1e-6):
    return float(a / (b + eps))

def compute_baseline(df_vid, wrist_col):
    """
    Baseline intended to represent the DOWN position of lateral raise (arms down).
    We use early frames + confidence filter + percentile to avoid start noise.
    Note: wrist_rel_y can be negative if wrist is below shoulder (common for arms-down).
    """
    first = df_vid.head(BASELINE_FRAMES).copy()
    first = first[first["conf_mean"].astype(float) >= MIN_CONF]

    s = first[wrist_col].astype(float).values
    s = s[np.isfinite(s)]

    if len(s) == 0:
        return -0.10

    return float(np.percentile(s, BASELINE_PCT))

def detect_reps_one_arm(df_vid, arm: str):
    buf = deque(maxlen=SMOOTH_N)

    wrist_col = "R_wrist_rel_y" if arm == "R" else "L_wrist_rel_y"
    elbow_col = "R_elbow_angle" if arm == "R" else "L_elbow_angle"

    baseline = compute_baseline(df_vid, wrist_col)
    down_thr = baseline + DOWN_OFFSET
    up_thr   = down_thr + UP_OFFSET

    state = "down"
    rep_id = 0
    reps = []
    current = None  # created ONLY when rep starts (on UP)

    for _, r in df_vid.iterrows():
        if float(r.get("conf_mean", 0.0)) < MIN_CONF:
            continue

        y = float(r[wrist_col])
        if not np.isfinite(y):
            continue

        buf.append(y)
        y_s = float(np.median(buf))

        # -------------------------
        # Start rep ONLY when you actually go UP
        # -------------------------
        if state == "down":
            if y_s >= up_thr:
                state = "up"
                current = {"vals": [], "times": [], "trunk": [], "elbow": []}
                # include this frame as rep start
                current["vals"].append(y_s)
                current["times"].append(float(r["time_sec"]))
                current["trunk"].append(float(r["trunk_offset_norm"]))
                current["elbow"].append(float(r[elbow_col]))
            continue

        # -------------------------
        # Collect only while UP state is active
        # -------------------------
        if state == "up" and current is not None:
            current["vals"].append(y_s)
            current["times"].append(float(r["time_sec"]))
            current["trunk"].append(float(r["trunk_offset_norm"]))
            current["elbow"].append(float(r[elbow_col]))

            # Safety reset if stuck
            if (current["times"][-1] - current["times"][0]) > MAX_REP_TIME:
                current = None
                state = "down"
                buf.clear()
                continue

            # End rep on return DOWN
            if y_s <= down_thr:
                if len(current["vals"]) >= MIN_REP_FRAMES:
                    rep_id += 1
                    vals  = np.array(current["vals"], dtype=np.float32)
                    times = np.array(current["times"], dtype=np.float32)
                    trunk = np.array(current["trunk"], dtype=np.float32)
                    elbow = np.array(current["elbow"], dtype=np.float32)

                    reps.append({
                        "arm": arm,
                        "rep_number": rep_id,
                        "baseline": float(baseline),
                        "down_thr": float(down_thr),
                        "up_thr": float(up_thr),

                        "min_wrist_rel_y": float(vals.min()),
                        "max_wrist_rel_y": float(vals.max()),
                        "wrist_rel_range": float(vals.max() - vals.min()),
                        "duration": float(times[-1] - times[0]),

                        "trunk_absmax": float(np.max(np.abs(trunk))) if len(trunk) else 0.0,
                        "elbow_min": float(np.min(elbow)) if len(elbow) else 180.0,

                        "n_frames": int(len(vals)),
                    })

                current = None
                state = "down"

    return reps

def pick_best_arm(repR, repL):
    """
    Match bicep/press philosophy: prioritize movement quality.
    Primary: bigger wrist_rel_range (actual rep signal)
    Tie-breakers: less trunk swing, higher elbow_min (less upright-row cheating)
    """
    if repR is None and repL is None:
        return None
    if repR is None:
        return repL
    if repL is None:
        return repR

    # 1) bigger movement wins
    if repR["wrist_rel_range"] > repL["wrist_rel_range"] + 1e-6:
        return repR
    if repL["wrist_rel_range"] > repR["wrist_rel_range"] + 1e-6:
        return repL

    # 2) less trunk swing
    if repR["trunk_absmax"] < repL["trunk_absmax"] - 1e-6:
        return repR
    if repL["trunk_absmax"] < repR["trunk_absmax"] - 1e-6:
        return repL

    # 3) less elbow bend (higher elbow_min is better)
    if repR["elbow_min"] > repL["elbow_min"] + 1e-6:
        return repR
    if repL["elbow_min"] > repR["elbow_min"] + 1e-6:
        return repL

    return repR  # stable default

def main():
    df = pd.read_csv(IN_CSV)
    df = df[df["exercise"] == "lateral_raise"].copy()
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

    if not out_rows:
        print("No reps detected. Tune UP_OFFSET (0.22–0.30) or BASELINE_PCT.")
        return

    rep_df = pd.DataFrame(out_rows)
    rep_df.to_csv(OUT_CSV, index=False)
    print("Saved:", OUT_CSV, "| reps:", len(rep_df))
    print(rep_df.head())

if __name__ == "__main__":
    main()
