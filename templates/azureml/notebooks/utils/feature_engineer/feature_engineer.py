import numpy as np
import pandas as pd
from sklearn.preprocessing import RobustScaler, OneHotEncoder

# NOTE: Not used in the current implementation.

class GoldFeatureEngineer:
    def __init__(self, config=None):
        self.config = config or {}
        self.scaler = RobustScaler()
        self.ohe = OneHotEncoder(sparse_output=False, handle_unknown='ignore')
        self.is_fitted = False

    def transform_skewed(self, df, cols):
        """Log-transform skewed features (e.g., op_w, wire_dia)"""
        df_copy = df.copy()
        for col in cols:
            # log1p to log(1 + x), which handles zero values gracefully
            df_copy[f'log_{col}'] = np.log1p(df_copy[col])
        return df_copy

    def create_domain_features(self, df):
        """Create domain-specific features and interactions"""
        df_copy = df.copy()
        # Example: batch area
        if 'batch_width' in df.columns and 'batch_length' in df.columns:
            df_copy['batch_area'] = df_copy['batch_width'] * df_copy['batch_length']
        
        # Example: interaction between op_w and wire_dia
        if 'op_w' in df.columns and 'wire_dia' in df.columns:
            df_copy['interaction_w_dia'] = df_copy['op_w'] * df_copy['wire_dia']
            
        return df_copy

    def fit(self, df, categorical_cols=['cluster_id'], numerical_cols=None):
        """Fit scalers and encoders (Only on TRAIN)"""
        # One-Hot Encoding for clusters
        self.ohe.fit(df[categorical_cols])
        
        # Scaling at the very end for all numerical features
        if numerical_cols:
            self.scaler.fit(df[numerical_cols])
        
        self.is_fitted = True
        return self

    def transform(self, df, numerical_cols, categorical_cols=['cluster_id']):
        """Final transformation (Train and Test)"""
        if not self.is_fitted:
            raise Exception("Call fit on training data first!")

        # One-Hot Encoding for clusters
        encoded_cats = self.ohe.transform(df[categorical_cols])
        cat_names = self.ohe.get_feature_names_out(categorical_cols)
        df_encoded = pd.DataFrame(encoded_cats, columns=cat_names, index=df.index)
        
        # Concatenation and scaling
        df_res = pd.concat([df[numerical_cols], df_encoded], axis=1)
        df_res[numerical_cols] = self.scaler.transform(df_res[numerical_cols])
        
        return df_res
