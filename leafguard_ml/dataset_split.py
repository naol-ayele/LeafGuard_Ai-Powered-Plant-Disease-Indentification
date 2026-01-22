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


def split_dataset():
    print(f"\nStarting split from directory: {RAW_DIR}")
    

    if os.path.exists(SPLIT_DIR):
        print(f"Removing existing split directory: {SPLIT_DIR}")
        shutil.rmtree(SPLIT_DIR)


    for s in ["train", "val", "test"]:
        os.makedirs(os.path.join(SPLIT_DIR, s), exist_ok=True)

    for cls in os.listdir(RAW_DIR):
        cls_path = os.path.join(RAW_DIR, cls)
        
        if not os.path.isdir(cls_path):
            continue

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

        n_train = int(total * TRAIN_P)
        n_val = int(total * VAL_P)

        train_files = images[:n_train]
        val_files = images[n_train:n_train+n_val]
        test_files = images[n_train+n_val:] 

        for split_name, file_set in [
            ("train", train_files),
            ("val", val_files),
            ("test", test_files),
        ]:
            out_dir = os.path.join(SPLIT_DIR, split_name, cls)
            os.makedirs(out_dir, exist_ok=True)
            
        
            for f in file_set:
                shutil.copy2(f, out_dir)

        print(f"Class {cls}: train={len(train_files)}, val={len(val_files)}, test={len(test_files)}")


if __name__ == "__main__":
    remove_corrupted()
    split_dataset()
    print("\nDataset processing completed.")