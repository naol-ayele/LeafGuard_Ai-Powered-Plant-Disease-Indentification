/**
 * @fileoverview Scan routes
 * Defines routes for uploading plant disease scans,
 * retrieving scan history, and deleting scans.
 */


const express = require("express");
const router = express.Router();
const scanController = require("../controllers/scanController");
const auth = require("../middleware/authMiddleware");
const multer = require("multer");
// upload configuration
const upload = multer({
  dest: "uploads/",
  limits: { fileSize: 5 * 1024 * 1024 }, 
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith("image/")) {
      cb(null, true);
    } else {
      cb(new Error("Only images less than 5mb are allowed!"), false);
    }
  },
});
// restrictd route for uploading and viewing scan history 
router.post("/upload", auth, upload.single("image"), scanController.uploadScan);
router.get("/history", auth, scanController.getHistory);
router.delete("/:id", auth, scanController.deleteScan);

module.exports = router;