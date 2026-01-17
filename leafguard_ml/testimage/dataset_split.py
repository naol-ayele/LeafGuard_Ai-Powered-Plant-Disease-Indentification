import os
import random
import shutil
from PIL import Image
# configuration
RAW_DIR = "data/raw/plantVillage/color"
SPLIT_DIR = "data/splits"

TRAIN_P = 0.75
VAL_P = 0.15
# corrupted image detection
def remove_corrupted():
    print("Checking for corrupted images...")
    bad = []

    for root, _, files in os.walk(RAW_DIR):
        for f in files:
            if not f.lower().endswith(("png", "jpg", "jpeg")):
                continue

            path = os.path.join(root, f)
            try:
                img = Image.open(path)
                img.verify()
            except:
                bad.append(path)
                os.remove(path)

    print(f"Removed corrupted: {len(bad)}")
    