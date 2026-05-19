const express = require("express");
const bcrypt = require("bcryptjs");
const { db, publicUser, publicStream, publicMessage } = require("../db");
const { signToken, requireAuth } = require("../middleware/auth");

const router = express.Router();

function parseBody(req, fields) {
  const missing = fields.filter((f) => {
    const value = req.body[f];
    return value === undefined || value === null || String(value).trim() === "";
  });
  return missing;
}

// POST /api/login
router.post("/login", (req, res) => {
  const missing = parseBody(req, ["email", "password"]);
  if (missing.length) {
    return res.status(400).json({
      success: false,
      error: `Missing required fields: ${missing.join(", ")}`,
    });
  }

  const email = String(req.body.email).trim().toLowerCase();
  const password = String(req.body.password);

  const user = db
    .prepare(
      "SELECT id, username, email, password_hash, display_name, avatar_url, created_at FROM users WHERE email = ?"
    )
    .get(email);

  if (!user || !bcrypt.compareSync(password, user.password_hash)) {
    return res.status(401).json({
      success: false,
      error: "Invalid email or password",
    });
  }

  const token = signToken(user.id);
  return res.json({
    success: true,
    token,
    user: publicUser(user),
  });
});

// POST /api/register
router.post("/register", (req, res) => {
  const missing = parseBody(req, ["username", "email", "password"]);
  if (missing.length) {
    return res.status(400).json({
      success: false,
      error: `Missing required fields: ${missing.join(", ")}`,
    });
  }

  const username = String(req.body.username).trim();
  const email = String(req.body.email).trim().toLowerCase();
  const password = String(req.body.password);
  const displayName = req.body.displayName
    ? String(req.body.displayName).trim()
    : username;

  if (password.length < 6) {
    return res.status(400).json({
      success: false,
      error: "Password must be at least 6 characters",
    });
  }

  if (username.length < 3) {
    return res.status(400).json({
      success: false,
      error: "Username must be at least 3 characters",
    });
  }

  const existing = db
    .prepare(
      "SELECT id FROM users WHERE email = ? OR username = ? COLLATE NOCASE"
    )
    .get(email, username);

  if (existing) {
    return res.status(409).json({
      success: false,
      error: "Email or username already registered",
    });
  }

  const passwordHash = bcrypt.hashSync(password, 10);
  const result = db
    .prepare(
      `INSERT INTO users (username, email, password_hash, display_name)
       VALUES (?, ?, ?, ?)`
    )
    .run(username, email, passwordHash, displayName);

  const user = db
    .prepare(
      "SELECT id, username, email, display_name, avatar_url, created_at FROM users WHERE id = ?"
    )
    .get(result.lastInsertRowid);

  const token = signToken(user.id);
  return res.status(201).json({
    success: true,
    token,
    user: publicUser(user),
  });
});

// GET /api/profile
router.get("/profile", requireAuth, (req, res) => {
  return res.json({
    success: true,
    user: publicUser(req.user),
  });
});

// GET /api/live-streams
router.get("/live-streams", (req, res) => {
  const liveOnly = req.query.live !== "false";
  const sql = liveOnly
    ? "SELECT * FROM live_streams WHERE is_live = 1 ORDER BY viewer_count DESC"
    : "SELECT * FROM live_streams ORDER BY viewer_count DESC";

  const rows = db.prepare(sql).all();
  return res.json({
    success: true,
    streams: rows.map(publicStream),
    count: rows.length,
  });
});

// POST /api/send-message
router.post("/send-message", requireAuth, (req, res) => {
  const missing = parseBody(req, ["streamId", "message"]);
  if (missing.length) {
    return res.status(400).json({
      success: false,
      error: `Missing required fields: ${missing.join(", ")}`,
    });
  }

  const streamId = Number(req.body.streamId);
  const content = String(req.body.message).trim();

  if (!Number.isInteger(streamId) || streamId < 1) {
    return res.status(400).json({
      success: false,
      error: "streamId must be a positive integer",
    });
  }

  if (content.length > 500) {
    return res.status(400).json({
      success: false,
      error: "Message must be 500 characters or fewer",
    });
  }

  const stream = db
    .prepare("SELECT id FROM live_streams WHERE id = ?")
    .get(streamId);

  if (!stream) {
    return res.status(404).json({
      success: false,
      error: "Live stream not found",
    });
  }

  const result = db
    .prepare(
      "INSERT INTO messages (stream_id, user_id, content) VALUES (?, ?, ?)"
    )
    .run(streamId, req.user.id, content);

  const row = db
    .prepare("SELECT * FROM messages WHERE id = ?")
    .get(result.lastInsertRowid);

  return res.status(201).json({
    success: true,
    message: publicMessage(row, req.user.username),
  });
});

module.exports = router;
