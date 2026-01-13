const request = require("supertest");
const app = require("../index");
const pool = require("../config/db");

// Mock the database pool and client for transactions
const mockClient = {
  query: jest.fn(),
  release: jest.fn(),
};

jest.mock("../config/db", () => ({
  query: jest.fn(),
  connect: jest.fn(() => Promise.resolve(mockClient)), // Mocking pool.connect()
}));

// Mock Auth Middleware to bypass real JWT checks
jest.mock("../middleware/authMiddleware", () => (req, res, next) => {
  req.user = { id: 1, email: "test@leafguard.com" };
  next();
});

describe("Scan Controller Unit Tests (Updated with Security Hardening)", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // Default mock to prevent "cannot read property rows of undefined" errors
    pool.query.mockResolvedValue({ rows: [], rowCount: 0 });
    mockClient.query.mockResolvedValue({ rows: [], rowCount: 0 });
  });

  describe("GET /api/scans/history", () => {
    it("should return 200 and the user's scan history", async () => {
      const mockHistory = [
        {
          id: 1,
          label: "Tomato_Healthy",
          confidence: 0.98,
          plant_name: "Tomato",
        },
      ];
      pool.query.mockResolvedValueOnce({ rows: mockHistory });

      const res = await request(app).get("/api/scans/history");

      expect(res.statusCode).toEqual(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data[0].label).toBe("Tomato_Healthy");
    });

    it("should return 500 if the database query fails", async () => {
      pool.query.mockRejectedValueOnce(new Error("DB Error"));
      const res = await request(app).get("/api/scans/history");
      expect(res.statusCode).toEqual(500);
    });
  });

  describe("POST /api/scans/upload", () => {
    it("should return 400 if validation fails (Joi Catch)", async () => {
      const res = await request(app).post("/api/scans/upload").send({
        label: "Tomato_Healthy",
        confidence: 1.5, // Invalid: max is 1
      });
      expect(res.statusCode).toEqual(400);
      expect(res.body.error).toBe("Validation Failed");
    });

    it("should return 201 and sync scan when data is valid (Transaction Path)", async () => {
      // 1. BEGIN, 2. INSERT disease, 3. INSERT scan, 4. COMMIT
      mockClient.query
        .mockResolvedValueOnce({})
        .mockResolvedValueOnce({ rowCount: 1 })
        .mockResolvedValueOnce({ rows: [{ id: 99, label: "Tomato_Healthy" }] })
        .mockResolvedValueOnce({});

      const res = await request(app).post("/api/scans/upload").send({
        label: "Tomato_Healthy",
        confidence: 0.99,
        status: "Healthy",
        plant: "Tomato",
      });

      expect(res.statusCode).toEqual(201);
      expect(res.body.success).toBe(true);
      expect(mockClient.query).toHaveBeenCalledWith(
        expect.stringContaining("BEGIN")
      );
      expect(mockClient.release).toHaveBeenCalled();
    });

    it("should successfully handle a file upload with multipart/form-data", async () => {
      mockClient.query
        .mockResolvedValueOnce({})
        .mockResolvedValueOnce({ rowCount: 1 })
        .mockResolvedValueOnce({ rows: [{ id: 100 }] })
        .mockResolvedValueOnce({});

      const res = await request(app)
        .post("/api/scans/upload")
        .set("Authorization", "Bearer mock-token")
        .field("label", "Tomato_Healthy")
        .field("confidence", 0.99)
        .field("status", "Healthy")
        .field("plant", "Tomato")
        .attach("image", Buffer.from("fake-image"), "test.jpg");

      expect(res.statusCode).toEqual(201);
    });

    it("should return 500 and ROLLBACK if database fails during transaction", async () => {
      mockClient.query.mockResolvedValueOnce({}); // BEGIN
      mockClient.query.mockRejectedValueOnce(new Error("Transaction Crash")); // INSERT fails

      const res = await request(app).post("/api/scans/upload").send({
        label: "Tomato_Healthy",
        confidence: 0.9,
        plant: "Tomato",
      });

      expect(res.statusCode).toEqual(500);
      expect(mockClient.query).toHaveBeenCalledWith(
        expect.stringContaining("ROLLBACK")
      );
    });
  });

  describe("DELETE /api/scans/:id", () => {
    it("should return 200 and trigger Audit Log when successfully deleted", async () => {
      const consoleSpy = jest.spyOn(console, "log").mockImplementation();
      pool.query.mockResolvedValueOnce({ rowCount: 1 });

      const res = await request(app).delete("/api/scans/1");

      expect(res.statusCode).toEqual(200);
      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining("[AUDIT LOG]")
      );
      consoleSpy.mockRestore();
    });

    it("should return 404 if scan doesn't exist (Fixes Line 126 Coverage)", async () => {
      // rowCount: 0 triggers the 404 branch
      pool.query.mockResolvedValueOnce({ rowCount: 0 });

      const res = await request(app).delete("/api/scans/999");

      expect(res.statusCode).toEqual(404);
      expect(res.body.message).toBe("Scan not found or unauthorized");
    });

    it("should return 500 when database fails during deletion", async () => {
      pool.query.mockRejectedValueOnce(new Error("Delete Failure"));
      const res = await request(app).delete("/api/scans/1");
      expect(res.statusCode).toBe(500);
    });

    it("should return 400 when an invalid file type is uploaded (Hits scanRoutes.js:14)", async () => {
      const res = await request(app)
        .post("/api/scans/upload")
        .set("Authorization", "Bearer mock-token")
        .attach("image", Buffer.from("not-an-image"), "test.pdf"); // .pdf triggers the error

      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error).toContain("Only images");
    });
  });
});
