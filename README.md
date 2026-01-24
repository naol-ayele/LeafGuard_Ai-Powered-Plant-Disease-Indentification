
# LeafGuard: AI-Powered Plant Disease Identification

LeafGuard is an "Offline" mobile solution designed to empower farmers in remote areas. It utilizes an embedded **MobileNetV2 CNN** to diagnose crop diseases instantly without an internet connection, while providing a secure **Node.js/PostgreSQL** backend for cloud synchronization and data persistence.

## Key Features

- **Edge AI Inference:** Real-time diagnosis using TFLite (Under 500ms).
- **Offline-First:** No 4G/Wi-Fi required for core diagnostic features.
- **Secure Sync:** JWT-authorized synchronization of scan history.
- **Data Integrity:** ACID-compliant transactions and BCNF-normalized database.

---

## Tech Stack & Dependencies

### **Mobile (Client Tier)**

- **Framework:** Flutter (Dart)
- **AI Engine:** `tflite_flutter` (In-app neural network execution)
- **Local Storage:** `sqflite` (Local caching of scans)
- **Image Handling:** `image_picker` (Camera/Gallery access)

### **Backend (Logic Tier)**

- **Runtime:** Node.js (Express.js)
- **Security:** `jsonwebtoken` (Auth), `helmet` (Header hardening), `express-rate-limit` (DDoS protection)
- **Validation:** `joi` (Strict schema validation)
- **Database:** PostgreSQL (`pg` pool)

---

## Setup & Installation

LeafGuard is fully containerized to ensure environment consistency. We use **Docker Compose** for orchestration and **ngrok** for secure local-to-mobile tunneling.

### **1. Backend Setup (Dockerized)**

1. Navigate to the `/leafguard-backend` folder.
2. **Initialize the Environment:**

```bash
docker-compose up -d --build

```

_This command builds the Node.js image, pulls the PostgreSQL database, and starts the services in "detached" mode._ 3. **Monitor Logs:**

```bash
docker logs -f leafguard_api

```

### **2. Network Tunneling (ngrok)**

Since the mobile app runs on a physical device or emulator, it needs to reach your Dockerized backend.

1. Start an ngrok tunnel on the port your backend is running (e.g., 3000):

```bash
ngrok config add-authtoken 32qeqGIpJ.............

```

```bash
ngrok http 3000

```

2. **Important:** Copy the generated `https://...` URL. You will need this for the Mobile configuration.

### **3. Mobile Setup (Flutter)**

1. In the main project folder, install Flutter dependencies:

```bash
flutter pub get

```

2. **Configure API Endpoint:** Open your Flutter configuration file (e.g., `lib/constants.dart`) and paste your **ngrok URL** as the `BASE_URL`.
3. **Check AI Assets:** Ensure the quantized model is present at:
   `assets/models/plant_model.tflite`
4. **Launch the App:**

```bash
flutter run

```

---

## Dependency & Tooling Breakdown

### **1. Mobile Frontend (Flutter)**

The mobile suite is designed for high performance, local AI inference, and a polished user experience.

#### **Core Production Dependencies**

- **AI & ML:** `tflite_flutter` — Executes the quantized TFLite model locally on the device hardware.
- **Database:** `sqflite` & `path` — Provides a local SQLite engine for offline data persistence.
- **Localization:** `abushakir` & `easy_localization` — Supports the Ethiopian calendar and multi-language support.
- **Hardware:** `camera` & `image_picker` — Direct interface for leaf image capture.

#### **Dev Dependencies (Testing & Tooling)**

- **Testing:** `mockito`, `mocktail`, `sqflite_common_ffi` — Used for mocking database and API responses in Unit Tests to ensure logic reliability.
- **UX/UI:** `flutter_launcher_icons` & `flutter_native_splash` — Generates professional-grade app icons and splash screens.
- **Quality:** `flutter_lints` — Enforces strict, industry-standard coding conventions (Clean Code).
- **Automation:** `build_runner` — Automates the generation of necessary boilerplate code.

---

### **2. Backend & API (Node.js)**

The backend architecture focuses on **Defense-in-Depth** security, data integrity, and containerized scalability.

