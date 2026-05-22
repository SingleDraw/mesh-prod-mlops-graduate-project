import urllib.request
import os

# Files in hadoop-3.3.5/bin from cdarlint/winutils
files = [
    "hadoop.dll",
    "hadoop.exp",
    "hadoop.lib",
    "hadoop.pdb",
    "libwinutils.lib",
    "winutils.exe",
    "winutils.pdb",
]

base_url = "https://github.com/cdarlint/winutils/raw/master/hadoop-3.3.5/bin/"
save_dir = r"C:\hadoop\bin"

os.makedirs(save_dir, exist_ok=True)

for fname in files:
    url = base_url + fname
    dest = os.path.join(save_dir, fname)
    print(f"Downloading {fname}...")
    urllib.request.urlretrieve(url, dest)
    print(f"  Saved to {dest}")

print("\nDone! All files downloaded.")