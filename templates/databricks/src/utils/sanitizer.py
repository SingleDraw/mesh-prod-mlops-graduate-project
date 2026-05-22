from pyspark.sql import DataFrame
from pyspark.sql import functions as F
import re

class Sanitizer:
    @staticmethod
    def sanitize_numeric(df: DataFrame, numeric_columns: list[str]) -> DataFrame:
        """
        Sanitizes numeric columns by:
        1. Replacing commas with dots
        2. Extracting the first matching number using regex
        3. Casting to Double
        """
        for col_name in numeric_columns:
            # Regex: (-?\d+(?:\.\d+)?)
            # Optional minus, digits, optional dot and more digits
            regex_pattern = r"(-?\d+(?:\.\d+)?)"
            
            df = df.withColumn(
                col_name,
                F.regexp_extract(
                    F.regexp_replace(F.col(col_name).cast("string"), ",", "."), 
                    regex_pattern, 
                    1
                ).cast("double")
            )
        
        return df

    @staticmethod
    def sanitize_column_names(df: DataFrame) -> DataFrame:
        """ Sanitizes column names by replacing spaces and special characters with underscores,
            and collapsing multiple underscores into a single one."""
        for col in df.columns:
            new_col = re.sub(r'[ ,;{}()\n\t=\[\]]', '_', col)
            new_col = re.sub(r'_+', '_', new_col).strip('_')
            df = df.withColumnRenamed(col, new_col)
        return df