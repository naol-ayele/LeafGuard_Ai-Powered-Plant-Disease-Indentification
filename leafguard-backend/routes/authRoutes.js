/**
 * @fileoverview Authentication routes
 * Defines routes for user registration, login, password management,
 * and password recovery operations.
 */

const express = require("express");
const router = express.Router();
const authController = require("../controllers/authController");
const authMiddleware = require("../middleware/authMiddleware");
/**
 * Register a new user
 *
 * @route POST /register
 * @access Public
 */
router.post("/register", authController.register);


router.post("/login", authController.login);
router.put("/change-password", authMiddleware, authController.changePassword);
router.post("/forgot-password", authController.forgotPassword);
router.post("/reset-password", authController.resetPassword);

module.exports = router;
