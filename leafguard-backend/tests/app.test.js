const request = require("supertest");
const app = require("../index");

describe("Sanity Check", () => {
  it("should return status UP from the health endpoint", async () => {
    const res = await request(app).get("/health");
    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toBe("UP");
  });
});
