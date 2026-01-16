const pool = require("../config/db");
const Joi = require("joi");
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

// Get scan
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