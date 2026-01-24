/**
 * @fileoverview JWT authentication middleware
 * Validates JSON Web Tokens and attaches decoded user data to the request object
 */
const jwt = require("jsonwebtoken");

/**
 * Authenticate requests using JWT
 *
 * - Extracts token from Authorization header
 * - Supports "Bearer <token>" format
 * - Verifies token using JWT secret
 * - Attaches decoded payload to req.user
 *
 * @function authMiddleware
 * @param {import("express").Request} req - Express request object
 * @param {import("express").Response} res - Express response object
 * @param {import("express").NextFunction} next - Express next middleware function
 * @returns {void|import("express").Response} Continues request or returns 401 response
 */

module.exports = (req, res, next) => {
  const authHeader = req.header("Authorization");

  if (!authHeader) {
    return res.status(401).json({
      success: false,
      error: "Access Denied. No token provided.",
    });
  }

  try {
    const token = authHeader.startsWith("Bearer ")
      ? authHeader.slice(7).trim()
      : authHeader.trim();

    if (!token || token === "") {
      return res.status(401).json({
        success: false,
        error: "Token is not valid", 
      });
    }

    
    const verified = jwt.verify(token, process.env.JWT_SECRET);


    req.user = verified;
    next();
  } catch (err) {

    const message =
      err.name === "TokenExpiredError" ? "Token expired" : "Token is not valid";

    return res.status(401).json({
      success: false,
      error: message,
    });
  }
};
