# kbest_features.py
from sklearn.feature_selection import SelectKBest, f_regression
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.utils.validation import check_is_fitted
import numpy as np
import pandas as pd

class KBestPruning(BaseEstimator, TransformerMixin):
    def __init__(self, k=15):
        self.k = k

    def fit(self, X, y=None):
        self.feature_names_ = (
            np.array(X.columns if hasattr(X, 'columns') 
            else [f"feature_{i}" for i in range(X.shape[1])])
        )

        self.selector_ = SelectKBest(
            score_func=f_regression, 
            k=min(self.k, X.shape[1])
        )
        self.selector_.fit(X, y)
        
        # map selected features back to original polynomial space
        filtered_support = self.selector_.get_support()
        
        # store names of selected features
        self.selected_names_ = self.feature_names_[filtered_support]
        
        # compile mapping and indices of selected features
        self.selected_idx_ = np.where(filtered_support)[0]
        
        return self


    def transform(self, X):
        check_is_fitted(self, "selected_idx_")
        # X_selected = X.values if isinstance(X, pd.DataFrame) else X
        X_selected = np.asarray(X) # ensure we have a numpy array for indexing
        return X_selected[:, self.selected_idx_]


    def get_feature_names_out(self, input_features=None):
        check_is_fitted(self, "selected_names_")
        return self.selected_names_
    