import os
import sys

# Determining the current script path in Databricks environment
if "filename" in globals():
    current_script = globals()["filename"]
elif "__file__" in globals():
    current_script = __file__
else:
    # Fallback
    current_script = os.path.join(os.getcwd(), "src/bronze/ingest.py")

# Calculating paths
current_dir = os.path.dirname(os.path.abspath(current_script)) # src/bronze
src_dir = os.path.dirname(current_dir)                         # src
project_root = os.path.dirname(src_dir)                        # files (root)

# Adding project root to sys.path for imports
if project_root not in sys.path:
    sys.path.insert(0, project_root)

# =========== Imports ===========
from src.utils.sanitizer import Sanitizer
from src.utils.xlsx_loader import load_spark_excel
# =========== End of imports ===========

import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.functions import current_timestamp, input_file_name


# =========== Main function ===========
def main(storage_account, container, source_blob, sink_blob="delta/bronze/production_time"):
    spark = SparkSession.getActiveSession() or SparkSession.builder.getOrCreate()
    source_path = f"abfss://{container}@{storage_account}.dfs.core.windows.net/{source_blob}"
    sink_delta = f"abfss://{container}@{storage_account}.dfs.core.windows.net/{sink_blob}"

    print(f"Reading from source blob at: {source_path}")
    print(f"Writing to bronze delta at: {sink_delta}")

    # Chaining transformations
    return (
        load_spark_excel(spark, source_path)
        .withColumn("source_file", F.lit(source_path))
        .transform(lambda df: Sanitizer.sanitize_column_names(df))
        # add metadata columns (optional - note that it changes schema!)
        .withColumn("ingestion_timestamp", current_timestamp())
        .transform(lambda df: (print(f"Rows count: {df.count()}") or df))
    ).write.format("delta").mode("overwrite").save(sink_delta)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("--storage_account", required=True)
    parser.add_argument("--container", required=True)
    parser.add_argument("--source_blob", required=True)
    parser.add_argument("--sink_blob", required=False, default="delta/bronze/production_time")
    
    args = parser.parse_args()

    main(args.storage_account, args.container, args.source_blob, args.sink_blob)