import pandas as pd
import numpy as np
import joblib
from pathlib import Path
from sklearn.preprocessing import StandardScaler
from sklearn.svm import OneClassSVM

# ---------------- CONFIG ----------------
PROJECT_ROOT = Path(__file__).resolve().parents[1]
IN_CSV  = PROJECT_ROOT / "datasets" / "reps" / "bicep_curl_reps.csv"
OUT_PKL = PROJECT_ROOT / "models" / "bicep_curl_ocsvm.pkl"
OUT_PKL.parent.mkdir(parents=True, exist_ok=True)

# Drop abnormal long reps (warm-up / pauses)
MAX_REP_DURATION = 8.0  # seconds

# Features used by the model
FEATURES = [
    "rom",
    "duration",
    "trunk_absmax",
    "min_angle",
]

# OCSVM parameters (tuned for small, clean dataset)
NU = 0.10            # expected fraction of anomalies
THRESH_PCT = 1       # stricter threshold percentile

# ---------------- MAIN ----------------
def main():
    df = pd.read_csv(IN_CSV)

    print("Initial reps:", len(df))

    # Basic filtering
    df = df[df["duration"] <= MAX_REP_DURATION].copy()
    df = df.dropna(subset=FEATURES)

    # ---- IMPORTANT FIX ----
    # Clip extreme trunk sway so it doesn't dominate the kernel space
    df["trunk_absmax"] = df["trunk_absmax"].clip(upper=0.3)

    print("Reps after duration + clipping:", len(df))

    if len(df) < 10:
        raise RuntimeError("Not enough reps to train a stable model.")

    X = df[FEATURES].values

    scaler = StandardScaler()
    Xs = scaler.fit_transform(X)

    model = OneClassSVM(
        kernel="rbf",
        gamma="scale",
        nu=NU
    )
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
    print("Score stats:")
    print(" min :", float(scores.min()))
    print(" mean:", float(scores.mean()))
    print(" max :", float(scores.max()))
    print(" threshold:", threshold)
    print("\nSaved model ->", OUT_PKL)

if __name__ == "__main__":
    main()
