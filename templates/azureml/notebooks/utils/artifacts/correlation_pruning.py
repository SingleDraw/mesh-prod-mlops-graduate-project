# correlation_pruning.py
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.utils.validation import check_is_fitted
import numpy as np

class CorrPruning(BaseEstimator, TransformerMixin):
    def __init__(self, threshold=None):
        if threshold is not None and (threshold <= 0 or threshold >= 1):
            raise ValueError("Threshold must be in the range (0, 1) or None.")
        self.threshold = threshold


    def fit(self, X, y=None):

        self.feature_names_ = (
            np.array(X.columns if hasattr(X, 'columns') 
            else [f"feature_{i}" for i in range(X.shape[1])])
        )
        
        uncorrelated_mask = self._get_uncorrelated_features_mask(X)

        self.selected_names_ = self.feature_names_[uncorrelated_mask]

        self.selected_idx_ = np.where(uncorrelated_mask)[0]

        return self


    def _get_uncorrelated_features_mask(self, X):
        X_arr = np.asarray(X)

        uncorrelated_mask = np.ones(X_arr.shape[1], dtype=bool)

        if self.threshold is None or self.threshold == 0 or self.threshold == 1:
            self.selected_names_ = self.feature_names_
            self.selected_idx_ = np.arange(X_arr.shape[1])
            return uncorrelated_mask

        with np.errstate(divide='ignore', invalid='ignore'):
            corr_matrix = np.abs(np.corrcoef(X_arr, rowvar=False))
        
        corr_matrix = np.nan_to_num(corr_matrix, nan=1.0)

        # upper_tri = np.triu(np.ones(corr_matrix.shape), k=1).astype(bool)

        to_drop = set()

        for col_idx in range(corr_matrix.shape[1]):
            if col_idx in to_drop:
                continue  # already marked for dropping

            high_corr_indices = np.where(
                (corr_matrix[col_idx, :] > self.threshold) & 
                (np.arange(corr_matrix.shape[1]) > col_idx)
            )[0]
            
            for idx in high_corr_indices:
                to_drop.add(idx)

        uncorrelated_mask[list(to_drop)] = False

        return uncorrelated_mask


    def transform(self, X):
        check_is_fitted(self, "selected_idx_")
        X_filtered = np.asarray(X) if not isinstance(X, np.ndarray) else X
        return X_filtered[:, self.selected_idx_] # fast boolean masking


    def get_feature_names_out(self, input_features=None):
        check_is_fitted(self, "selected_names_")
        return self.selected_names_