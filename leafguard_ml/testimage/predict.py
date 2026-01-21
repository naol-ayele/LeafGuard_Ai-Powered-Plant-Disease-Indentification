import tensorflow as tf
import numpy as np
import os

DATA_DIR = "data/splits" 
IMG_SIZE = 224          
MODEL_PATH = "model.h5"
IMG_PATH = "testImage/corn_healthy.jpg"   
try:
    model = tf.keras.models.load_model(MODEL_PATH)
    print(f"Successfully loaded model from {MODEL_PATH}")
except Exception as e:
    print(f"Error loading model: {e}")
    exit()