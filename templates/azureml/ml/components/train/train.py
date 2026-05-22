import argparse
import os
import pandas as pd
import joblib
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import ElasticNet
import mlflow

# pipeline step imports
from sklearn.compose import ColumnTransformer, make_column_selector 
from sklearn.mixture import GaussianMixture
from sklearn.preprocessing import PolynomialFeatures, OneHotEncoder, StandardScaler, FunctionTransformer, QuantileTransformer
from sklearn.pipeline import Pipeline
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.feature_selection import SelectKBest, f_regression
from sklearn.utils.validation import check_is_fitted

import numpy as np

# ========== Argument parsing ===========
parser = argparse.ArgumentParser()
parser.add_argument("--X_train",      type=str,   required=True)
parser.add_argument("--y_train",      type=str,   required=True)
parser.add_argument("--alpha",        type=float, required=True)
parser.add_argument("--l1_ratio",     type=float, required=True)
parser.add_argument("--random_state", type=int,   required=True)
parser.add_argument("--n_components", type=int,   required=True)
parser.add_argument("--soft_clusters",    type=lambda x: x.lower() == 'true', required=True)
parser.add_argument("--poly_degree",  type=int, required=True)
parser.add_argument("--corr_threshold", type=float, required=True)
parser.add_argument("--k_best", type=int, required=True)
parser.add_argument("--model_output", type=str,   required=True)
args = parser.parse_args()

# =========================
# LOAD TRAINING DATA
# =========================
X_train = pd.read_parquet(os.path.join(args.X_train, "X_train.parquet"))
y_train = pd.read_parquet(os.path.join(args.y_train, "y_train.parquet")).squeeze()

print(f"X_train shape: {X_train.shape}")
print(f"y_train shape: {y_train.shape}")
print(f"Hyperparams  : alpha={args.alpha}  l1_ratio={args.l1_ratio}  random_state={args.random_state}  n_components={args.n_components}  soft_clusters={args.soft_clusters}  poly_degree={args.poly_degree}  corr_threshold={args.corr_threshold}  k_best={args.k_best}")

# =========================
# DEFINE PIPELINE STEPS
# =========================

class FeatureCreator(BaseEstimator, TransformerMixin):

    def __init__(self, density_steel=7850, mat_allowance=600):
        self.density_steel = density_steel
        self.mat_allowance = mat_allowance
    
    def fit(self, X, y=None):
        self.required_columns_ = ['op_align', 'op_w', 'op_l', 'batch_length', 'batch_width', 'wire_dia']

        missing = [c for c in self.required_columns_ if c not in X.columns]

        if missing:
            raise ValueError(f"Missing columns: {missing}")
        
        self.feature_names_in_ = np.array(X.columns, dtype=object)

        self.n_features_in_ = len(self.feature_names_in_)
        return self
    
    
    def transform(self, X):
        X = X.copy()

        mask = X['op_align'].isin(['A', 'S'])

        X['warp_wire_count'] = np.ceil(X['batch_width'] / ( X['wire_dia'] +  np.where(mask, X['op_l'], X['op_w']) ))
        X['weft_wire_count'] = np.ceil((X['batch_length'] - self.mat_allowance) / ( X['wire_dia'] + np.where(mask, X['op_w'], X['op_l']) ))

        X['cross_section_count'] = X['warp_wire_count'] * X['weft_wire_count']
        X['wire_weight_per_meter'] = 1 * (X['wire_dia'] / 1000) ** 2 * np.pi / 4 * self.density_steel
        X['batch_area'] = (X['batch_length'] / 1000) * (X['batch_width'] / 1000)
        X['batch_volume'] = X['batch_area'] * (X['wire_dia'] / 1000)

        return X
    
    def get_feature_names_out(self, input_features=None):
        if input_features is None:
            input_features = self.feature_names_in_
        
        new_features = [
            'warp_wire_count', 'weft_wire_count', 'cross_section_count', 
            'wire_weight_per_meter', 'batch_area', 'batch_volume'
        ]
        # return numpy array of type object (standard in sklearn)
        return np.concatenate([input_features, new_features])


preprocessor = ColumnTransformer(
    transformers=[
        (
            "cat", 
            OneHotEncoder(
                handle_unknown="ignore", 
                sparse_output=False
            ), 
            # cat_cols
            make_column_selector(dtype_include=['category', 'object'])
        ), 
        (
            "num", 
            StandardScaler(), 
            make_column_selector(dtype_include='number')
        )
    ], 
    verbose_feature_names_out=False
)

# GMM wrapper
class GMMClusterer(BaseEstimator):
    def __init__(self, n_components=6, random_state=42, max_iter=1000, **kwargs):
        """Wrapper class for GaussianMixture to be used in a pipeline.
        If soft_clusters is True, predict_proba will be used to get cluster probabilities as features.
        If False, predict will be used to get hard cluster labels."""

        self.soft_clusters = kwargs.pop('soft_clusters', False)
        self.n_components = n_components
        self.random_state = random_state
        self.max_iter = max_iter
        self.kwargs = kwargs

    def fit(self, X, y=None):
        self.clusterer = GaussianMixture(
            n_components=self.n_components,
            random_state=self.random_state,
            max_iter=self.max_iter,
            **self.kwargs
        )
        
        if self.soft_clusters:
            self.labels_ = self.clusterer.fit(X).predict_proba(X)
        else:
            self.labels_ = self.clusterer.fit_predict(X)
       
        return self

    def predict(self, X):
        if self.soft_clusters:
            return self.clusterer.predict_proba(X)
        return self.clusterer.predict(X)


