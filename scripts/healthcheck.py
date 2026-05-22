import requests
import os
import sys
import time
import statistics

SCORING_URI = os.environ["SCORING_URI"]
API_KEY = os.environ["API_KEY"]

HEADERS = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json",
    "azureml-model-deployment": "green",  # force green
}

PAYLOAD = {"data": [[5.1, 3.5, 1.4, 0.2]]}

SAMPLES = 20
MAX_LATENCY_MS = 500
MAX_ERROR_RATE = 0.05

latencies = []
errors = 0

for _ in range(SAMPLES):
    start = time.time()
    try:
        r = requests.post(SCORING_URI, json=PAYLOAD, headers=HEADERS, timeout=5)
        latency = (time.time() - start) * 1000
        latencies.append(latency)

        if r.status_code != 200:
            errors += 1
    except Exception:
        errors += 1

avg_latency = statistics.mean(latencies) if latencies else 9999
error_rate = errors / SAMPLES

print(f"avg_latency={avg_latency:.2f}ms error_rate={error_rate:.2%}")

if avg_latency > MAX_LATENCY_MS or error_rate > MAX_ERROR_RATE:
    print("[x] health check failed")
    sys.exit(1)

print("[v] health check passed")