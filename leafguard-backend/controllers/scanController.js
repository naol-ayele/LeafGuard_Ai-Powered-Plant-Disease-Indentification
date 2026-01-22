/**
 * @fileoverview Scan controller
 * Handles uploading scans, retrieving scan history, and deleting scans
 */

const pool = require("../config/db");
const Joi = require("joi");

/**
 * Joi validation schema for scan upload
 * @type {Joi.ObjectSchema}
 */
const scanValidationSchema = Joi.object({
  label: Joi.string().max(100).required(),
  confidence: Joi.number().min(0).max(1).required(),
  status: Joi.string().max(50).optional().allow(null, ""),
  plant: Joi.string().max(100).optional().allow(null, ""),
  cause: Joi.string().max(255).optional().allow(null, ""),
  symptoms: Joi.string().max(500).optional().allow(null, ""),
  treatment: Joi.string().max(1000).optional().allow(null, ""),
});
// Upload New Scan
/**
 * Upload a new disease scan
 *
 * - Validates request body using Joi
 * - Inserts disease information (if not already present)
 * - Stores scan metadata linked to authenticated user
 * - Supports transactions when using a PostgreSQL client pool
 *
 * @async
 * @function uploadScan
 * @param {import("express").Request} req - Express request object
 * @param {import("express").Response} res - Express response object
 * @returns {Promise<void>} JSON response containing saved scan data
 */
exports.uploadScan = async (req, res) => {
  let client;
  // Detect if we are in a mock environment or a real PG pool
  const canTransact = typeof pool.connect === "function";

  try {
    const { error, value } = scanValidationSchema.validate(req.body, {
      abortEarly: false,
    });

    if (error) {
      return res.status(400).json({
        success: false,
        error: "Validation Failed",
        details: error.details.map((d) => d.message),
      });
    }

    const { label, confidence, status, plant, cause, symptoms, treatment } =
      value;
    const userId = req.user.id;
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : null;

    if (canTransact) {
      client = await pool.connect();
      await client.query("BEGIN");
    }
    const db = client || pool;

    await db.query(
      `INSERT INTO disease_info (label, plant_name, cause, symptoms, treatment) 
       VALUES ($1, $2, $3, $4, $5) 
       ON CONFLICT (label) DO NOTHING`,
      [label, plant, cause, symptoms, treatment]
    );

    const query = `
      INSERT INTO scans (label, confidence, plant_status, image_url, user_id) 
      VALUES ($1, $2, $3, $4, $5) 
      RETURNING *`;

    const result = await db.query(query, [
      label,
      confidence,
      status,
      imageUrl,
      userId,
    ]);

    if (canTransact) await client.query("COMMIT");

    return res.status(201).json({
      success: true,
      message: "Scan synced successfully",
      data: result.rows[0],
    });
  } catch (err) {
    if (client) await client.query("ROLLBACK");
    console.error("Upload Error:", err.message);

    const isProduction = process.env.NODE_ENV === "production";
    return res.status(500).json({
      success: false,
      error: "Internal Server Error",
      ...(isProduction ? {} : { details: err.message }),
    });
  } finally {
    if (client) client.release();
  }
};

// Get scan history
/**
 * Retrieve scan history for authenticated user
 *
 * - Fetches scans joined with disease information
 * - Returns scans ordered by most recent first
 *
 * @async
 * @function getHistory
 * @param {import("express").Request} req
 * @param {import("express").Response} res
 * @returns {Promise<void>} JSON response containing scan history
 */
exports.getHistory = async (req, res) => {
  const userId = req.user.id;
  try {
    const query = `
      SELECT 
        s.id, s.label, s.confidence, s.image_url, s.plant_status, s.created_at,
        d.plant_name, d.cause, d.symptoms, d.treatment
      FROM scans s
      JOIN disease_info d ON s.label = d.label
      WHERE s.user_id = $1
      ORDER BY s.created_at DESC
    `;
    const result = await pool.query(query, [userId]);
    res.status(200).json({ success: true, data: result.rows });
  } catch (err) {
    console.error(err.message);
    res
      .status(500)
      .json({ success: false, error: "Server error fetching history" });
  }
};

// delete a scan
exports.deleteScan = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const userEmail = req.user.email;

    const result = await pool.query(
      "DELETE FROM scans WHERE id = $1 AND user_id = $2 RETURNING *",
      [id, userId]
    );

    if (result.rowCount === 0) {
      return res
        .status(404)
        .json({ success: false, message: "Scan not found or unauthorized" });
    }

    console.log(
      `[AUDIT LOG] Action: DELETE_SCAN | User: ${userEmail} (ID: ${userId}) | Scan ID: ${id} | Timestamp: ${new Date().toISOString()}`
    );

    res.json({ success: true, message: "Scan deleted successfully" });
  } catch (err) {
    const isProduction = process.env.NODE_ENV === "production";
    res.status(500).json({
      success: false,
      error: isProduction ? "Internal Server Error" : err.message,
    });
  }
};
