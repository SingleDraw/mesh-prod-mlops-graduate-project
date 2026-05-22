import pandas as pd

class BasicEDA:
    # =============================================
    # Main methods (static)
    # =============================================
    @staticmethod
    def basic_insights(df: pd.DataFrame) -> None:
        """ Displays basic information about the dataframe, 
            including number of observations, duplicates, 
            shape, columns, and missing values."""
        
        print(f"{50*'-'}\nBasic EDA insights:\n{50*'-'}")
        print(f"    Number of observations: {len(df)}")
        print(f"    Duplicate rows: {df.duplicated().sum()}")
        print(f"    Shape: {df.shape}")
        print(f"    Number of columns: {len(df.columns)}")
        print(f"\n    Features:\n        {', '.join(df.columns.tolist())}")
        print(f"\n    Missing values:")
        total = len(df)
        for col in df.columns:
            missing = df[col].isna().sum()
            print(
                f"        {col:<22} "
                f"{missing:>4}/{total:<6} "
                f"{missing/total*100:>6.2f}%"
            )
        print(f"{50*'-'}\nEnd of insights\n")
    

    @staticmethod
    def show_samples(df: pd.DataFrame, n: int = 5) -> None:
        """Displays a sample of the dataframe."""
        
        if df is None:
            print("Dataframe is empty. Please load data first.")
            return
        
        sample_size = n
        print(f"{50*'-'}\nData types and sample values:\n{50*'-'}")
        for col in df.columns:
            print(f"  {col:<18} {str(df[col].dtype):<8} "
                  f"{df[col].unique()[:sample_size]} "
                  f"{'...' if len(df[col].unique()) > sample_size else ''}")


    @staticmethod
    def analyse_numeric_columns(
        df: pd.DataFrame, 
        numeric_columns: list[str], 
        sample_size: int = 5
        ) -> None:
        total_nn_indices = set()

        for col in numeric_columns:
            
            # Replace non-numeric values with NaN
            nn_mask = (pd
                .to_numeric(df[col], errors='coerce')
                .isna()
            )
            non_numeric_df = df[nn_mask]

            if not non_numeric_df.empty:
                nn_count = len(non_numeric_df)
                col_nn_indices = non_numeric_df.index.tolist()

                total_nn_indices.update(col_nn_indices)

                values_string = (
                    ', '.join(map(str, non_numeric_df[col][:sample_size])) 
                    + (' ...' if nn_count > sample_size else '')
                )

                print(
                    f"Non-numeric values in {'"'+col+'"':<16} "
                    f"found: {nn_count:<4} (values: {values_string})")


        print(f"\nTotal unique indices with non-numeric values across all float columns: {len(total_nn_indices)}\n")
