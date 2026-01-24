const request = require("supertest");
const app = require("../index");

describe("Index.js Global Handlers", () => {
  // Covers Line 43 & 53-56 (The generic error path)
  it("should trigger the global error handler for unexpected errors", async () => {
    // Sending an empty object {} instead of null
    // This allows the code to destructure req.body but fail on logic
    const res = await request(app).post("/api/auth/login").send({});

    expect(res.body).toHaveProperty("success", false);
  });

  // Covers the Syntax Error branch (Broken JSON)
  it("should return 400 for a syntax error in request body", async () => {
    const res = await request(app)
      .post("/api/auth/login")
      .set("Content-Type", "application/json")
      .send('{"email": "test@test.com", "password": }'); // Invalid JSON

    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  // Covers the 404 Handler branch
  it("should return 404 for a non-existent route", async () => {
    const res = await request(app).get("/api/v1/not-a-real-route");
    expect(res.statusCode).toBe(404);
  });

  it("should return 400 for a syntax error in request body", async () => {
    const res = await request(app)
      .post("/api/auth/login")
      .set("Content-Type", "application/json")
      .send('{"email": "test@test.com", "password": }'); // Malformed JSON

    // This triggers the Global Error Handler in index.js
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });
});
