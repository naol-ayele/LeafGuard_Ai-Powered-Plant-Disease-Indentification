/**
 * @fileoverview Authentication and user account controller
 * Handles registration, login, password reset, and password change
 */

const pool=require('../config/db');
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const nodemailer = require("nodemailer");

/**
 * Register a new user
 *
 * @async
 * @function register
 * @param {import("express").Request} req - Express request object
 * @param {import("express").Response} res - Express response object
 * @returns {Promise<void>} JSON response with created user data
 */
exports.register=async(req , res)=>{
    const {name, email, password}=req.body
    if (!email || typeof email !=='string'){
        return res.status(400).json({message:"email is required"})

    }
    if (!password || typeof password !== 'string'){

    }
    if (!name || typeof name !== "string") {
    return res
      .status(400)
      .json({ success: false, message: "Name is required" });
  }
  try {
    // 1. Check if user already exists
    const userExist = await pool.query("SELECT * FROM users WHERE email = $1", [
      email,
    ]);
    if (userExist.rows.length > 0) {
      return res
        .status(400)
        .json({ success: false, error: "User already exists" });
    }

    // 2. Hash the password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // 3. Insert into PostgreSQL
    const newUser = await pool.query(
      "INSERT INTO users (full_name, email, password) VALUES ($1, $2, $3) RETURNING id, full_name, email",
      [name, email, hashedPassword]
    );

    res.status(201).json({
      success: true,
      message: "User registered successfully",
      data: newUser.rows[0],
    });
  } catch (err) {
    console.error(err.message);
    res
      .status(500)
      .json({ success: false, error: "Server Error during registration" });
  }
};

/**
 * Login user and generate JWT token
 *
 * @async
 * @function login
 * @param {import("express").Request} req
 * @param {import("express").Response} res
 * @returns {Promise<void>} JWT token and user info
 */

exports.login = async (req, res) => {
  const { email, password } = req.body;

  if (
    !email ||
    !password ||
    typeof email !== "string" ||
    typeof password !== "string"
  ) {
    return res
      .status(400)
      .json({ success: false, error: "Invalid email or password format" });
  }

  try {
    // 1. Check if user exists
    const userResult = await pool.query(
      "SELECT * FROM users WHERE email = $1",
      [email]
    );
    if (userResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: "User not found" });
    }

    const user = userResult.rows[0];

    // 2. Verify Password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res
        .status(401)
        .json({ success: false, error: "Invalid credentials" });
    }

    // 3. Create and assign JWT Token
    const token = jwt.sign(
      { id: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: "7d" } 
    );

    res.json({
      success: true,
      token: token,
      user: { id: user.id, name: user.full_name, email: user.email },
    });
  } catch (err) {
    console.error(err.message);
    res
      .status(500)
      .json({ success: false, error: "Server Error during login" });
  }
}
// Forgot password

/**
 * Send password reset token to user's email
 *
 * @async
 * @function forgotPassword
 * @param {import("express").Request} req
 * @param {import("express").Response} res
 * @returns {Promise<void>} Success message
 */

