const pool=require('../config/db');
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const nodemailer = require("nodemailer");
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


