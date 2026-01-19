import os
import numpy as np
import tensorflow as tf

# Settings
DATA_DIR = "data/splits"
IMG_SIZE = 224
BATCH_SIZE = 32
EPOCHS = 30  # Increased, but EarlyStopping will prevent overfitting
MODEL_PATH = "model.h5"
TFLITE_PATH = "model_quantized.tflite"

# 1. ENHANCED DATA AUGMENTATION
# Added brightness and shift to handle real-world camera variations
train_gen = tf.keras.preprocessing.image.ImageDataGenerator(
    rescale=1./255,
    rotation_range=30,
    width_shift_range=0.2,
    height_shift_range=0.2,
    brightness_range=[0.8, 1.2], # CRITICAL: Simulates different lighting
    zoom_range=0.2,
    horizontal_flip=True,
    fill_mode='nearest'
)

val_gen = tf.keras.preprocessing.image.ImageDataGenerator(rescale=1./255)

train_data = train_gen.flow_from_directory(
    os.path.join(DATA_DIR, "train"),
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='categorical'
)

val_data = val_gen.flow_from_directory(
    os.path.join(DATA_DIR, "val"),
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='categorical'
)

# 2. BUILD MODEL WITH FINE-TUNING
base_model = tf.keras.applications.MobileNetV2(
    weights="imagenet", 
    include_top=False, 
    input_shape=(IMG_SIZE, IMG_SIZE, 3)
)

# Initially freeze the base
base_model.trainable = False 

x = base_model.output
x = tf.keras.layers.GlobalAveragePooling2D()(x)
x = tf.keras.layers.Dropout(0.3)(x) # Increased dropout to fight overfitting
x = tf.keras.layers.Dense(train_data.num_classes, activation="softmax")(x)

model = tf.keras.models.Model(inputs=base_model.input, outputs=x)

model.compile(optimizer='adam',
              loss='categorical_crossentropy',
              metrics=['accuracy'])

# 3. EARLY STOPPING
# Stops training if the validation loss doesn't improve for 5 epochs
early_stop = tf.keras.callbacks.EarlyStopping(
    monitor='val_loss',
    patience=5,
    restore_best_weights=True
)

print("--- Phase 1: Training Top Layers ---")
model.fit(
    train_data,
    validation_data=val_data,
    epochs=10,
    callbacks=[early_stop]
)

# 4. FINE-TUNING PHASE
# Unfreeze the last few layers of MobileNetV2 to adapt to leaf textures
print("--- Phase 2: Fine-Tuning ---")
base_model.trainable = True
# Freeze all layers except the last 20
for layer in base_model.layers[:-20]:
    layer.trainable = False

# Recompile with a very low learning rate
model.compile(optimizer=tf.keras.optimizers.Adam(1e-5),
              loss='categorical_crossentropy',
              metrics=['accuracy'])

model.fit(
    train_data,
    validation_data=val_data,
    epochs=EPOCHS,
    callbacks=[early_stop]
)

model.save(MODEL_PATH)
print(f"Model saved as {MODEL_PATH}")

def representative_dataset():
    for _ in range(20): # 20 batches * 5 images = 100 calibration images
        images, _ = next(train_data)
        for i in range(min(len(images), 5)):
            # The model expects [1, 224, 224, 3] float32 (0.0 to 1.0)
            yield [images[i:i+1].astype(np.float32)]

converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.representative_dataset = representative_dataset


converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
converter.inference_input_type = tf.uint8   # App sends 0-255
converter.inference_output_type = tf.uint8 # App receives 0-255

tflite_model = converter.convert()

with open(TFLITE_PATH, "wb") as f:
    f.write(tflite_model)

print(f"✅ Mobile-optimized model exported: {TFLITE_PATH}")