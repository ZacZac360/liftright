# ml/scripts/03_train_shoulder_press_ocsvm.py
import pandas as pd
import numpy as np
import joblib
from pathlib import Path
from sklearn.preprocessing import RobustScaler
from sklearn.svm import OneClassSVM

PROJECT_ROOT = Path(__file__).resolve().parents[1]
IN_CSV  = PROJECT_ROOT / "datasets" / "reps" / "shoulder_press_reps.csv"
OUT_PKL = PROJECT_ROOT / "models" / "shoulder_press_ocsvm.pkl"
OUT_PKL.parent.mkdir(parents=True, exist_ok=True)

# Keep lenient like bicep curl
MAX_REP_DURATION = 10.0

# --- Feature contract (must match 04_live_shoulder_press.py) ---
FEATURES = [
    "wrist_rel_range",
    "duration",
    "trunk_absmax",
    "wrist_drift_absmax"
]

# OCSVM tuning: permissive / small dataset
NU = 0.06
THRESH_PCT = 10

def main():
    df = pd.read_csv(IN_CSV)
    print("Initial reps:", len(df))

    df = df[df["duration"] <= MAX_REP_DURATION].copy()
    df = df.dropna(subset=FEATURES)

    # Clip extremes so one weird rep doesn't dominate the kernel space
    df["trunk_absmax"] = df["trunk_absmax"].clip(upper=0.55)
    df["wrist_drift_absmax"] = df["wrist_drift_absmax"].clip(upper=0.60)
    df["max_wrist_rel_y"] = df["max_wrist_rel_y"].clip(upper=1.20)

    print("Reps after duration + clipping:", len(df))
    if len(df) < 12:
        raise RuntimeError("Not enough reps to train a stable model (need >= 12).")

    X = df[FEATURES].values
    scaler = RobustScaler()
    Xs = scaler.fit_transform(X)

    model = OneClassSVM(kernel="rbf", gamma="scale", nu=NU)
    model.fit(Xs)

    scores = model.decision_function(Xs).ravel()
    threshold = float(np.percentile(scores, THRESH_PCT))

    bundle = {
        "exercise": "shoulder_press",
        "features": FEATURES,
        "max_rep_duration": MAX_REP_DURATION,
        "nu": NU,
        "threshold_pct": THRESH_PCT,
        "threshold": threshold,
        "scaler": scaler,
        "model": model,
    }

    joblib.dump(bundle, OUT_PKL)

    print("\nModel trained successfully.")
    print("Score stats: min/mean/max =", float(scores.min()), float(scores.mean()), float(scores.max()))
    print("threshold:", threshold)
    print("\nSaved model ->", OUT_PKL)

if __name__ == "__main__":
    main()
