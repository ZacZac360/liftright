import pandas as pd
import joblib
from pathlib import Path
import matplotlib.pyplot as plt

ROOT = Path(r"C:\xampp\htdocs\liftright\ml")

MODELS = {
    "Bicep Curl": ROOT / "models" / "bicep_curl_ocsvm.pkl",
    "Lateral Raise": ROOT / "models" / "lateral_raise_ocsvm.pkl",
    "Shoulder Press": ROOT / "models" / "shoulder_press_ocsvm.pkl",
}

DATASETS = {
    "Bicep Curl": ROOT / "datasets" / "reps" / "bicep_curl_reps.csv",
    "Lateral Raise": ROOT / "datasets" / "reps" / "lateral_raise_reps.csv",
    "Shoulder Press": ROOT / "datasets" / "reps" / "shoulder_press_reps.csv",
}

fig, axes = plt.subplots(1, 3, figsize=(15, 4.8), sharey=True)

for ax, name in zip(axes, MODELS.keys()):
    bundle = joblib.load(MODELS[name])
    df = pd.read_csv(DATASETS[name])

    feat_cols = bundle["features"]
    X = df[feat_cols].dropna().copy()
    Xs = bundle["scaler"].transform(X.values)
    scores = bundle["model"].decision_function(Xs).ravel()
    threshold = bundle["threshold"]

    ax.hist(scores, bins=10, edgecolor="black")
    ax.axvline(threshold, linestyle="--", linewidth=1.5)
    ax.set_title(name)
    ax.set_xlabel("Decision Score")
    ax.text(
        0.98, 0.95,
        f"n={len(scores)}\nthreshold={threshold:.4f}",
        transform=ax.transAxes,
        ha="right", va="top",
        fontsize=9,
        bbox=dict(boxstyle="round,pad=0.25", facecolor="white", alpha=0.8)
    )

axes[0].set_ylabel("Frequency")
fig.suptitle("Histogram of Decision Scores for Each Exercise Model", fontsize=14)
plt.tight_layout()
plt.savefig("decision_score_histograms_clean.png", dpi=300, bbox_inches="tight")
plt.show()