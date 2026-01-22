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
def predict_image(img_path, class_names):
    """
    Loads, preprocesses, and predicts the class of a single image.
    """
    try:
        # 1. Load and Resize Image (using the updated access method)
        img = tf.keras.utils.load_img(img_path, target_size=(IMG_SIZE, IMG_SIZE))
        
        # 2. Convert to Array (using the updated access method)
        x = tf.keras.utils.img_to_array(img)
        
        # 3. Normalize (must match training normalization: 0-255 -> 0.0-1.0)
        x = x / 255.0
        
        # 4. Add Batch Dimension (1, H, W, C)
        x = np.expand_dims(x, axis=0)

        # 5. Predict
        preds = model.predict(x, verbose=0)
        
        # 6. Interpret Results
        class_index = np.argmax(preds)
        confidence = preds[0][class_index]
        
        predicted_class = class_names[class_index] if class_names else "Unknown Class (Mapping Failed)"
            
        print("-" * 40)
        print(f"✅ Prediction for {os.path.basename(img_path)}:")
        print(f"   Predicted Class: {predicted_class}")
        print(f"   Confidence: {confidence:.2f}")
        print(f"   Class Index: {class_index}")
        print("-" * 40)

    except FileNotFoundError:
        print(f"\nERROR: Image file not found at {img_path}. Please check IMG_PATH.")
    except Exception as e:
        print(f"\nAn error occurred during prediction: {e}")
if __name__ == "__main__":
    
    # Get the list of class names
    CLASS_NAMES = get_class_names()
    
    if CLASS_NAMES:
        print(f"Found {len(CLASS_NAMES)} classes: {CLASS_NAMES}")
        predict_image(IMG_PATH, CLASS_NAMES)