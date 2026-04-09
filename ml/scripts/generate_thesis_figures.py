from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt

ROOT = Path(r"C:\xampp\htdocs\liftright")
ML_DIR = ROOT / "ml"
REPS_DIR = ML_DIR / "datasets" / "reps"
OUT_DIR = ML_DIR / "thesis_figures"
OUT_DIR.mkdir(parents=True, exist_ok=True)

SUMMARY_CSV = ML_DIR / "ocsvm_model_summary.csv"

EXERCISE_FILES = {
    "Bicep Curl": REPS_DIR / "bicep_curl_reps.csv",
    "Lateral Raise": REPS_DIR / "lateral_raise_reps.csv",
    "Shoulder Press": REPS_DIR / "shoulder_press_reps.csv",
}


# ================================
# HELPERS
# ================================
def find_col(df, names):
    for n in names:
        for col in df.columns:
            if n.lower() in col.lower():
                return col
    return None


def save_bar(x, y, title, ylabel, filename, percent=False):
    plt.figure(figsize=(8, 5))
    plt.bar(x, y)
    plt.title(title)
    plt.ylabel(ylabel)

    for i, v in enumerate(y):
        label = f"{v:.2f}%" if percent else f"{v:.3f}"
        plt.text(i, v + (max(y) * 0.02 if max(y) > 0 else 0.01), label, ha="center")

    if percent:
        plt.ylim(0, 100)

    plt.tight_layout()
    plt.savefig(OUT_DIR / filename, dpi=300)
    plt.close()


# ================================
# LOAD DATA
# ================================
data = {}
for name, path in EXERCISE_FILES.items():
    df = pd.read_csv(path)
    data[name] = df
    print(f"\n{name} columns:")
    print(df.columns.tolist())


# ================================
# FEATURE CHARTS
# ================================
duration_vals = {}
trunk_vals = {}
feature_vals = {}

for name, df in data.items():
    duration_col = find_col(df, ["duration"])
    trunk_col = find_col(df, ["trunk"])
    rom_col = find_col(df, ["rom"])
    wrist_col = find_col(df, ["wrist_rel_range", "wrist_range"])

    if duration_col:
        duration_vals[name] = pd.to_numeric(df[duration_col], errors="coerce").mean()

    if trunk_col:
        trunk_vals[name] = pd.to_numeric(df[trunk_col], errors="coerce").mean()

    if name == "Bicep Curl" and rom_col:
        feature_vals[name] = pd.to_numeric(df[rom_col], errors="coerce").mean()
    elif wrist_col:
        feature_vals[name] = pd.to_numeric(df[wrist_col], errors="coerce").mean()


# SAVE FEATURE CHARTS
save_bar(list(duration_vals.keys()), list(duration_vals.values()),
         "Mean Repetition Duration Across Exercises",
         "Duration (s)",
         "mean_duration.png")

save_bar(list(trunk_vals.keys()), list(trunk_vals.values()),
         "Mean Trunk Offset Across Exercises",
         "Trunk Offset",
         "mean_trunk_offset.png")

save_bar(list(feature_vals.keys()), list(feature_vals.values()),
         "Comparison of Key Movement Feature Values Across Exercises",
         "Feature Value",
         "key_feature.png")


# ================================
# ACCEPTANCE RATE (FROM SUMMARY CSV)
# ================================
if SUMMARY_CSV.exists():
    df = pd.read_csv(SUMMARY_CSV)
    print("\nSUMMARY CSV COLUMNS:")
    print(df.columns.tolist())

    exercise_col = find_col(df, ["exercise"])
    rate_col = find_col(df, ["accept", "rate", "accuracy"])

    if exercise_col and rate_col:
        exercises = df[exercise_col].tolist()
        rates = pd.to_numeric(df[rate_col], errors="coerce").tolist()

        # convert to percent if needed
        if max(rates) <= 1:
            rates = [r * 100 for r in rates]

        save_bar(exercises, rates,
                 "Acceptance Rates Across Exercise Models",
                 "Acceptance Rate (%)",
                 "acceptance_rates.png",
                 percent=True)

    else:
        print("\n⚠️ Could not auto-detect acceptance rate. Using fallback values.")

        exercises = ["Bicep Curl", "Lateral Raise", "Shoulder Press"]
        rates = [76.47, 81.63, 70.83]

        save_bar(exercises, rates,
                 "Acceptance Rates Across Exercise Models",
                 "Acceptance Rate (%)",
                 "acceptance_rates.png",
                 percent=True)

else:
    print("\n⚠️ No summary CSV found. Using fallback acceptance values.")

    exercises = ["Bicep Curl", "Lateral Raise", "Shoulder Press"]
    rates = [76.47, 81.63, 70.83]

    save_bar(exercises, rates,
             "Acceptance Rates Across Exercise Models",
             "Acceptance Rate (%)",
             "acceptance_rates.png",
             percent=True)


# ================================
# HISTOGRAM (ONLY IF EXISTS)
# ================================
for name, df in data.items():
    score_col = find_col(df, ["score", "anomaly"])

    if score_col:
        plt.figure()
        plt.hist(pd.to_numeric(df[score_col], errors="coerce").dropna(), bins=10)
        plt.title(f"Decision Score Distribution - {name}")
        plt.xlabel("Score")
        plt.ylabel("Frequency")
        plt.tight_layout()
        plt.savefig(OUT_DIR / f"hist_{name}.png", dpi=300)
        plt.close()
    else:
        print(f"Skipping histogram for {name} (no score column)")


print("\nDONE. Check:")
print(OUT_DIR)