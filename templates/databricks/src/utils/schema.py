from pyspark.sql.types import FloatType, IntegerType, StringType

# =========== Define column names for consistency ===========

column_names = [ 
    'op_w',             # oczko/szczelina       -> op_w         = opening width     [mm]
    'op_l',             # Unnamed: 1            -> op_l         = opening length    [mm]
    'wire_dia',         # drut                  -> wire_dia     = wire diameter     [mm]
    'op_align',         # *                     -> op_align     = opening alignment (A, B, nan)
    'qty',              # szt.                  -> qty          = product quantity  [pcs]
    'mesh_fl',          # wymiar [mm]           -> mesh_fl      = mesh weft width   [mm]
    'mesh_sp',          # Unnamed: 6            -> mesh_sp      = mesh warp length  [mm]
    'batch_width',      # szerokosc [mm]        -> batch_width  = batch width       [mm]
    'batch_length',     # zaciąg [mm]           -> batch_length = batch length      [mm]
    'process_time',     # czas[min]             -> process_time = production time of the batch [min]
    'stand_type',        # stand                 -> stand_type   = production stand type ('KROSNO I', 'KROSNO II', 'KROSNO III')
    'ingestion_timestamp',  # metadata column for ingestion timestamp
    'source_file'           # metadata column for source file name
]


# =========== Define columns to cast ===========

columns_to_cast_float = ['op_w', 'op_l', 'wire_dia', 'mesh_fl', 'mesh_sp', 'batch_width', 'batch_length', 'process_time']
columns_to_cast_int = ['qty']
columns_to_cast_cat = ['op_align', 'stand_type']

numeric_cols = columns_to_cast_float + columns_to_cast_int

# =========== Define Spark data types for casting ===========

spark_types = {
    **{col: FloatType() for col in columns_to_cast_float},
    **{col: IntegerType() for col in columns_to_cast_int},
    **{col: StringType() for col in columns_to_cast_cat}
}