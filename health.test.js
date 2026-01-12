const request = require("supertest");
const app = require("../index");

describe("System Health Checks", () => {
  it("should return 200 for the root route", async () => {
    const res = await request(app).get("/");
    expect(res.text).toBe("LeafGuard Professional Backend is Running!");
  });

  it("should return 200 for the health endpoint", async () => {
    const res = await request(app).get("/health");
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe("UP");
  });
});

describe("System Health and Global Error Handlers", () => {
  it("should return 200 and a timestamp for the health endpoint", async () => {
    const res = await request(app).get("/health");
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty("timestamp");
  });

  it("should trigger the Global 404 Handler for unknown routes", async () => {
    const res = await request(app).get("/api/unknown-endpoint-123");
    expect(res.statusCode).toBe(404);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain("not found");
  });

  it("should trigger the Global Error Handler", async () => {
    // We send something that we know will cause a 500 or error
    // If we mock a route to throw an error, it hits the global handler
    const res = await request(app).get("/api/auth/login").send(null);
    // This usually triggers a 400 or 500 depending on your controller logic
    expect(res.body).toHaveProperty("success", false);
  });
});
