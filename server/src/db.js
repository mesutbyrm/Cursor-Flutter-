const fs = require("fs");
const path = require("path");
const Database = require("better-sqlite3");

const dbPath =
  process.env.DATABASE_PATH ||
  path.join(__dirname, "..", "data", "canlifal.db");

fs.mkdirSync(path.dirname(dbPath), { recursive: true });

const db = new Database(dbPath);
db.pragma("journal_mode = WAL");
db.pragma("foreign_keys = ON");

db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE COLLATE NOCASE,
    email TEXT NOT NULL UNIQUE COLLATE NOCASE,
    password_hash TEXT NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS live_streams (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    streamer_name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'general',
    thumbnail_url TEXT,
    stream_url TEXT,
    is_live INTEGER NOT NULL DEFAULT 1,
    viewer_count INTEGER NOT NULL DEFAULT 0,
    started_at TEXT NOT NULL DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    stream_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    content TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (stream_id) REFERENCES live_streams(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  );
`);

function seedIfEmpty() {
  const streamCount = db
    .prepare("SELECT COUNT(*) AS count FROM live_streams")
    .get().count;

  if (streamCount === 0) {
    const insert = db.prepare(`
      INSERT INTO live_streams (title, streamer_name, category, thumbnail_url, viewer_count, is_live)
      VALUES (@title, @streamer_name, @category, @thumbnail_url, @viewer_count, 1)
    `);

    const streams = [
      {
        title: "Kahve Falı — Canlı Yorum",
        streamer_name: "Ayşe Hanım",
        category: "kahve",
        thumbnail_url: null,
        viewer_count: 128,
      },
      {
        title: "Tarot Açılımı",
        streamer_name: "Melek",
        category: "tarot",
        thumbnail_url: null,
        viewer_count: 94,
      },
      {
        title: "El Falı & Astroloji",
        streamer_name: "Zeynep",
        category: "el",
        thumbnail_url: null,
        viewer_count: 67,
      },
      {
        title: "Katina Falı — Soru Cevap",
        streamer_name: "Fatma Ana",
        category: "katina",
        thumbnail_url: null,
        viewer_count: 203,
      },
    ];

    for (const stream of streams) {
      insert.run(stream);
    }
  }
}

seedIfEmpty();

function publicUser(row) {
  if (!row) return null;
  return {
    id: row.id,
    username: row.username,
    email: row.email,
    displayName: row.display_name || row.username,
    avatarUrl: row.avatar_url,
    createdAt: row.created_at,
  };
}

function publicStream(row) {
  return {
    id: row.id,
    title: row.title,
    streamerName: row.streamer_name,
    category: row.category,
    thumbnailUrl: row.thumbnail_url,
    streamUrl: row.stream_url,
    isLive: Boolean(row.is_live),
    viewerCount: row.viewer_count,
    startedAt: row.started_at,
  };
}

function publicMessage(row, username) {
  return {
    id: row.id,
    streamId: row.stream_id,
    userId: row.user_id,
    username,
    content: row.content,
    createdAt: row.created_at,
  };
}

module.exports = { db, publicUser, publicStream, publicMessage };
