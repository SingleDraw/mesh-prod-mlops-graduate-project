import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
from sklearn.base import BaseEstimator

class ModelDiagnostics:

    @staticmethod
    def plot_parity_residuals(
            model: BaseEstimator, 
            X_test: pd.DataFrame, 
            y_test: pd.Series,
            scale: float = 0.25) -> None:
        
        y_pred = model.predict(X_test)

        residuals = y_test - y_pred

        fig, (ax1, ax2, ax3) = plt.subplots(1, 3, figsize=(18, 6))

        # Plot 1: Parity Plot
        sns.scatterplot(x=y_test, y=y_pred, alpha=0.5, ax=ax1)
        ax1.plot([y_test.min(), y_test.max()], [y_test.min(), y_test.max()], 'r--', lw=2)
        ax1.set_title('Parity Plot')
        ax1.set_xlabel('Actual y')
        ax1.set_ylabel('Predicted y')

        # Plot 2: Zoomed Parity Plot
        mask = y_test < (y_test.max() * scale)

        y_test_filtered = y_test[mask]
        y_pred_filtered = y_pred[mask]

        sns.scatterplot(x=y_test_filtered, y=y_pred_filtered, alpha=0.5, ax=ax2)
        ax2.plot([y_test.min(), y_test.max() * scale], [y_test.min(), y_test.max() * scale], 'r--', lw=2)
        ax2.set_title(f'Zoomed Parity Plot ({1/scale:.0f}x)')
        ax2.set_xlabel('Actual y')
        ax2.set_ylabel('Predicted y')

        # Plot 3: Residuals Plot
        sns.scatterplot(x=y_pred, y=residuals, alpha=0.5, ax=ax3)
        ax3.axhline(y=0, color='r', linestyle='--')
        ax3.set_title('Residuals Plot')
        ax3.set_xlabel('Predicted y')
        ax3.set_ylabel('Error (Actual - Predicted)')

        plt.tight_layout()
        plt.show()