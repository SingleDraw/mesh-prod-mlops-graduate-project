import pandas as pd
from IPython.display import display, Markdown

class StatisticsEDA:
    """ Class for performing exploratory data analysis (EDA) to identify potential outliers 
        based on summary statistics and visualizations. """
    
    @staticmethod
    def statistics(df: pd.DataFrame) -> None:
        """ Displays summary statistics for numeric and categorical columns 
            to help identify potential outliers. """
        
        numeric_stats = ['count', 'mean', 'std', 'min', '25%', '50%', '75%', 'max']
        categorical_stats = ['count', 'unique', 'top', 'freq']

        numeric_cols = df.select_dtypes(include='number').columns.tolist()
        categorical_cols = df.select_dtypes(include='category').columns.tolist()

        display(Markdown("### Summary statistics for numeric columns"))
        display(df[numeric_cols].describe().T[numeric_stats].round(2))
        display(Markdown("### Summary statistics for categorical columns"))
        display(df[categorical_cols].describe().T[categorical_stats])
                