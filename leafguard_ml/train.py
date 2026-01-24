import os
import numpy as np
import tensorflow as tf

# ===============================
# GLOBAL SETTINGS
# ===============================
DATA_DIR = "data/splits"
IMG_SIZE = 224
BATCH_SIZE = 32
EPOCHS = 30
MODEL_PATH = "model.h5"
TFLITE_PATH = "model_quantized.tflite"

AUTOTUNE = tf.data.AUTOTUNE
tf.keras.backend.clear_session()

# ===============================
# 1. DATA AUGMENTATION
# ===============================
# MobileNetV2 expects inputs scaled to [-1, 1]
preprocess_fn = tf.keras.applications.mobilenet_v2.preprocess_input

train_gen = tf.keras.preprocessing.image.ImageDataGenerator(
    preprocessing_function=preprocess_fn,
    rotation_range=30,
    width_shift_range=0.2,
    height_shift_range=0.2,
    brightness_range=[0.8, 1.2],
    zoom_range=0.2,
    horizontal_flip=True,
    fill_mode="nearest"
)

val_gen = tf.keras.preprocessing.image.ImageDataGenerator(
    preprocessing_function=preprocess_fn
)

train_data = train_gen.flow_from_directory(
    os.path.join(DATA_DIR, "train"),
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode="categorical",
    shuffle=True
)

val_data = val_gen.flow_from_directory(
    os.path.join(DATA_DIR, "val"),
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode="categorical",
    shuffle=False
)

NUM_CLASSES = train_data.num_classes

# ===============================
# 2. MODEL BUILDING
# ===============================
base_model = tf.keras.applications.MobileNetV2(
    weights="imagenet",
    include_top=False,
    input_shape=(IMG_SIZE, IMG_SIZE, 3)
)

base_model.trainable = False  # Phase 1 freeze

x = base_model.output
x = tf.keras.layers.GlobalAveragePooling2D()(x)
x = tf.keras.layers.BatchNormalization()(x)  # Stability improvement
x = tf.keras.layers.Dropout(0.3)(x)
outputs = tf.keras.layers.Dense(NUM_CLASSES, activation="softmax")(x)

model = tf.keras.Model(inputs=base_model.input, outputs=outputs)

model.compile(
    optimizer=tf.keras.optimizers.Adam(),
    loss="categorical_crossentropy",
    metrics=["accuracy"]
)

# ===============================
# 3. CALLBACKS
# ===============================
early_stop = tf.keras.callbacks.EarlyStopping(
    monitor="val_loss",
    patience=5,
    restore_best_weights=True
)

# ===============================
# 4. TRAINING – PHASE 1
# ===============================
print("\n--- Phase 1: Training Top Layers ---\n")
model.fit(
    train_data,
    validation_data=val_data,
    epochs=10,
    callbacks=[early_stop],
    workers=4,
    use_multiprocessing=True
)

# ===============================
# 5. FINE-TUNING – PHASE 2
# ===============================
print("\n--- Phase 2: Fine-Tuning ---\n")

base_model.trainable = True

# Freeze everything except last 20 layers
for layer in base_model.layers[:-20]:
    layer.trainable = False

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5),
    loss="categorical_crossentropy",
    metrics=["accuracy"]
)

model.fit(
    train_data,
    validation_data=val_data,
    epochs=EPOCHS,
    callbacks=[early_stop],
    workers=4,
    use_multiprocessing=True
)

# ===============================
# 6. SAVE MODEL
# ===============================
model.save(MODEL_PATH)
print(f"✅ Model saved: {MODEL_PATH}")

# ===============================
# 7. TFLITE INT8 CONVERSION
# ===============================
def representative_dataset():
    """
    Uses real training images for proper INT8 calibration
    """
    for _ in range(20):  # 100 total samples
        images, _ = next(train_data)
        for i in range(min(5, len(images))):
            yield [images[i:i+1].astype(np.float32)]

converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.representative_dataset = representative_dataset

converter.target_spec.supported_ops = [
    tf.lite.OpsSet.TFLITE_BUILTINS_INT8
]

converter.inference_input_type = tf.uint8
converter.inference_output_type = tf.uint8

tflite_model = converter.convert()

with open(TFLITE_PATH, "wb") as f:
    f.write(tflite_model)

print(f"🚀 Mobile-optimized TFLite model saved: {TFLITE_PATH}")
