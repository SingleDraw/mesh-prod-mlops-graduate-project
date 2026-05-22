from pyspark.sql import SparkSession

# ----------------------------------------
# Test Spark compatibility with Java Runtime
# ----------------------------------------

# 1/ Create SparkSession
spark = SparkSession.builder \
    .appName("spark-test") \
    .master("local[*]") \
    .config("spark.jars.packages", "org.postgresql:postgresql:42.6.0") \
    .getOrCreate()

print("\nSparkSession created successfully!\n")