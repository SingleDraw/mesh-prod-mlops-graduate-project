from pyspark.sql import DataFrame, functions as F

class DataCleaner:
    """ Class responsible for cleaning and preprocessing the data, 
        including handling missing values,
        correcting data types, and filtering out invalid entries. """
    
    @staticmethod
    def clean_op_align(df: DataFrame) -> DataFrame:
        """ Cleans the 'op_align' column by filling missing values, 
            converting to uppercase, and filtering out invalid categories. """

        valid = ['S', 'A', 'B']

        return (
            df
            .withColumn(
                'op_align',
                F.upper(F.coalesce(F.col('op_align'), F.lit('S')))
            )
            .filter(F.col('op_align').isin(valid))
        )


    @staticmethod
    def rename_stand_type(df: DataFrame) -> DataFrame:
        """ Renames the 'stand_type' column by mapping Roman numerals 
            to integers and cleaning the string values. """
        mapping = {
            'I': 'A',
            'II': 'B',
            'III': 'C',
            'IV': 'D',
            'V': 'E',
            'VI': 'F',
            'VII': 'G'
        }

        mapping_expr = F.create_map(
            *[x for kv in mapping.items() for x in (F.lit(kv[0]), F.lit(kv[1]))]
        )

        cleaned = (
            F.upper(
                F.regexp_replace(
                    F.col("stand_type").cast("string"),
                    r"KROSNO ",
                    ""
                )
            )
        )

        return (
            df
            .withColumn(
                "stand_type",
                F.coalesce(
                    mapping_expr[cleaned],
                    cleaned
                )
            )
        )

    @staticmethod
    def drop_invalid_op(df: DataFrame) -> DataFrame:
        """
        Drops rows where:
        - op_align == 'S'
        - and op_w != op_l
        """
        return df.filter(
            ~(
                (F.col("op_align") == "S") &
                (F.col("op_w") != F.col("op_l"))
            )
        )