import pandas as pd

class DataCleaner:
    """ Class responsible for cleaning and preprocessing the data, 
        including handling missing values,
        correcting data types, and filtering out invalid entries. """
    
    @staticmethod
    def clean_op_align(df: pd.DataFrame) -> pd.DataFrame:
        """ Cleans the 'op_align' column by filling missing values, 
            converting to uppercase, and filtering out invalid categories. """
        valid = {'S', 'A', 'B'}

        df = df.copy()

        if 'S' not in df['op_align'].cat.categories:
            df['op_align'] = df['op_align'].cat.add_categories(['S'])

        df['op_align'] = (
            df['op_align']
                .fillna('S')
                .astype(str)
                .str.upper()
            )

        df = df[df['op_align'].isin(valid)]

        df['op_align'] = df['op_align'].astype('category')

        return df


    @staticmethod
    def rename_stand_type(df: pd.DataFrame) -> pd.DataFrame:
        """ Renames the 'stand_type' column by mapping Roman numerals 
            to integers and cleaning the string values. """
        mapping = {'I':'A','II':'B','III':'C','IV':'D','V':'E','VI':'F','VII':'G'}

        df = df.copy()
    
        df['stand_type'] = (
            df['stand_type']
                .astype('string')
                .str.upper()
                .str.replace('KROSNO ', '', regex=False)
                .map(mapping)
                .fillna(df['stand_type'])
                .astype('category')
            )

        return df


    @staticmethod
    def drop_invalid_op(df: pd.DataFrame) -> pd.DataFrame:
        """ Drops rows with invalid 'op' values. """
        invalid_op_mask = (df['op_align'].isin(['S'])) & (df['op_w'] != df['op_l'])

        df = df[~invalid_op_mask].copy()

        return df