# Transformer to add cluster features
class ClusterFeatureAdder(BaseEstimator, TransformerMixin):
    def __init__(self, clusterer, ohe=None):
        """Clusterer Feature Adder wrapper class for adding GMM cluster features to the dataset.
        If ohe is provided, it will be used to one-hot encode hard cluster labels.
        For soft clusters, the cluster probabilities will be added directly as features."""

        self.clusterer = clusterer
        self.ohe = ohe if not self.clusterer.soft_clusters else None  # OHE only for hard clusters

    def fit(self, X, y=None):
        if hasattr(X, 'columns'):
            # if DataFrame, store column names
            self.feature_names_in_ = np.array(X.columns, dtype=object)
        else:
            # if NumPy, create generic names (x0, x1, ...)
            self.feature_names_in_ = np.array(
                [f"x{i}" for i in range(X.shape[1])], 
                dtype=object
            )

        X_converted = self.get_X_converted(X)

        self.clusterer.fit(X_converted)

        if hasattr(self.clusterer, 'labels_'):
            clusters = self.clusterer.labels_
        else:
            clusters = self.clusterer.predict(X_converted)

        if self.ohe is not None:
            clusters = self.ohe.fit_transform(clusters.reshape(-1, 1))

        self.is_fitted_ = True # IMPORTANT!

        return self


    def transform(self, X):
        # return X
        X_converted = self.get_X_converted(X)
        
        clusters = self.clusterer.predict(X_converted)
        if self.ohe is not None:
            clusters = self.ohe.transform(clusters.reshape(-1, 1))

        return np.column_stack([X, clusters])
    

    def get_feature_names_out(self, input_features=None):
        if input_features is None:
            input_features = self.feature_names_in_
        
        # if ohe set (hard clusters, ohe)
        if self.ohe is not None:
            ohe_feature_names = self.ohe.get_feature_names_out(["cluster_id"])
            return np.append(input_features, ohe_feature_names)
        
        # if soft clusters, add one feature per cluster
        if self.clusterer.soft_clusters:
            cluster_feature_names = [
                f"cluster_{i}" for i in range(self.clusterer.n_components)
            ]
            return np.append(input_features, cluster_feature_names)

        # hard clusters, no ohe (single cluster_id feature)
        return np.append(input_features, "cluster_id")
    

    def get_X_converted(self, X):
        """ Helper method to convert X to NumPy array 
            if it's a DataFrame, ensuring it's contiguous 
            and of type float32. """
        return np.ascontiguousarray(
            X.to_numpy() 
            if hasattr(X, 'to_numpy') 
            else X, dtype=np.float32
        )
    

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
    


feature_creation_step = FeatureCreator()


steps = [
    ('feature_creation', feature_creation_step),
    ('preprocess', preprocessor),
]

steps.append(('cluster_feat', ClusterFeatureAdder(
    GMMClusterer(
        n_components=args.n_components,
        random_state=args.random_state,
        max_iter=5000,
        reg_covar=1e-3,
        soft_clusters=args.soft_clusters
    ),
    ohe=OneHotEncoder(
        sparse_output=False, 
        handle_unknown='ignore'
    )
)))


steps.append(('poly_select', PolynomialFeatures(
    degree=args.poly_degree,
    interaction_only=False, 
    include_bias=False
)))

steps.append(('corr_prune', CorrPruning(
    threshold=args.corr_threshold
)))

steps.append(('kbest_select', KBestPruning(
    k=args.k_best
)))

steps.append(('scaler', StandardScaler()))

steps.append(('regressor', 
    ElasticNet(
        alpha=args.alpha,
        l1_ratio=args.l1_ratio,
        max_iter=50000,
        random_state=args.random_state,
        tol=1e-3
    )
))

# ========================
# BUILD & FIT PIPELINE
# ========================
sklearn_pipeline = Pipeline(steps=steps)

sklearn_pipeline.fit(X_train, y_train)
print("Training complete.")
print(f"  Coefficients (first 10): {sklearn_pipeline.named_steps['regressor'].coef_[:10]}")
print(f"  Intercept:               {sklearn_pipeline.named_steps['regressor'].intercept_}")

# ========================
# SAVE MODEL
# ========================
os.makedirs(args.model_output, exist_ok=True)
model_path = os.path.join(args.model_output, "model.joblib")
joblib.dump(sklearn_pipeline, model_path)
print(f"Model saved → {model_path}")

# ========================
# LOG MODEL TO MLflow
# ========================
mlflow.sklearn.log_model(sklearn_pipeline, "model")