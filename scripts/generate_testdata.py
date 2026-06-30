from pathlib import Path

import pandas as pd


OUTPUT_PATH = Path("data") / "tax_cases.csv"


def build_cases() -> pd.DataFrame:
    rows = [
        {"jaarinkomen": 28000, "aftrek": 1000, "verwachte_schijf": "SCHIJF_1"},
        {"jaarinkomen": 55000, "aftrek": 5000, "verwachte_schijf": "SCHIJF_2"},
        {"jaarinkomen": 120000, "aftrek": 10000, "verwachte_schijf": "SCHIJF_3"},
    ]
    return pd.DataFrame(rows)


def main() -> None:
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    df = build_cases()
    df.to_csv(OUTPUT_PATH, index=False)
    print(f"Saved {len(df)} cases to {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
