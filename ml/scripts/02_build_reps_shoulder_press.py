# ml/scripts/02_build_reps_shoulder_press.py
import pandas as pd
import numpy as np
from pathlib import Path
from collections import deque

PROJECT_ROOT = Path(__file__).resolve().parents[1]
IN_CSV  = PROJECT_ROOT / "datasets" / "frames" / "all_exercises_frames.csv"
OUT_CSV = PROJECT_ROOT / "datasets" / "reps" / "shoulder_press_reps.csv"
OUT_CSV.parent.mkdir(parents=True, exist_ok=True)

SMOOTH_N = 7
MIN_REP_FRAMES = 6
MAX_REP_TIME = 8.0   # match bicep-curl "real thing" lenience

MIN_CONF = 0.50

# Adaptive threshold offsets (relative to baseline rack position)
DOWN_OFFSET = 0.02
UP_OFFSET   = 0.35

# --- Robust baseline settings ---
# Use more early frames so we include the "get into rack" phase.
# Filter out arms-down negatives, and pick a rack-ish percentile.
BASELINE_FRAMES = 400   # ~13 sec at ~30 fps
BASELINE_MIN_Y  = 0.10  # ignore arms-down / near-zero
BASELINE_PCT    = 25    # rack-ish percentile (tends to land near "down/rack" cluster)

ARMS = ["R", "L"]

def safe_div(a, b, eps=1e-6):
    return float(a / (b + eps))

def compute_baseline(df_vid, wrist_col):
    """
    Baseline intended to represent "rack/down" position, not arms-at-sides.
    Strategy:
      - take first BASELINE_FRAMES frames
      - keep confident frames only
      - ignore near-zero/negative wrist_rel_y (often arms-down)
      - use a low-ish percentile (BASELINE_PCT) to get rack-ish height
    """
    first = df_vid.head(BASELINE_FRAMES).copy()
    first = first[first["conf_mean"].astype(float) >= MIN_CONF]

    s = first[wrist_col].astype(float).values
    s = s[np.isfinite(s)]
    s = s[s > BASELINE_MIN_Y]

    if len(s) == 0:
        return 0.10

    return float(np.percentile(s, BASELINE_PCT))

def detect_reps_one_arm(df_vid, arm: str):
    buf = deque(maxlen=SMOOTH_N)

    wrist_col = "R_wrist_rel_y" if arm == "R" else "L_wrist_rel_y"
    sh_x = "R_sh_x" if arm == "R" else "L_sh_x"
    wr_x = "R_wr_x" if arm == "R" else "L_wr_x"

    baseline = compute_baseline(df_vid, wrist_col)
    down_thr = max(0.05, baseline + DOWN_OFFSET)
    up_thr   = down_thr + UP_OFFSET

    # state machine: count a rep after seeing UP then returning DOWN
    state = "down"
    rep_id = 0
    reps = []

    current = None  # only created once rep actually starts (on UP)

    for _, r in df_vid.iterrows():
        if float(r.get("conf_mean", 0.0)) < MIN_CONF:
            continue

        y = float(r[wrist_col])
        buf.append(y)
        y_s = float(np.median(buf))

        shoulder_w = float(r.get("shoulder_width_px", 2.0))
        if shoulder_w < 2:
            shoulder_w = 2
            
        el_x = "R_el_x" if arm == "R" else "L_el_x"
        drift = abs(float(r[wr_x]) - float(r[el_x]))
        drift_norm = safe_div(drift, shoulder_w)

        # -------------------------
        # Start rep ONLY when you actually go UP
        # -------------------------
        if state == "down":
            if y_s >= up_thr:
                state = "up"
                current = {"vals": [], "times": [], "trunk": [], "drift": []}
                # include this frame as the rep start
                current["vals"].append(y_s)
                current["times"].append(float(r["time_sec"]))
                current["trunk"].append(float(r["trunk_offset_norm"]))
                current["drift"].append(float(drift_norm))
            continue

        # -------------------------
        # Collect only while UP state is active
        # -------------------------
        if state == "up" and current is not None:
            current["vals"].append(y_s)
            current["times"].append(float(r["time_sec"]))
            current["trunk"].append(float(r["trunk_offset_norm"]))
            current["drift"].append(float(drift_norm))

            # Safety reset if stuck
            if (current["times"][-1] - current["times"][0]) > MAX_REP_TIME:
                current = None
                state = "down"
                buf.clear()
                continue

            # End rep when we come back DOWN
            if y_s <= down_thr:
                if len(current["vals"]) >= MIN_REP_FRAMES:
                    rep_id += 1
                    vals  = np.array(current["vals"], dtype=np.float32)
                    times = np.array(current["times"], dtype=np.float32)
                    trunk = np.array(current["trunk"], dtype=np.float32)
                    driftv = np.array(current["drift"], dtype=np.float32)

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

                        "trunk_absmax": float(np.max(np.abs(trunk))),
                        "wrist_drift_absmax": float(np.max(driftv)),
                        "wrist_drift_mean": float(np.mean(driftv)),

                        "n_frames": int(len(vals)),
                    })

                current = None
                state = "down"

    return reps

def pick_best_arm(repR, repL):
    # match bicep curl philosophy: bigger range wins; tie-break by lower drift
    if repR is None and repL is None:
        return None
    if repR is None:
        return repL
    if repL is None:
        return repR

    if repR["wrist_rel_range"] > repL["wrist_rel_range"] + 1e-6:
        return repR
    if repL["wrist_rel_range"] > repR["wrist_rel_range"] + 1e-6:
        return repL

    return repR if repR["wrist_drift_absmax"] <= repL["wrist_drift_absmax"] else repL

def main():
    df = pd.read_csv(IN_CSV)
    df = df[df["exercise"] == "shoulder_press"].copy()
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
        print("No reps detected. Likely thresholding (baseline/down/up) needs tuning.")
        return

    rep_df = pd.DataFrame(out_rows)
    rep_df.to_csv(OUT_CSV, index=False)

    print("Saved:", OUT_CSV, "| reps:", len(rep_df))
    print(rep_df.head())

if __name__ == "__main__":
    main()
