from pyspark.sql import DataFrame, functions as F

# cutoff for outliers based on DOMAIN knowledge
domain_cutoffs = {
    'op_w': (0, 400),
    'op_l': (0, 400),
    'wire_dia': (0, 15),
    'mesh_fl': (0, 2500),
    'batch_width': (0, 2500)
}

def filter_domain_outliers(df: DataFrame, cutoffs: dict) -> DataFrame:
    """ Filters out rows with outliers based on domain-specific cutoffs. """
    
    mask = F.lit(True)
    for col, (lower, upper) in cutoffs.items():
        if col in df.columns:
            col_mask = (F.col(col) >= lower) & (F.col(col) <= upper)
            mask = mask & col_mask
    
    return df.filter(mask)
