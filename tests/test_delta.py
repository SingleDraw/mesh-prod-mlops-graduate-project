print(
    "Run this test before submitting pipeline, ",
    "to verify that pkg versions are compatible ",
    "and that the DeltaTable can be read successfully ",
    "in the test-delta-env environment. ",
    "If this test fails, the pipeline will fail too, so fix it here first!"
)

import subprocess, sys
subprocess.run([sys.executable, "-m", "pip", "install", "setuptools"], check=True)
import mltable

print("MLTable imported successfully!")