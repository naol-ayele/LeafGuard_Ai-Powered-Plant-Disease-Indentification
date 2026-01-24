const express = require("express");
const cors = require("cors");
const path = require("path"); // Added missing import
require("dotenv").config();
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");

const app = express();

// 1. Security Headers (Mitigates Info Disclosure)
app.use(helmet());

// 2. Global Rate Limiter (Mitigates DoS)
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per window
  message: { error: "Too many requests, please try again later." },
});
app.use("/api/", generalLimiter);

// 3. Strict Limiter for Auth/Email (Mitigates Brute Force)
const authLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 10, // Only 10 attempts (login/forgot-password) per hour
  message: { error: "Security limit reached. Try again in an hour." },
});
app.use("/api/auth/login", authLimiter);
app.use("/api/auth/forgot-password", authLimiter);

// 1. Middleware
app.use(cors());
app.use(express.json()); // This fixes the "req.body undefined" error
app.use(express.urlencoded({ extended: true }));

// 2. Static Folder for Images (So Flutter can display them via URL)
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// 3. Link Modular Routes
// These files now handle the logic you had at the bottom of your file
app.use("/api/auth", require("./routes/authRoutes"));
app.use("/api/scans", require("./routes/scanRoutes"));

// 4. Test Route
app.get("/", (req, res) => {
  res.send("LeafGuard Professional Backend is Running!");
});

// 5. Health Check Route
app.get("/health", (req, res) => {
  res.status(200).json({ status: "UP", timestamp: new Date() });
});

// --- ENHANCEMENTS START ---

// 6. Global 404 Handler (Catch-all for undefined routes)
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.originalUrl} not found`,
  });
});

// 7. Global Error Handler (Handles Multer errors, DB crashes, and syntax errors)
app.use((err, req, res, next) => {
  console.error("Critical Error Detected:", err.stack);

  // If the error comes from Multer (e.g., file too large) or invalid file type
  /* istanbul ignore next */
  if (err.code === "LIMIT_FILE_SIZE") {
    return res.status(400).json({
      success: false,
      error: "File too large. Maximum limit is 5MB.",
    });
  }

  // Detect custom Multer fileFilter errors (Fixes the 500 vs 400 test failure)
  if (err.message && err.message.includes("Only images")) {
    return res.status(400).json({
      success: false,
      error: err.message,
    });
  }

  res.status(err.status || 500).json({
    success: false,
    error: err.message || "Internal Server Error",
  });
});

// --- ENHANCEMENTS END ---

// 2. ONLY start the listener if this file is run directly (not by Jest)
/* istanbul ignore next */
if (process.env.NODE_ENV !== "test") {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => {
    console.log(`Server running on http://0.0.0.0:${PORT}`);
  });
}

module.exports = app;
