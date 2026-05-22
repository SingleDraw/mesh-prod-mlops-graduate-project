import argparse
import os
import mltable
import pandas as pd
from sklearn.model_selection import train_test_split

# =========== Argument parsing ===========
parser = argparse.ArgumentParser()
parser.add_argument("--input_data",    type=str, required=True)
parser.add_argument("--test_size",     type=float, default=0.2)
parser.add_argument("--random_state",  type=int,   default=42)
parser.add_argument("--target_column", type=str,   required=True)
parser.add_argument("--X_train",       type=str,   required=True)
parser.add_argument("--X_test",        type=str,   required=True)
parser.add_argument("--y_train",       type=str,   required=True)
parser.add_argument("--y_test",        type=str,   required=True)
args = parser.parse_args()

# =========================
# LOAD MLTABLE (DELTA)
# =========================
tbl = mltable.load(args.input_data)
df = tbl.to_pandas_dataframe()

print(f"Loaded {len(df)} rows, {len(df.columns)} columns")
print(f"Columns: {list(df.columns)}")

# =========================
# DROP METADATA COLUMNS IF PRESENT
# =========================
DROP_COLS = ["transformation_timestamp", "source_file"]
cols_to_drop = [c for c in DROP_COLS if c in df.columns]
if cols_to_drop:
    print(f"Dropping columns: {cols_to_drop}")
    df = df.drop(columns=cols_to_drop)
else:
    print("None of the drop-columns were present, skipping.")

# =========================
# VERIFY TARGET COLUMN
# =========================
if args.target_column not in df.columns:
    raise ValueError(
        f"Target column '{args.target_column}' not found. "
        f"Available: {list(df.columns)}"
    )
 
X = df.drop(columns=[args.target_column])
y = df[[args.target_column]]
print(f"Features: {list(X.columns)}")
print(f"Target:   {args.target_column}")


# =========================
# SPLIT DATA
# =========================
X_train, X_test, y_train, y_test = train_test_split(
    X, y,
    test_size=args.test_size,
    random_state=args.random_state
)
print(f"Train size: {len(X_train)}\nTest size: {len(X_test)}")


# =========================
# WRITE PARQUETES
# =========================
# with open(args.delta_output, "w") as f:
#     f.write(f"rows={len(df)}\n")
#     f.write(f"columns={list(df.columns)}\n")
#     f.write(f"sample_row={df.iloc[0].to_dict() if len(df) > 0 else None}\n")

# print("Written:", args.delta_output)
for data, path, name in [
    (X_train, args.X_train, "X_train"),
    (X_test,  args.X_test,  "X_test"),
    (y_train, args.y_train, "y_train"),
    (y_test,  args.y_test,  "y_test"),
]:
    os.makedirs(path, exist_ok=True)
    out_path = os.path.join(path, f"{name}.parquet")
    data.to_parquet(out_path, index=False)
    print(f"Saved {name} to {out_path}  ({len(data)} rows)")
 
print("Prepare step complete.")
