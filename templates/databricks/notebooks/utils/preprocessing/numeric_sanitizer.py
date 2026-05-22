import pandas as pd

class NumericSanitizer:
    @staticmethod
    def sanitize_numeric_inplace(df: pd.DataFrame, numeric_columns: list[str]) -> None:
        for col in numeric_columns:
            NumericSanitizer._sanitize_column(df, col)

    @staticmethod
    def _sanitize_column(df: pd.DataFrame, col_name: str) -> None:
        """ Sanitized numeric values in float columns inplace
            by extracting numeric part until the first non-numeric character
            and coercing to numeric, setting non-convertible values to NaN """
        col = df[col_name]

        # 1. detect non-numeric values
        nn_mask = pd.to_numeric(col, errors='coerce').isna()
        if not nn_mask.any():
            return
        
        # 2. extract numeric part
        sanitized = (
            col[nn_mask].astype(str)                         # Ensure we are working with strings
            .str.replace(',', '.', regex=False)              # , => . for decimal separator
            .str.extract(r'(-?\d+(?:\.\d+)?)', expand=False) # get numeric part until first non-numeric character, also handle negative numbers
        )

        # 3. cast to numeric / NaN inplace 
        df.loc[nn_mask, col_name] = pd.to_numeric(sanitized, errors='coerce')