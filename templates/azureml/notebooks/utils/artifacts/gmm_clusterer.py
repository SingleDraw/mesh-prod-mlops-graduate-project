# gmm_clusterer.py
from sklearn.mixture import GaussianMixture
from sklearn.base import BaseEstimator, TransformerMixin
import numpy as np

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
    