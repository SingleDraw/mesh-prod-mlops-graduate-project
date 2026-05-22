# optuna_study.py
import pandas as pd
import numpy as np
import warnings
from IPython.display import display, Markdown
from sklearn.model_selection import cross_validate
from sklearn.exceptions import ConvergenceWarning
import optuna
optuna.logging.set_verbosity(optuna.logging.WARNING)

warnings.filterwarnings("ignore", category=ConvergenceWarning)

class OptunaStudy:
    @staticmethod
    def cross_validate(
        trial, 
        model, 
        X_train, 
        y_train, 
        variance_penalty=True,  # True for optimizing stability
        ):
        try:

            # -------------------
            # CV 
            # -------------------
            scores = cross_validate(
                model, 
                X_train, y_train, 
                cv=5, 
                scoring={
                    'RMSE': 'neg_root_mean_squared_error', 
                    'MAE': 'neg_mean_absolute_error', 
                    'R^2': 'r2'
                },
                n_jobs=-1
            )

            # -------------------
            # METRIC CALCULATION
            # -------------------
            mean_rmse = -scores['test_RMSE'].mean()
            mean_mae = -scores['test_MAE'].mean()
            mean_r2 = scores['test_R^2'].mean()

            # std dev of RMSE across folds (for stability analysis)
            std_rmse = np.std(-scores['test_RMSE'])
            

            # -------------------
            # FIT ON SAMPLE
            # -------------------
            X_sample, y_sample = OptunaStudy._get_sample(X_train, y_train)
            model.fit(X_sample, y_sample)

            # -------------------
            # CONVERGENCE SIGNAL
            # -------------------
            converged, n_iter_max_ratio = OptunaStudy._get_convergence_signal(model)
            trial.set_user_attr("converged", bool(converged))
            trial.set_user_attr("n_iter_max_ratio", float(n_iter_max_ratio))

            # -------------------
            # CONDITION NUMBER
            # -------------------
            condition_number = OptunaStudy._get_cond_num(model, X_sample)
            trial.set_user_attr("condition_number", condition_number)

            # -------------------
            # OBJECTIVE 
            # -------------------
            is_quantile = hasattr(model[-1], "quantile") and model[-1].quantile is not None
            
            pinball = None
            coverage = None
            coverage_error = None
            if is_quantile:
                # For quantile regression, we want to minimize the pinball loss
                # which is asymmetric. We can use the mean absolute error as a proxy,
                # but we should also consider the quantile level.
                ql = model[-1].quantile
                y_pred = model.predict(X_sample)
                err = y_sample - y_pred

                pinball = np.mean(np.maximum(ql * err, (ql - 1) * err))
                coverage = np.mean(y_pred >= y_sample)
                coverage_error = abs(coverage - ql)

                score = pinball + 10.0 * coverage_error  # penalize coverage deviation
            else:
                # For standard regression, we want to minimize RMSE
                score = mean_rmse

            # --------------------
            # PENALTIES
            # --------------------
            # performance instability
            if variance_penalty:
                # penalize ill-conditioned transformations
                cv_penalty  = std_rmse / (mean_rmse + 1e-8)
                score *= (1 + cv_penalty)


            # Define safety thresholds for matrix conditioning
            MAX_SAFE_COND = 500.0

            # structural instability (orthogonal signal)
            if condition_number > MAX_SAFE_COND:
                # heavy penalty
                violation_magnitude = condition_number / MAX_SAFE_COND
                score += 10.0 * violation_magnitude
            else:
                # soft penalty
                cond_penalty = np.log10(condition_number + 1)
                score += 0.01 * cond_penalty

            # --------------------
            # LOGGING
            # --------------------
            # save additional metrics in "attributes" of the trial
            trial.set_user_attr("RMSE", mean_rmse)
            trial.set_user_attr("MAE", mean_mae)
            trial.set_user_attr("R2", mean_r2)
            trial.set_user_attr("RMSE_std", std_rmse)

            # save all fold scores for later analysis
            trial.set_user_attr("fold_RMSE", (-scores['test_RMSE']).tolist())
            trial.set_user_attr("fold_MAE", (-scores['test_MAE']).tolist())
            trial.set_user_attr("fold_R2", scores['test_R^2'].tolist())
            
            # save quantile regression specific metrics
            trial.set_user_attr("pinball_loss", pinball)
            trial.set_user_attr("coverage", coverage)
            trial.set_user_attr("coverage_error", coverage_error)


            return score
        
        except Exception as e:
            print(f"Trial failed with error: {e}")
            return float('inf')
    
    
    @staticmethod
    def _get_convergence_signal(model, step_name="regressor"):
        """ Helper method to check if the regressor converged 
            and how many iterations it took. """
        reg = model.named_steps[step_name]

        n_iter = getattr(reg, "n_iter_", None)
        max_iter = getattr(reg, "max_iter", None)

        # models without iterative optimization
        if n_iter is None or max_iter is None:
            return True, 0.0

        n_iter_arr = np.atleast_1d(n_iter)

        converged = np.all(n_iter_arr < max_iter)
        n_iter_max_ratio = np.mean(n_iter_arr / max_iter)

        return bool(converged), float(n_iter_max_ratio)


    @staticmethod
    def _get_cond_num(model, X_sample):
        """ Helper method to calculate the condition 
            number of the transformed feature space
            before the regressor. """
        if not hasattr(model[-1], "predict"):
            return 1.0  # if no regressor, return perfect condition number
        if not hasattr(model[:-1], "transform"):
            return 1.0  # if no transformations, return perfect condition number
        X_transformed = model[:-1].transform(X_sample)
        return np.linalg.cond(X_transformed)

    
    @staticmethod
    def _get_sample(X, y, n_samples=1000):
        """Helper method to get a deterministic sample of the data for fitting."""
        if isinstance(X, np.ndarray):
            X = pd.DataFrame(X)  # convert to DataFrame for consistent sampling
        X_sample = X.sample(n=min(n_samples, len(X)), random_state=42)
        y_sample = y.loc[X_sample.index]
        return X_sample, y_sample


    @staticmethod
    def display_optuna_results(mlflow, study, run_name="feature_engineering"):
        with mlflow.start_run(run_name=run_name) as run:     
            results_df = pd.DataFrame({
                'mean_scores': [
                    study.best_trial.user_attrs['RMSE'],
                    study.best_trial.user_attrs['MAE'], 
                    study.best_trial.user_attrs['R2']
                ]
            }, index=['RMSE', 'MAE', 'R2'])

            fold_scores_df = pd.DataFrame({
                'RMSE': study.best_trial.user_attrs['fold_RMSE'],
                'MAE': study.best_trial.user_attrs['fold_MAE'],
                'R2': study.best_trial.user_attrs['fold_R2']
            }, index=[f'Fold {i+1}' for i in range(5)])
            
            joined_df = pd.concat([results_df.T, fold_scores_df], axis=0)

            n_trials = len(study.trials)

            # log best hyperparameters and metrics to MLflow
            mlflow.log_params(study.best_trial.params)
            mlflow.log_metric("optuna_trials", n_trials)
            mlflow.log_metrics(results_df['mean_scores'].to_dict())
            # log fold scores as a table (optional, for detailed analysis)

            # fold_scores_df.round(4).to_parquet("__fold_scores.parquet")
            mlflow.log_table(fold_scores_df.round(4), artifact_file="fold_scores.parquet")
            # Path("__fold_scores.parquet").unlink()

            # name = run_name.replace("_", " ").replace(" c", " GMM").replace(" p", " Poly").title().capitalize()
            name = (
                f"Run: `{run_name}`, Trials: {n_trials}"
                    # .replace("_", " ")      
                    # .replace(" cr", " CorrPrune") 
                    # .replace(" kb", " KBestFilter")
                    # .replace(" vp", " VariancePenalty")            
                    # .replace(" c", " GMM")
                    # .replace(" p", " PolynomialFeatures")
                    # .title()
                    # .capitalize()
            )
            display(Markdown(f"> ### {run_name}"))
            display(Markdown(f"##### {name}"))
            display(joined_df.T.round(4))

            display(Markdown("### Best Hyperparameters:"))
            display(pd.DataFrame(study.best_params, index=["value"]).T)