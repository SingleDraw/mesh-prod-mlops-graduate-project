import pandas as pd
from typing import Iterable

class DataLoader:
    """
    DataLoader is responsible for loading data from an Excel file containing multiple sheets.
    It filters sheets based on their names and shapes to identify those that contain production stand data.
    Main method:
    - load(file_path): Loads data from the specified Excel file and returns a combined DataFrame.
    """

    # =============================================
    # Main methods
    # =============================================
    @staticmethod
    def load(file_path: str) -> pd.DataFrame:
        try:
            df = pd.DataFrame()

            print(f"Loading data from {file_path} sheets...")
            df_sheets = pd.read_excel(file_path, sheet_name=None)

            for sheet_name, sheet_df in df_sheets.items():
                if DataLoader._is_production_stand(sheet_df, sheet_name):
                    print(f"Processing sheet: {sheet_name}")

                    sheet_df['stand'] = sheet_name  # Add a column to identify the sheet

                    # NOTE: ignore_index=True to reset index after concatenation
                    df = pd.concat([df, sheet_df], ignore_index=True) 
                else:
                    print(f"Skipping sheet: {sheet_name} (not a production stand sheet)")
            
            print(f"Data loaded successfully with {len(df)} rows.")

            return df

        except Exception as e:
            print(f"Error loading Excel file: {e}")
            raise

    # =============================================
    # Helper methods for sheet validation
    # =============================================
    @staticmethod
    def _is_sheet_proper_shaped(df: pd.DataFrame) -> bool:
        # TODO: Validate shape size
        return True

    @staticmethod
    def _is_production_stand(
            df: pd.DataFrame, 
            sheet_name: str,
            rejected_sheets: Iterable[str] = ('zbiorcze',)
        ) -> bool:
        """
        Determines if selected sheet 
        is a production stand data sheet based on its name and shape.
        Used to filter out sheets with aggregated data (e.g. 'zbiorcze') and empty sheets."""

        rejected = {s.lower() for s in rejected_sheets}

        return (
            not df.empty 
            and sheet_name.lower() not in rejected
            and DataLoader._is_sheet_proper_shaped(df)
        )
    