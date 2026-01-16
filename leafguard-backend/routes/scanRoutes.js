const express = require("express");
const router = express.Router();
const scanController = require("../controllers/scanController");
const auth = require("../middleware/authMiddleware");
const multer = require("multer");