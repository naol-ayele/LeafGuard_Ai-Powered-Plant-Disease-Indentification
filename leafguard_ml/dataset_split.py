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
# Iterate over class folders (which are now directly inside RAW_DIR)
    for cls in os.listdir(RAW_DIR):
        cls_path = os.path.join(RAW_DIR, cls)
        
        # Skip if it's not a directory (e.g., skips files like .DS_Store)
        if not os.path.isdir(cls_path):
            continue

        # Collect all image files in the current class directory
        images = [
            os.path.join(cls_path, f)
            for f in os.listdir(cls_path)
            if f.lower().endswith(("png", "jpg", "jpeg"))
        ]

        if not images:
             print(f"Warning: Class '{cls}' has no images and will be skipped.")
             continue

        random.shuffle(images)
        total = len(images)

        # Calculate split sizes
        n_train = int(total * TRAIN_P)
        n_val = int(total * VAL_P)

        # Slice the list into the three sets
        train_files = images[:n_train]
        val_files = images[n_train:n_train+n_val]
        test_files = images[n_train+n_val:] # Remainder goes to test

        # Copy files to the respective split directories
        for split_name, file_set in [
            ("train", train_files),
            ("val", val_files),
            ("test", test_files),
        ]:
            # Create the destination folder: data/splits/train/ClassName
            out_dir = os.path.join(SPLIT_DIR, split_name, cls)
            os.makedirs(out_dir, exist_ok=True)
            
            # Copy all files in the set
            for f in file_set:
                shutil.copy2(f, out_dir)

        print(f"Class {cls}: train={len(train_files)}, val={len(val_files)}, test={len(test_files)}")
if __name__ == "__main__":
    remove_corrupted()
    split_dataset()
    print("\nDataset processing completed.")