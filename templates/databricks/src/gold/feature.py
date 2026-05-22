import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.functions import current_timestamp

# =========== Main function ===========
def main(storage_account, container, source_blob, sink_blob):
    spark = SparkSession.getActiveSession() or SparkSession.builder.getOrCreate()
    delta_path = f"abfss://{container}@{storage_account}.dfs.core.windows.net/{source_blob}"
    sink_path = f"abfss://{container}@{storage_account}.dfs.core.windows.net/{sink_blob}"

    print(f"Reading from silver delta at: {delta_path}")
    print(f"Writing to gold delta at: {sink_path}")

    # Chaining transformations
    return (
        spark.read.format("delta").load(delta_path)
        .filter(F.col("process_time") > 0)
        .filter(F.col("qty") > 0)
        # add metadata columns (optional - note that it changes schema!)
        .withColumn("transformation_timestamp", current_timestamp())
        # .withColumn("source_file", input_file_name())
        .transform(lambda df: (print(f"Rows count: {df.count()}") or df))
    ).write.format("delta").mode("overwrite").save(sink_path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("--storage_account", required=True, help="Name of the storage account")
    parser.add_argument("--container", required=True, help="Name of the container")
    parser.add_argument("--source_blob", required=True, help="Path for silver delta, e.g. delta/silver/production_time")
    parser.add_argument("--sink_blob", required=True, help="Path for gold delta, e.g. delta/gold/production_time")
    
    args = parser.parse_args()

    main(args.storage_account, args.container, args.source_blob, args.sink_blob)