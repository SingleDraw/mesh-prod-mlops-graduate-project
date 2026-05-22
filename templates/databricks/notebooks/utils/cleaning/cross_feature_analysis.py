import pandas as pd

class CrossFeatureAnalysis:
    def __init__(self, config: dict):
        self.config = config
        self.stats_ = {}
        self.stats_table_ = None
        self.stats_summary_ = None
        self.is_fitted = False

        self.head_display_cols = [
            'batch_length', 'batch_width', 'qty', 'mesh_sp', 'mesh_fl', 
            'calculated_batch_length', 'length_diff', 'length_diff_percentage']
        
        self.stats_display_cols = ['batch_length', 'length_diff', 'length_diff_percentage']
          

    def drop_invalid_batch_length(self, df: pd.DataFrame) -> None:
        """ Identifies and drops rows where 'batch_length' is significantly different 
            from the expected value calculated based on 'mesh_sp', 'qty', and a material allowance. 
            This helps to identify potential data entry errors or inconsistencies in the 'batch_length' feature. """
        
        mat_allowance = self.config.get('mat_allowance', 600)
        min_batch_th = self.config.get('min_batch_th', 3000)
        batchl_dev_tol = self.config.get('batchl_dev_tol', 0.1)

        columns = df.columns.tolist()

        total_rows = len(df)

        df_ = df[df['batch_length'] > min_batch_th].copy()

        rows_analyzed = len(df_)

        df_['calculated_batch_length'] = df_['mesh_sp'] * df_['qty'] + mat_allowance

        df_['length_diff'] = df_['batch_length'] - df_['calculated_batch_length']

        df_['length_diff_percentage'] = abs(df_['length_diff']) / df_['batch_length']

        df_ = df_[abs(df_['length_diff_percentage']) > batchl_dev_tol]

        self.stats_ = {
            'min batch_length analysis threshold': str(min_batch_th) + " mm",
            'batch_length deviation tolerance': str(batchl_dev_tol * 100) + " %",
            'material c/o allowance': str(mat_allowance) + " mm",
            'total rows': total_rows,
            'rows analyzed': rows_analyzed,
            'invalid rows detected': len(df_),
            'total dropout': str(round(len(df_) / total_rows * 100, 2)) + " %"
        }
        self.stats_table_ = df_.loc[:, self.head_display_cols].sort_values(by='length_diff_percentage', ascending=False).head(10).round(2)
        self.stats_summary_ = df_.loc[:, self.stats_display_cols].describe().T.round(2)

        self.is_fitted = True

        return df.drop(index=df_.index)[columns].copy()
    

    def get_summary(self) -> None:
        if not self.is_fitted:
            print("No analysis performed yet. Please run 'drop_invalid_batch_length' first to analyze the data.")
            return
        
        df_stats = pd.DataFrame(self.stats_, index=[0]).T.rename(columns={0: 'Value'})

        styled_df = df_stats.style.set_properties(**{'text-align': 'left'})

        return styled_df
    
    def get_stats_table(self) -> pd.DataFrame:
        if self.stats_table_ is None:
            print("No stats table available. Please run 'drop_invalid_batch_length' first to compute the stats table.")
            return
        
        return self.stats_table_
    
    def get_stats_summary(self) -> pd.DataFrame:
        if self.stats_summary_ is None:
            print("No stats summary available. Please run 'drop_invalid_batch_length' first to compute the stats summary.")
            return
        
        return self.stats_summary_