#### **Core Logic & Infrastructure**

- **`express`**: The primary web framework for our RESTful API.
- **`pg` (node-postgres)**: Enables the **ACID Transaction** logic for reliable PostgreSQL communication.
- **`multer`**: Handles the `multipart/form-data` required for uploading high-resolution leaf images.
- **`nodemailer`**: Automates critical notifications like password resets and health alerts.

#### **Security & Validation (Defense-in-Depth)**

- **`jsonwebtoken` (JWT)**: Manages secure, stateless user sessions.
- **`bcryptjs`**: Cryptographically hashes user passwords before storage in the **BCNF database**.
- **`helmet`**: Hardens the server by setting secure HTTP headers to prevent reconnaissance.
- **`express-rate-limit`**: Our primary shield against **DDoS attacks**, controlling request flow per IP.
- **`joi`**: Provides strict schema validation to block malformed data and SQL injection attempts.

#### **Dev & Test (SQA)**

- **`jest`**: Our core testing framework utilized to maintain **85%+ code coverage**.
- **`supertest`**: Allows for high-speed functional testing of API endpoints within the CI/CD pipeline.

---

## 🧠 AI Model Research & Training

The core of LeafGuard is a custom-trained **Convolutional Neural Network (CNN)**. Our goal was to achieve high accuracy while maintaining a small enough footprint for mobile execution.

### **1. Dataset & Preprocessing**

- **Source:** We utilized the **PlantVillage Dataset**, consisting of over 50,000 images of healthy and diseased crop leaves.
- **Augmentation:** To improve model generalization and prevent **Overfitting**, we applied real-time data augmentation, including:
- Random rotations and horizontal flips.
- Brightness and contrast adjustments.
- Zooming and shearing.

- **Normalization:** All images were resized to **224x224 pixels** and normalized to a range of to match the input requirements of the MobileNetV2 architecture.

### **2. Architecture: MobileNetV2**

We selected **MobileNetV2** as our base architecture because of its use of **Inverted Residual Blocks** and **Depthwise Separable Convolutions**.

- **Transfer Learning:** We used a pre-trained model (on ImageNet) and replaced the top "head" with custom Dense layers for our specific plant classes.
- **Fine-tuning:** After initial training, we "unfroze" the top layers of the base model to fine-tune the weights for agricultural-specific patterns.

### **3. Training & Performance Metrics**

The model was trained using the **Adam Optimizer** and **Categorical Cross-Entropy** loss function.

- **Accuracy:** Achieved **92%+ accuracy** on the validation set.
- **Optimization:** We monitored the **Loss Curve** to ensure convergence and used **Early Stopping** to halt training once the validation loss stopped improving.

### **4. Model Export & Quantization**

To enable **Edge Computing**, the model underwent a post-training optimization:

1. **SavedModel:** The model was first saved in TensorFlow format.
2. **TFLite Conversion:** Converted to `.tflite` format.
3. **8-bit Quantization:** Reduced weight precision from 32-bit floats to 8-bit integers.

- _Result:_ Reduced model size from ~19MB to **2.7MB**, significantly lowering RAM usage on the farmer's mobile device.

---

## Documentation Standards

This project follows professional engineering documentation standards:

- **Internal Comments:** All backend logic is documented using **JSDoc**.
- **API Specs:** Endpoints follow RESTful conventions.
- **Code Quality:** Every push must pass automated **Jest** (Backend) and **Flutter Test** (Frontend) suites, maintaining **85%+ coverage**.

---

## The Team

Role Member GitHub Profile
Project Manager Naol Ayele : https://github.com/naol-ayele
AI/ML Engineers Natan, Muluken : https://github.com/natanmuletahunde, https://github.com/MuleAgeri
Backend Engineers Yoseph, Naol : https://github.com/winnerJd, https://github.com/naol-ayele,
Mobile Developers Beka, Gifti, Bedasa : https://github.com/BekaAbate, https://github.com/giftiy, https://github.com/bedasamegersa
QA & Security Bekan, Roba, Naol : https://github.com/beckdg, https://github.com/RobaByteNinja

