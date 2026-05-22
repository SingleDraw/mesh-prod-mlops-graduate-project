import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

class DomainOutliers:
    """ Class for filtering out outliers 
        based on domain knowledge and specific rules. """
    
    def __init__(self, config: dict):
        self.config = config
        self.stats_ = {}
        self.is_fitted = False


    def filter(self, df: pd.DataFrame) -> pd.DataFrame:
        """ Filters out rows in the dataframe that contain outliers based on specified domain cutoffs. 
            Returns a new dataframe with outliers removed. """
        
        initial_count = len(df)

        mask = pd.Series(True, index=df.index)

        for col, (lower, upper) in self.config.items():
            if col in df.columns:
                col_mask = (df[col] >= lower) & (df[col] <= upper)

                self.stats_[col] = {
                    'cutoff range': (lower, upper),
                    'initial count': initial_count,
                    'removed': (~col_mask).sum(),
                    '% removed': round((~col_mask).sum() / initial_count * 100, 2)
                }

                mask &= col_mask
            else:
                print(f"Warning: Column '{col}' not found in dataframe. Skipping outlier filtering for this column.")

        self.is_fitted = True
        return df[mask].copy()


    def plot_cutoff_impact(self, df: pd.DataFrame):
        """ Plots box plots and distribution plots for specified columns with outliers removed based on domain cutoffs. """
        if not self.config:
            print("No domain cutoffs provided. Please specify cutoffs to identify outliers.")
            return

        n_rows = len(self.config)
        n_cols = 3

        plt.figure(figsize=(15, 4 * n_rows))

        # filter out outliers based on domain cutoffs
        df_filtered = self.filter(df)
        
        for i, (col, (lower, upper)) in enumerate(self.config.items()):
            # ======================
            # box plot for input data col with outliers
            plt.subplot(n_rows, n_cols, 3 * i + 1)
            sns.boxplot(x=col, data=df, color='skyblue')
            plt.title(f"Box plot for '{col}'")


            # ======================
            # box plot for col with outliers removed
            plt.subplot(n_rows, n_cols, 3 * i + 2)
            sns.boxplot(x=col, data=df_filtered, color='skyblue', showmeans=True)
            plt.title(f"Box plot for '{col}' (outliers removed)")

            # # ======================
            # # box plot for col with outliers removed and log transformed
            # plt.subplot(n_rows, n_cols, 3 * i + 3)
            # import numpy as np
            # sns.boxplot(x=np.log1p(df_filtered[col]), color='salmon', showmeans=True) # log1p - log(1+x) to handle zero values
            # plt.title(f"Box plot for '{col}' (outliers removed, log transformed)")

            # distribution plot for col with outliers removed
            plt.subplot(n_rows, n_cols, 3 * i + 3)
            sns.histplot(x=col, data=df_filtered, kde=False, color='salmon', bins=100, alpha=0.5)
            plt.title(f"Distribution of '{col}' (outliers removed)")

        plt.tight_layout()
        plt.show()


    def get_summary(self) -> pd.DataFrame:
        """ Returns a dataframe with statistics about the outliers removed based on domain cutoffs. """
        if not self.is_fitted:
            print("No outlier filtering performed yet. Please call the 'filter' method first to compute statistics.")
            return
        
        return pd.DataFrame(self.stats_).T
