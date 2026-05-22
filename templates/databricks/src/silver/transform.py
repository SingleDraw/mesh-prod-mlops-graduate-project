import os
import sys

# Determining the current script path in Databricks environment
if "filename" in globals():
    current_script = globals()["filename"]
elif "__file__" in globals():
    current_script = __file__
else:
    # Fallback
    current_script = os.path.join(os.getcwd(), "src/silver/transform.py")

# Calculating paths
current_dir = os.path.dirname(os.path.abspath(current_script)) # src/silver
src_dir = os.path.dirname(current_dir)                         # src
project_root = os.path.dirname(src_dir)                        # files (root)

# Adding project root to sys.path for imports
if project_root not in sys.path:
    sys.path.insert(0, project_root)

# =========== Imports ===========
from src.utils.sanitizer import Sanitizer
from src.utils.data_cleaner import DataCleaner
from src.utils.outlier_filter import filter_domain_outliers, domain_cutoffs
from src.utils.cross_feature_analysis import drop_invalid_batch_length, config
from src.utils.schema import column_names, spark_types, numeric_cols
# =========== End of imports ===========

import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.functions import current_timestamp, input_file_name


# =========== Main function ===========
def main(storage_account, container, source_blob, sink_blob):
    spark = SparkSession.getActiveSession() or SparkSession.builder.getOrCreate()
    delta_path = f"abfss://{container}@{storage_account}.dfs.core.windows.net/{source_blob}"
    sink_path = f"abfss://{container}@{storage_account}.dfs.core.windows.net/{sink_blob}"

    print(f"Reading from bronze delta at: {delta_path}")
    print(f"Writing to silver delta at: {sink_path}")

    # Chaining transformations
    return (
        spark.read.format("delta").load(delta_path)
        # get file name before transformations (due to potential shuffling and repartitioning)
        # .withColumn("source_file", F.col("_metadata.file_name")) 
        .toDF(*column_names)
        .transform(lambda df: Sanitizer.sanitize_numeric(df, numeric_cols))
        .dropna(subset=numeric_cols)
        .select(*[F.col(c).cast(spark_types[c]).alias(c) for c in spark_types])

        .transform(lambda df: DataCleaner.clean_op_align(df)) # clean 'op_align' column
        .transform(lambda df: DataCleaner.rename_stand_type(df)) # rename 'stand_type' column
        .transform(lambda df: DataCleaner.drop_invalid_op(df)) # drop invalid 'op' rows
        .dropDuplicates() # drop duplicates
        .transform(lambda df: filter_domain_outliers(df, domain_cutoffs)) # filter out domain-specific outliers
        .transform(lambda df: drop_invalid_batch_length(df, config)) # drop rows with invalid batch length based on cross-feature analysis

        # print schema after cleaning
        .transform(lambda df: (
            print("Schema after cleaning:") or df.printSchema() or df
        ))
        # count rows after cleaning
        .transform(lambda df: (
            print(f"Count after cleaning: {df.count()}") or 
            print(f"Duplicate rows after cleaning: {df.count() - df.distinct().count()}") or 
            df
        ))
        # add metadata columns (optional - note that it changes schema!)
        .withColumn("transformation_timestamp", current_timestamp())
        .transform(lambda df: (print(f"Rows count: {df.count()}") or df))
    ).write.format("delta").mode("overwrite").save(sink_path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("--storage_account", required=True, help="Name of the storage account")
    parser.add_argument("--container", required=True, help="Name of the container")
    parser.add_argument("--source_blob", required=True, help="Path for bronze delta, e.g. delta/bronze/production_time")
    parser.add_argument("--sink_blob", required=True, help="Path for silver delta, e.g. delta/silver/production_time")
    
    args = parser.parse_args()

    main(args.storage_account, args.container, args.source_blob, args.sink_blob)