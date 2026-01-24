import tensorflow as tf
import numpy as np
import os

# ===============================
# SETTINGS
# ===============================
MODEL_PATH = "model.h5"
TFLITE_PATH = "model_quantized.tflite"
IMG_SIZE = 224
BATCH_SIZE = 32

tf.keras.backend.clear_session()

# ===============================
# 1. LOAD KERAS MODEL
# ===============================
model = tf.keras.models.load_model(MODEL_PATH)
print("✅ Keras model loaded")

# ===============================
# 2. DATA SOURCE FOR CALIBRATION
# ===============================
# NOTE: Keep rescale=1./255 because your model was trained that way
datagen = tf.keras.preprocessing.image.ImageDataGenerator(rescale=1.0 / 255)

train_data = datagen.flow_from_directory(
    "data/testImage",        # <-- your path
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode="categorical",
    shuffle=True
)

# ===============================
# 3. REPRESENTATIVE DATASET
# ===============================
def representative_dataset():
    """
    Provides real images for INT8 calibration.
    Uses multiple batches for better activation coverage.
    """
    for _ in range(20):  # ~20 batches
        images, _ = next(train_data)
        for i in range(min(len(images), 5)):
            # Model expects float32 input during calibration
            yield [images[i:i+1].astype(np.float32)]

# ===============================
# 4. TFLITE CONVERTER SETUP
# ===============================
converter = tf.lite.TFLiteConverter.from_keras_model(model)

# Enable optimizations
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.representative_dataset = representative_dataset

# Force FULL INT8 quantization
converter.target_spec.supported_ops = [
    tf.lite.OpsSet.TFLITE_BUILTINS_INT8
]

# App input/output (0–255)
converter.inference_input_type = tf.uint8
converter.inference_output_type = tf.uint8

# ===============================
# 5. CONVERT & SAVE
# ===============================
tflite_model = converter.convert()

with open(TFLITE_PATH, "wb") as f:
    f.write(tflite_model)

print(f"🚀 Accuracy-optimized INT8 TFLite model saved: {TFLITE_PATH}")
