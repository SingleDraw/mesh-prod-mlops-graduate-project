import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np

class Visualization:
    
    @staticmethod
    def plot_distribution(data: pd.Series, title: str = 'target', bins: int = 100) -> None:
        """ Plots histogram for a single column to visualize its distribution. """

        plt.figure(figsize=(12, 4))

        plt.subplot(1, 2, 1)
        plt.hist(data, bins=bins)
        plt.title("Before log transformation")


        plt.subplot(1, 2, 2)
        plt.hist(np.log1p(data), bins=bins)
        plt.title("After log transformation")

        plt.suptitle(f"Distribution of {title} variable")
        plt.tight_layout()
        plt.show()



    @staticmethod
    def plot_feature_relationships(data, cols, target='process_time', filter_mask=None, color='blue'):
        num_rows = (len(cols) + 2) // 3
        num_cols = min(3, len(cols))

        if filter_mask is not None:
            data_ = data[filter_mask]
        else:
            data_ = data

        plt.figure(figsize=(5 * num_cols, 4 * num_rows))

        for i, col in enumerate(cols):
            if col is target:
                continue
            plt.subplot(num_rows, num_cols, i + 1)
            sns.scatterplot(
                data=data_, 
                x=col, 
                y=target, 
                color=color, 
                alpha=0.6, 
                edgecolor='w', 
                # s=10,
                # hue=hue_col
            )

            # trendline
            if data_[col].nunique() > 10: # only for numeric columns with enough unique values
                sns.regplot(
                    data=data_, 
                    x=col, 
                    y=target, 
                    scatter=False, 
                    color='red', 
                    line_kws={'linewidth':1}
                )

            plt.title(f"{col} vs {target}")

        plt.tight_layout()
        plt.show()

    @staticmethod
    def plot_feature_distributions(data, cols, bins=50, per_cat='stand_type', log_scale=False):

        cats = sorted(data[per_cat].dropna().unique())

        num_rows = len(cols)
        num_cols = len(cats)

        plt.figure(figsize=(6 * num_cols, 4 * num_rows))

        for i, col in enumerate(cols):
            for cat_idx, cat in enumerate(cats):

                data_ = data[data[per_cat] == cat]

                # ensure numeric type for histogram plotting, 
                # handle non-numeric gracefully
                series = data_[col].astype(float)

                if log_scale:
                    series = series.clip(lower=0)  # or handle negatives depending on meaning
                    series = np.log1p(series)

                col_ = series

                no = i * num_cols + cat_idx + 1

                plt.subplot(num_rows, num_cols, no)

                sns.histplot(
                    data=data_,
                    x=col_,
                    bins=bins,
                    kde=True,
                    alpha=0.5
                )

                plt.title(f"{col} | {per_cat}={cat}")

        plt.tight_layout()
        plt.show()