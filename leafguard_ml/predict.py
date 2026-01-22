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
def get_class_names():
    """
    Creates a temporary generator to retrieve the class-to-index mapping
    that was established during model training.
    """
    try:
        # Accessing ImageDataGenerator through tf.keras.preprocessing (works but is deprecated)
        temp_gen = tf.keras.preprocessing.image.ImageDataGenerator(rescale=1./255)
        
        train_data = temp_gen.flow_from_directory(
            os.path.join(DATA_DIR, "train"),
            target_size=(IMG_SIZE, IMG_SIZE),
            batch_size=1,
            class_mode='categorical',
            shuffle=False
        )
        
        class_indices = train_data.class_indices
        idx_to_class = {v: k for k, v in class_indices.items()}
        class_names = [idx_to_class[i] for i in range(len(idx_to_class))]
        
        return class_names
    
    except Exception as e:
        print(f"Error retrieving class names from {os.path.join(DATA_DIR, 'train')}: {e}")
        print("Ensure 'data/splits/train' exists and contains class folders.")
        return None