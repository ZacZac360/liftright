# ml/scripts/03_train_bicep_curl_ocsvm.py
import pandas as pd
import numpy as np
import joblib
from pathlib import Path
from sklearn.preprocessing import RobustScaler
from sklearn.svm import OneClassSVM

PROJECT_ROOT = Path(__file__).resolve().parents[1]
IN_CSV  = PROJECT_ROOT / "datasets" / "reps" / "bicep_curl_reps.csv"
OUT_PKL = PROJECT_ROOT / "models" / "bicep_curl_ocsvm.pkl"
OUT_PKL.parent.mkdir(parents=True, exist_ok=True)

MAX_REP_DURATION = 8.0

FEATURES = [
    "rom",
    "duration",
    "trunk_absmax",
    "elbow_drift_absmax",
]

# "Real thing" = lenient model
NU = 0.05
THRESH_PCT = 10

def main():
    df = pd.read_csv(IN_CSV)
    print("Initial reps:", len(df))

    df = df[df["duration"] <= MAX_REP_DURATION].copy()
    df = df.dropna(subset=FEATURES)

    # clip extremes so one weird rep doesn't dominate the kernel
    df["trunk_absmax"] = df["trunk_absmax"].clip(upper=0.45)
    df["elbow_drift_absmax"] = df["elbow_drift_absmax"].clip(upper=0.50)

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
        "exercise": "bicep_curl",
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
