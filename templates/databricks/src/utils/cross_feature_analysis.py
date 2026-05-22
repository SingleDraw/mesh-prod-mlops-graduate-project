from pyspark.sql import DataFrame, functions as F

# ================ Cross-feature analysis outlier detection ================
config = {
    'mat_allowance':    600, # min 600 mm allowance for material mount on batch length (300 mm on each side)
    'min_batch_th':     3000, # threshold for batch length to investigate (lowered from 20000 to 3000 to capture more potential outliers for analysis)
    'batchl_dev_tol':   0.1 # 10% generous threshold due to imprecision in production process and waste allowance
}

def drop_invalid_batch_length(df: DataFrame, config: dict) -> DataFrame:
    """ Identifies and drops rows where 'batch_length' is significantly different 
        from the expected value calculated based on 'mesh_sp', 'qty', and a material allowance. 
        This helps to identify potential data entry errors or inconsistencies in the 'batch_length' feature. """
    
    mat_allowance = config.get('mat_allowance', 600)
    min_batch_th = config.get('min_batch_th', 3000)
    batchl_dev_tol = config.get('batchl_dev_tol', 0.1)

    analyzed = (
        df
        .filter(F.col('batch_length') > min_batch_th)
        .withColumn( # create calculated_batch_length on the fly
            'calculated_batch_length',
            F.col('mesh_sp') * F.col('qty') + F.lit(mat_allowance)
        )
        .withColumn( # create length_diff_percentage on the fly
            'length_diff_percentage',
            F.abs(
                 (F.col('batch_length') - F.col('calculated_batch_length')) 
                / F.col('batch_length')
            )
        )
    ).filter(
        F.abs(F.col('length_diff_percentage')) > F.lit(batchl_dev_tol)
    ).drop(
        # drop intermediate columns
        'calculated_batch_length', 
        'length_diff_percentage'
    ) 

    return df.subtract(analyzed)