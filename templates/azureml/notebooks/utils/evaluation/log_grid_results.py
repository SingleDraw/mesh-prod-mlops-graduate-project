import pandas as pd
import mlflow
import mlflow.sklearn
import sklearn.pipeline

def log_grid_results(grid_search, run_name="Baseline Model", model_name="baseline_model", serialization_format="pickle"):
    best_idx = grid_search.best_index_
    results = grid_search.cv_results_

    rows = []

    # get best model from grid search (handle case when it's wrapped in a pipeline)
    best_model_step = grid_search.best_estimator_
    if isinstance(best_model_step, sklearn.pipeline.Pipeline):
        best_model_step = best_model_step._final_estimator

    # logging to MLflow
    with mlflow.start_run(run_name=run_name):
        # params
        mlflow.log_param("model_class", type(best_model_step).__name__)

        # Remove parameters that are class objects
        clean_params = {k: v for k, v in grid_search.best_params_.items() 
                        if not hasattr(v, "fit")} 
        mlflow.log_params(clean_params)

        # metrics
        for metric_name in ["RMSE", "MAE", "R2"]:
            row = {"metric": metric_name}
            sign = -1 if metric_name in ["RMSE", "MAE"] else 1

            mean_value = sign * results[f"mean_test_{metric_name}"][best_idx]
            row["mean_cv"] = round(mean_value, 4)
            mlflow.log_metric(f"{metric_name}_mean_cv", row["mean_cv"])

            for fold_idx in range(grid_search.cv):
                value = sign * results[f"split{fold_idx}_test_{metric_name}"][best_idx]
                row[f"fold_{fold_idx + 1}"] = round(value, 4)
                mlflow.log_metric(f"{metric_name}_fold_{fold_idx + 1}", row[f"fold_{fold_idx + 1}"])

            rows.append(row)

        # model artifact
        mlflow.sklearn.log_model(
            grid_search.best_estimator_, 
            name=model_name,
            serialization_format=serialization_format
        )

        print(f"Logged baseline model and metrics to MLflow with run ID: {mlflow.last_active_run().info.run_id}")
        print("""
        To load the model later:
        mlflow.sklearn.load_model('runs:/{mlflow.last_active_run().info.run_id}/"""+f"{model_name}')")

    df = pd.DataFrame(rows)
    params_df = pd.DataFrame({
        "model_class": [type(best_model_step).__name__],
        "params": [str(grid_search.best_params_)]
    }).T.rename(columns={0: ""})

    return df, params_df
