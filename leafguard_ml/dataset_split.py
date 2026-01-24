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
