const jwt = require("jsonwebtoken");
const { db, publicUser } = require("../db");

const JWT_SECRET = process.env.JWT_SECRET || "canlifal-dev-secret";

function signToken(userId) {
  return jwt.sign({ sub: userId }, JWT_SECRET, { expiresIn: "7d" });
}

function requireAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith("Bearer ")) {
    return res.status(401).json({
      success: false,
      error: "Authorization header with Bearer token is required",
    });
  }

  const token = header.slice(7);
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    const user = db
      .prepare(
        "SELECT id, username, email, display_name, avatar_url, created_at FROM users WHERE id = ?"
      )
      .get(payload.sub);

    if (!user) {
      return res.status(401).json({ success: false, error: "User not found" });
    }

    req.user = user;
    req.token = token;
    next();
  } catch {
    return res.status(401).json({ success: false, error: "Invalid or expired token" });
  }
}

module.exports = { signToken, requireAuth, JWT_SECRET };
