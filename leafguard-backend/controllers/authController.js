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


