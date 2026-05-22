# adaptive_budget.py
from collections import defaultdict
import numpy as np

class AdaptiveOptunaBudget:
    def __init__(
            self, 
            base_trials=20, 
            patience=15, 
            min_improve=1e-3,
            ascending=False
            ):
        self.base_trials = base_trials
        self.patience = patience
        self.min_improve = min_improve
        self.ascending = ascending

        self.best_score = defaultdict(
            lambda: np.inf if not self.ascending else -np.inf
        )
        self.no_improve = defaultdict(int)
        self.trials_done = defaultdict(int)

    def update(self, cfg_key, score):

        self.trials_done[cfg_key] += 1

        prev_best = self.best_score[cfg_key]

        if (
            not self.ascending and score < prev_best - self.min_improve
        ) or (
            self.ascending and score > prev_best + self.min_improve
        ):
            self.best_score[cfg_key] = score
            self.no_improve[cfg_key] = 0
        else:
            self.no_improve[cfg_key] += 1

    def should_stop(self, cfg_key):

        if self.trials_done[cfg_key] < self.base_trials:
            return False

        return self.no_improve[cfg_key] >= self.patience