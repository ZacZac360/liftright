import pandas as pd
import numpy as np
import joblib
from pathlib import Path
from sklearn.preprocessing import StandardScaler
from sklearn.svm import OneClassSVM

PROJECT_ROOT = Path(__file__).resolve().parents[1]
IN_CSV  = PROJECT_ROOT / "datasets" / "reps" / "lateral_raise_reps.csv"
OUT_PKL = PROJECT_ROOT / "models" / "lateral_raise_ocsvm.pkl"
OUT_PKL.parent.mkdir(parents=True, exist_ok=True)

MAX_REP_DURATION = 8.0
NU = 0.10
THRESH_PCT = 1

FEATURES = [
    "wrist_rel_range",
    "duration",
    "trunk_absmax",
    "elbow_min",
]

def main():
    df = pd.read_csv(IN_CSV)
    print("Initial reps:", len(df))

    df = df[df["duration"] <= MAX_REP_DURATION].copy()
    df = df.dropna(subset=FEATURES)

    # clip trunk sway outliers (same reason as your bicep/press scripts)
    df["trunk_absmax"] = df["trunk_absmax"].clip(upper=0.3)

    print("Reps after duration + clipping:", len(df))
    if len(df) < 8:
        raise RuntimeError("Not enough reps to train a stable lateral raise model.")

    X = df[FEATURES].values
    scaler = StandardScaler()
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
    print("Score stats:")
    print(" min :", float(scores.min()))
    print(" mean:", float(scores.mean()))
    print(" max :", float(scores.max()))
    print(" threshold:", threshold)
    print("\nSaved model ->", OUT_PKL)

if __name__ == "__main__":
    main()
