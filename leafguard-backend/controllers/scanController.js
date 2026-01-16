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