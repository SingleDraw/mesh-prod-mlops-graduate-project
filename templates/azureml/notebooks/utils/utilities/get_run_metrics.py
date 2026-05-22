# get_run_metrics.py
from mlflow.tracking import MlflowClient

def get_latest_metrics_for_run(
        run_name="baseline_model", 
        experiment_name="Production Time Prediction",
        client=MlflowClient(),
        verbose=True
    ):

    runs = client.search_runs(
        experiment_ids=[client.get_experiment_by_name(experiment_name).experiment_id],
        filter_string=f"tags.mlflow.runName = '{run_name}'",
        order_by=["start_time DESC"],
        max_results=1
    )

    if runs:
        # print(runs[0].data)
        metrics_lower = {k.lower(): v for k, v in runs[0].data.metrics.items()}
        required_metrics = ['rmse', 'mae', 'r2']
        if all(metric in metrics_lower for metric in required_metrics):
            latest_rmse = metrics_lower['rmse']
            latest_mae = metrics_lower['mae']
            latest_r2 = metrics_lower['r2']
            
            if verbose:
                print(f"\nLatest run of '{run_name}' metrics:\n{50*'-'}")
                print(f"Best RMSE: {latest_rmse}")
                print(f"Best MAE: {latest_mae}")
                print(f"Best R2: {latest_r2}")
                print(f"Model parameters:")
                for param, value in runs[0].data.params.items():
                    print(f"  {param}: {value}")

            return latest_rmse, latest_mae, latest_r2, runs[0].data.params
        else:
            print(f"Metrics 'RMSE', 'MAE', or 'R2' not found in the latest run of '{run_name}'.")
    else:
        print(f"No runs found in the '{experiment_name}' experiment.")

    return None, None, None