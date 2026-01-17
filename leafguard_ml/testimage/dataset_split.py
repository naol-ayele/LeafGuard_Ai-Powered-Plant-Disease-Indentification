import os
import random
import shutil
from PIL import Image
# configuration
RAW_DIR = "data/raw/plantVillage/color"
SPLIT_DIR = "data/splits"

TRAIN_P = 0.75
VAL_P = 0.15