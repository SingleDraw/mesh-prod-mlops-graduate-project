# plot_utils.py
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd

def plot_feature_importance(importance_df, top_n=20):
    """ Plots the top N most important features based on their weights."""
    top_features = importance_df.head(top_n) if len(importance_df) > top_n else importance_df
    
    plt.figure(figsize=(10, 6))
    sns.barplot(
        x='weight', y='feature', 
        data=top_features, 
        palette='viridis',
        hue='weight',
        )
    plt.title(f'Top {top_n} Feature Importances')
    plt.xlabel('Importance (Coefficient Weight)')
    plt.ylabel('Feature')
    plt.tight_layout()
    plt.show()


def plot_correlation_matrix(pipeline, X):
    """ Plots the correlation matrix of the features after transformation. """
    corr_matrix = pd.DataFrame(
        pipeline[:-1].transform(X), columns=pipeline[:-1].get_feature_names_out()
    ).corr()

    plt.figure(figsize=(12, 10))
    sns.heatmap(corr_matrix, annot=True, fmt=".2f", cmap='coolwarm', cbar=True)
    plt.title("Correlation Matrix of Features")
    plt.tight_layout()
    plt.show()