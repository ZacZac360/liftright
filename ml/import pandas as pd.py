import joblib
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
MODEL_DIR = SCRIPT_DIR / "models"

FILES = [
    "bicep_curl_ocsvm.pkl",
    "lateral_raise_ocsvm.pkl",
    "shoulder_press_ocsvm.pkl",
]

def inspect_model(model_path: Path):
    if not model_path.exists():
        print("=" * 60)
        print("Missing file:", model_path)
        return

    bundle = joblib.load(model_path)

    print("=" * 60)
    print("File:", model_path.name)
    print("Full path:", model_path)
    print("Exercise:", bundle.get("exercise"))
    print("Features:", bundle.get("features"))
    print("NU:", bundle.get("nu"))
    print("Threshold percentile:", bundle.get("threshold_pct"))
    print("Threshold:", bundle.get("threshold"))

def main():
    print("Script folder:", SCRIPT_DIR)
    print("Model folder :", MODEL_DIR)

    for name in FILES:
        inspect_model(MODEL_DIR / name)

if __name__ == "__main__":
    main()