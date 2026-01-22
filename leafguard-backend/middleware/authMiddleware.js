/**
 * @fileoverview JWT authentication middleware
 * Validates JSON Web Tokens and attaches decoded user data to the request object
 */
const jwt = require("jsonwebtoken");

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