exports.forgotPassword = async (req, res) => {
  const { email } = req.body;

  
  if (!email || typeof email !== "string") {
    return res
      .status(400)
      .json({ success: false, error: "A valid email is required" });
  }

  try {

    const userResult = await pool.query(
      "SELECT * FROM users WHERE email = $1",
      [email]
    );
    if (userResult.rows.length === 0) {
      return res
        .status(404)
        .json({ success: false, error: "User with this email not found" });
    }

    // 2. Create a random 6-digit numeric code
    const resetToken = Math.floor(100000 + Math.random() * 900000).toString();

    // 3. Hash the token to store in Db
    const hashedToken = crypto
      .createHash("sha256")
      .update(resetToken)
      .digest("hex");

    // 4. Set Expiry 
    const expiry = Date.now() + 15 * 60 * 1000;

    
    await pool.query(
      "UPDATE users SET reset_token = $1, reset_token_expiry = $2 WHERE email = $3",
      [hashedToken, expiry, email]
    );

    
    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });

    const mailOptions = {
      from: `"LeafGuard Support" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: "LeafGuard Password Reset Request",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
          <h2 style="color: #2e7d32; text-align: center;">Password Reset</h2>
          <p>You requested to reset your password. Please use the following 6-digit code in the LeafGuard app:</p>
          <div style="background-color: #f5f5f5; padding: 20px; text-align: center; font-size: 32px; font-weight: bold; color: #333; letter-spacing: 10px; border-radius: 5px; margin: 20px 0;">
            ${resetToken}
          </div>
          <p style="margin-top: 20px; font-size: 13px; color: #666; text-align: center;">This code will expire in 15 minutes. If you did not request this, please ignore this email.</p>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);

    res.status(200).json({
      success: true,
      message: "Reset token sent to your email address.",
    });
  } catch (err) {
    console.error(err.message);
    res
      .status(500)
      .json({ success: false, error: "Server error during forgot password" });
  }
};

// Password reset
exports.resetPassword = async (req, res) => {
  const { token, newPassword } = req.body;


  if (
    !token ||
    typeof token !== "string" ||
    !newPassword ||
    typeof newPassword !== "string"
  ) {
    return res
      .status(400)
      .json({ success: false, error: "Token and new password are required" });
  }

  try {
    // 1. Hash the incoming token to compare with stored hashed token
    const hashedToken = crypto.createHash("sha256").update(token).digest("hex");

    // 2. Find user with this token and check if expiry is still in the future
    const userResult = await pool.query(
      "SELECT * FROM users WHERE reset_token = $1 AND reset_token_expiry > $2",
      [hashedToken, Date.now()]
    );

    if (userResult.rows.length === 0) {
      return res
        .status(400)
        .json({ success: false, error: "Token is invalid or has expired" });
    }

    const user = userResult.rows[0];
    // 3. Hash the new password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);


    const result = await pool.query(
      "UPDATE users SET password = $1, reset_token = NULL, reset_token_expiry = NULL WHERE id = $2",
      [hashedPassword, user.id]
    );

    if (result.rowCount === 0) {
      return res
        .status(404)
        .json({ success: false, error: "User no longer exists" });
    }
    res
      .status(200)
      .json({ success: true, message: "Password updated successfully" });
  } catch (err) {
    console.error(err.message);
    res
      .status(500)
      .json({ success: false, error: "Server error during reset password" });
  }
};

// Change password
exports.changePassword = async (req, res) => {
  const { currentPassword, newPassword } = req.body;

  if (
    !currentPassword ||
    typeof currentPassword !== "string" ||
    !newPassword ||
    typeof newPassword !== "string"
  ) {
    return res.status(400).json({
      success: false,
      error: "Current and new passwords are required",
    });
  }

  const userId = req.user ? req.user.id : null;
  if (!userId) {
    return res.status(401).json({ success: false, error: "Unauthorized" });
  }

  try {
    // 3. Fetch user from DB
    const userResult = await pool.query("SELECT * FROM users WHERE id = $1", [
      userId,
    ]);
    const user = userResult.rows[0];

    if (!user) {
      return res.status(404).json({ success: false, error: "User not found" });
    }

    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res
        .status(401)
        .json({ success: false, error: "Current password is incorrect" });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedNewPassword = await bcrypt.hash(newPassword, salt);

    const result = await pool.query(
      "UPDATE users SET password = $1 WHERE id = $2",
      [hashedNewPassword, userId]
    );
    if (result.rowCount === 0) {
      return res
        .status(404)
        .json({ success: false, error: "User no longer exists" });
    }
    res
      .status(200)
      .json({ success: true, message: "Password changed successfully" });
  } catch (err) {
    console.error(err.message);
    res
      .status(500)
      .json({ success:
         false, error: "Server error during password change" });
  }
};
