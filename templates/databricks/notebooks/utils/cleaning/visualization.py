import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np

class Visualization:
    
    @staticmethod
    def plot_distributions(df: pd.DataFrame, column_names: list[str]) -> None:
        """ Plots histograms for specified columns 
            to visualize their distributions and identify potential outliers. """
        
        plt.figure(figsize=(15, 4 * len(column_names)))

        n_cols = 2
        n_rows = len(column_names)

        for i, col in enumerate(column_names):
            # Plot 1: Original distribution
            plt.subplot(n_rows, n_cols, i * n_cols + 1)
            sns.histplot(df[col], kde=False, color='skyblue', bins=100)
            plt.title(f"Distribution of '{col}'")

            # Plot 2: Boxplot to visualize outliers
            plt.subplot(n_rows, n_cols, i * n_cols + 2)
            sns.boxplot(x=df[col], color='lightblue')
            plt.title(f"Boxplot of '{col}' to visualize outliers")

            # plt.subplot(n_rows, n_cols, i * n_cols + 3)
            # sns.histplot(np.log1p(df[col]), kde=False, color='salmon', bins=100, alpha=0.5)
            # plt.yscale('log')  # Use log scale to better visualize outliers
            # plt.title(f"Distribution of '{col}' (log1p x-axis, log y-axis)")

        plt.tight_layout(w_pad=2)
        plt.show()
