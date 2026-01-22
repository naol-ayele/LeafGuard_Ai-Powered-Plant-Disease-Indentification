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

/**
 * Authenticate user and return JWT token
 *
 * @route POST /login
 * @access Public
 */
router.put("/change-password", authMiddleware, authController.changePassword);

/**
 * Change password for authenticated user
 *
 * @route PUT /change-password
 * @access Private
 */
router.post("/forgot-password", authController.forgotPassword);
/**
 * Request password reset token via email
 *
 * @route POST /forgot-password
 * @access Public
 */
router.post("/reset-password", authController.resetPassword);

module.exports = router;
