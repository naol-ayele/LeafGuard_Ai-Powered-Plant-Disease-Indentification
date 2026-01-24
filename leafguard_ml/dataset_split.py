import os
import random
import shutil
from PIL import Image

# --- CONFIGURATION ---
# IMPORTANT: You must change this path to point to the actual folder
# that contains the disease/class folders.
# Based on your output, this is likely one of the subfolders inside plantVillage.
# CHOOSE ONE:
# RAW_DIR = "data/raw/plantVillage/grayscale"
RAW_DIR = "data/raw/plantVillage/color" # <-- Set this to the version you want to use

SPLIT_DIR = "data/splits"

TRAIN_P = 0.75
VAL_P = 0.15
# ---------------------

def remove_corrupted():
    print("Checking for corrupted images...")
    bad = []

    # Note: os.walk will correctly handle the new RAW_DIR structure
    for root, _, files in os.walk(RAW_DIR):
        for f in files:
            # Check for common image extensions
            if not f.lower().endswith(("png", "jpg", "jpeg")):
                continue

            path = os.path.join(root, f)
            try:
                # Use PIL to open and verify the image file integrity
                img = Image.open(path)
                img.verify()
            except:
                # If verification fails, add to the list and remove the file
                bad.append(path)
                os.remove(path)

    print(f"Removed corrupted: {len(bad)}")
def split_dataset():
    print(f"\nStarting split from directory: {RAW_DIR}")
    
    # Clean up the previous splits directory before starting
    if os.path.exists(SPLIT_DIR):
        print(f"Removing existing split directory: {SPLIT_DIR}")
        shutil.rmtree(SPLIT_DIR)

    # Ensure base split directories exist
    for s in ["train", "val", "test"]:
        os.makedirs(os.path.join(SPLIT_DIR, s), exist_ok=True)