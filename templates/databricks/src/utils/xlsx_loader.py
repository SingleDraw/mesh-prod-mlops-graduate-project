import openpyxl
from pyspark.dbutils import DBUtils
from pyspark.sql import functions as F

def load_spark_excel(spark, file_path: str, rejected_sheets=("zbiorcze",)):
    """ Loads an Excel file with multiple sheets into a single Spark DataFrame. 
        Each sheet is tagged with its name."""
    
    local_path = "/tmp/production_time.xlsx"
    dbutils = DBUtils(spark)
    dbutils.fs.cp(file_path, f"file:{local_path}")

    wb = openpyxl.load_workbook(local_path, read_only=True)
    all_sheets = wb.sheetnames
    wb.close()

    final_df = None

    rejected = {s.lower() for s in rejected_sheets}

    for sheet_name in all_sheets:
        if sheet_name.lower() in rejected:
            continue

        print(f"Processing sheet: {sheet_name}")

        df = spark.read.format("com.crealytics.spark.excel") \
            .option("header", "true") \
            .option("dataAddress", f"'{sheet_name}'!A1") \
            .load(f"file://{local_path}")

        if df.isEmpty():
            continue

        df = df.withColumn("stand", F.lit(sheet_name))

        final_df = df if final_df is None else final_df.unionByName(df, True)

    return final_df

