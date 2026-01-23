
import tensorflow as tf
import numpy as np
import os

MODEL_PATH = "model.h5"
TFLITE_PATH = "model_quantized.tflite"
IMG_SIZE = 224

# 1. Load your trained Keras model
model = tf.keras.models.load_model(MODEL_PATH)

# --- NEW: Define your data source here ---
# Replace 'path/to/your/train_data' with the actual folder path
# or use a small validation folder.
datagen = tf.keras.preprocessing.image.ImageDataGenerator(rescale=1./255)
train_data = datagen.flow_from_directory(
    'data/testImage', # <--- UPDATE THIS PATH to your data
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=32,
    class_mode='categorical'
)

# 2. Improved Representative Dataset
def representative_dataset():
    # We loop through a few batches to provide variety
    for _ in range(20):
        try:
            images, _ = next(train_data)
            for img in images:
                # Provide one image at a time in the correct shape/type
                yield [img.reshape(1, IMG_SIZE, IMG_SIZE, 3).astype(np.float32)]
        except StopIteration:
            break

converter = tf.lite.TFLiteConverter.from_keras_model(model)

# 3. Optimization Settings
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.representative_dataset = representative_dataset

# 4. Force Full Integer Quantization
# Note: TFLITE_BUILTINS_INT8 ensures even the math is done in INT8
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
converter.inference_input_type = tf.uint8
converter.inference_output_type = tf.uint8

# 5. Convert and Save
tflite_model = converter.convert()
with open(TFLITE_PATH, "wb") as f:
    f.write(tflite_model)

print(f"✅ Accuracy-optimized TFLite model exported: {TFLITE_PATH}")