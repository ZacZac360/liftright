import os
import re
import textwrap
import pandas as pd
import matplotlib.pyplot as plt

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

CSV_JOBS = [
    {
        "label": "Beginner",
        "csv": os.path.join(BASE_DIR, "LiftRight User Experience (Beginner) (Responses) - Form Responses 1.csv"),
        "output": os.path.join(BASE_DIR, "Beginner"),
    },
    {
        "label": "Trainer",
        "csv": os.path.join(BASE_DIR, "LiftRight User Experience (Trainer) (Responses) - Form Responses 1.csv"),
        "output": os.path.join(BASE_DIR, "Trainer"),
    },
    {
        "label": "Expert",
        "csv": os.path.join(BASE_DIR, "LiftRight User Experience (Industry Expert) (Responses) - Form Responses 1.csv"),
        "output": os.path.join(BASE_DIR, "Expert"),
    },
]

SKIP_COLUMNS = {"Timestamp"}

LIKERT_COLORS = ["#ef476f", "#f78c6b", "#ffd166", "#06d6a0", "#118ab2"]
PIE_COLORS = [
    "#5B8FF9", "#61DDAA", "#65789B", "#F6BD16", "#7262FD",
    "#78D3F8", "#9661BC", "#F6903D", "#008685", "#F08BB4"
]

plt.rcParams.update({
    "figure.dpi": 150,
    "axes.titlesize": 15,
    "axes.labelsize": 12,
    "xtick.labelsize": 11,
    "ytick.labelsize": 11,
    "legend.fontsize": 10,
    "font.family": "sans-serif"
})

def safe_filename(name: str) -> str:
    name = re.sub(r'[\\/*?:"<>|]', "", name)
    name = re.sub(r"\s+", "_", name.strip())
    return name[:80]

def wrap_title(title: str, width: int = 55) -> str:
    return "\n".join(textwrap.wrap(title, width=width))

def clean_series(series: pd.Series) -> pd.Series:
    return (
        series.dropna()
        .astype(str)
        .str.strip()
        .replace("", pd.NA)
        .dropna()
    )

def is_likert_column(values: pd.Series) -> bool:
    unique_vals = set(values.unique())
    return len(unique_vals) > 0 and unique_vals.issubset({"1", "2", "3", "4", "5"})

def is_open_text_column(values: pd.Series) -> bool:
    if len(values) == 0:
        return True
    unique_count = values.nunique()
    avg_len = values.str.len().mean()
    return unique_count >= max(8, len(values) * 0.6) and avg_len > 18

def make_likert_bar(column_name: str, values: pd.Series, output_path: str) -> None:
    order = ["1", "2", "3", "4", "5"]
    counts = values.value_counts().reindex(order, fill_value=0)
    total = counts.sum()
    percentages = (counts / total * 100).round(1)

    fig, ax = plt.subplots(figsize=(10, 6))
    bars = ax.bar(order, counts.values, color=LIKERT_COLORS, edgecolor="white", linewidth=1.2)

    ax.set_title(wrap_title(column_name), pad=14, fontweight="bold")
    ax.set_xlabel("Likert Scale")
    ax.set_ylabel("Responses")
    ax.set_axisbelow(True)
    ax.yaxis.grid(True, linestyle="--", alpha=0.25)
    ax.xaxis.grid(False)

    ymax = max(counts.values) if len(counts.values) else 1
    ax.set_ylim(0, ymax + max(1, ymax * 0.18))

    for bar, pct in zip(bars, percentages):
        h = bar.get_height()
        if h > 0:
            ax.text(
                bar.get_x() + bar.get_width() / 2,
                h + (ymax * 0.03),
                f"{pct:.1f}%",
                ha="center",
                va="bottom",
                fontsize=10,
                fontweight="bold"
            )

    legend_labels = [
        "1 - Strongly Disagree",
        "2 - Disagree",
        "3 - Neutral",
        "4 - Agree",
        "5 - Strongly Agree"
    ]
    ax.legend(bars, legend_labels, title="Response", loc="upper left", frameon=False)

    plt.tight_layout()
    plt.savefig(output_path, bbox_inches="tight")
    plt.close()

def make_pie_chart(column_name: str, values: pd.Series, output_path: str) -> None:
    counts = values.value_counts()
    total = counts.sum()
    if total == 0:
        return

    colors = PIE_COLORS[:len(counts)]

    fig, ax = plt.subplots(figsize=(10, 6.8))

    wedges, texts, autotexts = ax.pie(
        counts.values,
        labels=None,
        colors=colors,
        autopct=lambda pct: f"{pct:.1f}%" if pct > 0 else "",
        startangle=90,
        counterclock=False,
        wedgeprops={"edgecolor": "white", "linewidth": 1.2},
        textprops={"fontsize": 11}
    )

    ax.set_title(wrap_title(column_name), pad=16, fontweight="bold")

    ax.legend(
        wedges,
        counts.index,
        title="Responses",
        loc="center left",
        bbox_to_anchor=(1.02, 0.5),
        frameon=False
    )

    plt.tight_layout()
    plt.savefig(output_path, bbox_inches="tight")
    plt.close()

def process_csv(label: str, csv_file: str, output_dir: str) -> None:
    print(f"\n===== {label.upper()} =====")
    print(f"Reading CSV from: {csv_file}")
    print(f"Charts will be saved to: {output_dir}")

    if not os.path.exists(csv_file):
        print("  -> CSV not found. Skipping.")
        return

    os.makedirs(output_dir, exist_ok=True)

    df = pd.read_csv(csv_file)
    print(f"Loaded CSV with shape: {df.shape}")

    summary_rows = []
    question_index = 1

    for col in df.columns:
        print(f"\nProcessing column: {col}")

        if col in SKIP_COLUMNS:
            print("  -> Skipped (timestamp)")
            summary_rows.append((col, "SKIPPED", "Timestamp column"))
            continue

        values = clean_series(df[col])

        if len(values) == 0:
            print("  -> Skipped (empty)")
            summary_rows.append((col, "SKIPPED", "Empty column"))
            continue

        if is_likert_column(values):
            filename = f"Q{question_index:02d}_{safe_filename(col)}_bar.png"
            output_path = os.path.join(output_dir, filename)
            make_likert_bar(col, values, output_path)
            print(f"  -> Saved BAR chart: {output_path}")
            summary_rows.append((col, "BAR", filename))
            question_index += 1
            continue

        if is_open_text_column(values):
            print("  -> Skipped (open-ended text)")
            summary_rows.append((col, "SKIPPED", "Open-ended text"))
            continue

        unique_count = values.nunique()
        if unique_count <= 8:
            filename = f"Q{question_index:02d}_{safe_filename(col)}_pie.png"
            output_path = os.path.join(output_dir, filename)
            make_pie_chart(col, values, output_path)
            print(f"  -> Saved PIE chart: {output_path}")
            summary_rows.append((col, "PIE", filename))
            question_index += 1
            continue

        print("  -> Skipped (too many unique values / unclear type)")
        summary_rows.append((col, "SKIPPED", "Too many unique values / unclear type"))

    summary_df = pd.DataFrame(summary_rows, columns=["Column", "Action", "Output / Reason"])
    summary_path = os.path.join(output_dir, "chart_summary.csv")
    summary_df.to_csv(summary_path, index=False)

    print("\nDone.")
    print(f"Summary saved to: {summary_path}")
    print(summary_df.to_string(index=False))

def main():
    print("Script started...")
    for job in CSV_JOBS:
        process_csv(job["label"], job["csv"], job["output"])

if __name__ == "__main__":
    main()