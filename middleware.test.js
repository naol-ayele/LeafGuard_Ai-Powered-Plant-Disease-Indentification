const authMiddleware = require("../middleware/authMiddleware");
const jwt = require("jsonwebtoken");
const request = require("supertest");
const app = require("../index");

describe("Auth Middleware Unit Tests", () => {
  let mockReq;
  let mockRes;
  let nextFunction;

  beforeEach(() => {
    mockReq = { header: jest.fn() };
    mockRes = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    nextFunction = jest.fn();
    process.env.JWT_SECRET = "testsecret";
  });

  it("should return 401 if no Authorization header is present", () => {
    mockReq.header.mockReturnValue(null);
    authMiddleware(mockReq, mockRes, nextFunction);
    expect(mockRes.status).toHaveBeenCalledWith(401);
    expect(mockRes.json).toHaveBeenCalledWith(
      expect.objectContaining({ error: "Access Denied. No token provided." })
    );
  });

  // FIXED: Updated from 400 to 401 and corrected error message
  it("should return 401 if token is invalid", () => {
    mockReq.header.mockReturnValue("Bearer invalidtoken");
    authMiddleware(mockReq, mockRes, nextFunction);
    expect(mockRes.status).toHaveBeenCalledWith(401);
    expect(mockRes.json).toHaveBeenCalledWith(
      expect.objectContaining({ error: "Token is not valid" })
    );
  });

  // NEW: Cover Line 21 (Malformed/Empty token after Bearer)
  it("should return 401 if token is empty after Bearer prefix", () => {
    mockReq.header.mockReturnValue("Bearer ");
    authMiddleware(mockReq, mockRes, nextFunction);
    expect(mockRes.status).toHaveBeenCalledWith(401);
    expect(mockRes.json).toHaveBeenCalledWith(
      expect.objectContaining({ error: "Token is not valid" })
    );
  });

  it("should call next() and set req.user if token is valid", () => {
    const payload = { id: 1, email: "test@test.com" };
    const token = jwt.sign(payload, process.env.JWT_SECRET);
    mockReq.header.mockReturnValue(`Bearer ${token}`);

    authMiddleware(mockReq, mockRes, nextFunction);

    expect(nextFunction).toHaveBeenCalled();
    expect(mockReq.user).toMatchObject(payload);
  });

  it("should handle tokens without 'Bearer ' prefix correctly", () => {
    const payload = { id: 1 };
    const token = jwt.sign(payload, process.env.JWT_SECRET);
    mockReq.header.mockReturnValue(token);

    authMiddleware(mockReq, mockRes, nextFunction);

    expect(nextFunction).toHaveBeenCalled();
    expect(mockReq.user).toMatchObject(payload);
  });
  it("should return 401 for an expired token (Line 36)", () => {
    // Create a token that expired 1 hour ago
    const expiredToken = jwt.sign({ id: 1 }, process.env.JWT_SECRET, {
      expiresIn: "-1h",
    });
    mockReq.header.mockReturnValue(`Bearer ${expiredToken}`);

    authMiddleware(mockReq, mockRes, nextFunction);

    expect(mockRes.status).toHaveBeenCalledWith(401);
    expect(mockRes.json).toHaveBeenCalledWith(
      expect.objectContaining({ error: "Token expired" })
    );
  });
});
