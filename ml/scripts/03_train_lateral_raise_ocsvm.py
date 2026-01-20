# ml/scripts/03_train_lateral_raise_ocsvm.py
import pandas as pd
import numpy as np
import joblib
from pathlib import Path
from sklearn.preprocessing import RobustScaler
from sklearn.svm import OneClassSVM

PROJECT_ROOT = Path(__file__).resolve().parents[1]
IN_CSV  = PROJECT_ROOT / "datasets" / "reps" / "lateral_raise_reps.csv"
OUT_PKL = PROJECT_ROOT / "models" / "lateral_raise_ocsvm.pkl"
OUT_PKL.parent.mkdir(parents=True, exist_ok=True)

# Match your "real thing" philosophy (lenient, robust, clipped)
MAX_REP_DURATION = 10.0

FEATURES = [
    "wrist_rel_range",
    "duration",
    "trunk_absmax",
    "elbow_min",
]

# Lenient like bicep/press
NU = 0.06
THRESH_PCT = 10

def main():
    df = pd.read_csv(IN_CSV)
    print("Initial reps:", len(df))

    df = df[df["duration"] <= MAX_REP_DURATION].copy()
    df = df.dropna(subset=FEATURES)

    # Clip extremes so one rep doesn't dominate
    df["trunk_absmax"] = df["trunk_absmax"].clip(upper=0.45)
    df["wrist_rel_range"] = df["wrist_rel_range"].clip(upper=1.20)
    # elbow_min: lower means more curl/upright-row cheat; clip absurd lows
    df["elbow_min"] = df["elbow_min"].clip(lower=60.0, upper=180.0)

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
        "exercise": "lateral_raise",
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
