// server.js – Music Library System API + static server
require("dotenv").config();
const express  = require("express");
const cors     = require("cors");
const path     = require("path");
const pool     = require("./db");

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

// ─────────────────────────────────────────────
//  SONGS
// ─────────────────────────────────────────────

// GET /api/songs?search=&genre=&limit=&offset=
app.get("/api/songs", async (req, res) => {
  try {
    const { search = "", genre = "", limit = 20, offset = 0 } = req.query;
    const params = [];
    let where = "WHERE 1=1";

    if (search) {
      params.push(`%${search}%`);
      where += ` AND (s.title ILIKE $${params.length} OR a.name ILIKE $${params.length})`;
    }
    if (genre) {
      params.push(genre);
      where += ` AND s.genre = $${params.length}`;
    }

    params.push(parseInt(limit), parseInt(offset));

    const sql = `
      SELECT
        s.song_id,
        s.title,
        s.genre,
        s.popularity,
        s.duration_ms,
        s.explicit,
        s.danceability,
        s.energy,
        s.valence,
        s.tempo,
        al.title  AS album,
        STRING_AGG(a.name, ', ' ORDER BY sa.billing_order) AS artists
      FROM songs s
      JOIN albums al ON al.album_id = s.album_id
      LEFT JOIN song_artists sa ON sa.song_id = s.song_id
      LEFT JOIN artists a ON a.artist_id = sa.artist_id
      ${where}
      GROUP BY s.song_id, al.title
      ORDER BY s.popularity DESC, s.song_id
      LIMIT $${params.length - 1} OFFSET $${params.length}
    `;

    const { rows } = await pool.query(sql, params);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// GET /api/genres – distinct genre list
app.get("/api/genres", async (_req, res) => {
  try {
    const { rows } = await pool.query(
      "SELECT DISTINCT genre FROM songs ORDER BY genre"
    );
    res.json(rows.map((r) => r.genre));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
//  USERS  (CREATE / READ)
// ─────────────────────────────────────────────

// GET /api/users
app.get("/api/users", async (_req, res) => {
  try {
    const { rows } = await pool.query(
      "SELECT user_id, username, email, created_at FROM app_users ORDER BY username"
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/users  { username, email, password }
app.post("/api/users", async (req, res) => {
  const { username, email, password } = req.body;
  if (!username || !email || !password)
    return res.status(400).json({ error: "username, email, and password are required" });

  try {
    // Store a bcrypt-style placeholder so the schema constraint is satisfied
    const hash = `$2b$12$${Buffer.from(username + email).toString("base64").slice(0, 53)}`;
    const { rows } = await pool.query(
      `INSERT INTO app_users (username, email, password_hash)
       VALUES ($1, $2, $3)
       RETURNING user_id, username, email, created_at`,
      [username, email, hash]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    if (err.code === "23505") {
      res.status(409).json({ error: "Username or email already exists" });
    } else {
      res.status(500).json({ error: err.message });
    }
  }
});

// DELETE /api/users/:id
app.delete("/api/users/:id", async (req, res) => {
  try {
    const { rowCount } = await pool.query(
      "DELETE FROM app_users WHERE user_id = $1",
      [req.params.id]
    );
    if (rowCount === 0) return res.status(404).json({ error: "User not found" });
    res.json({ message: "User deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
//  PLAYLISTS  (CREATE / READ / UPDATE / DELETE)
// ─────────────────────────────────────────────

// GET /api/users/:userId/playlists
app.get("/api/users/:userId/playlists", async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT p.playlist_id, p.name, p.created_date, p.updated_at,
              COUNT(ps.song_id)::INT AS song_count
       FROM playlists p
       LEFT JOIN playlist_songs ps ON ps.playlist_id = p.playlist_id
       WHERE p.user_id = $1
       GROUP BY p.playlist_id
       ORDER BY p.updated_at DESC`,
      [req.params.userId]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/playlists  { userId, name }
app.post("/api/playlists", async (req, res) => {
  const { userId, name } = req.body;
  if (!userId || !name)
    return res.status(400).json({ error: "userId and name are required" });

  try {
    const { rows } = await pool.query(
      `INSERT INTO playlists (user_id, name)
       VALUES ($1, $2)
       RETURNING playlist_id, name, created_date, updated_at`,
      [userId, name]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    if (err.code === "23505") {
      res.status(409).json({ error: "You already have a playlist with that name" });
    } else {
      res.status(500).json({ error: err.message });
    }
  }
});

// PUT /api/playlists/:id  { name }
app.put("/api/playlists/:id", async (req, res) => {
  const { name } = req.body;
  if (!name) return res.status(400).json({ error: "name is required" });

  try {
    const { rows, rowCount } = await pool.query(
      `UPDATE playlists
       SET name = $1, updated_at = NOW()
       WHERE playlist_id = $2
       RETURNING playlist_id, name, updated_at`,
      [name, req.params.id]
    );
    if (rowCount === 0) return res.status(404).json({ error: "Playlist not found" });
    res.json(rows[0]);
  } catch (err) {
    if (err.code === "23505") {
      res.status(409).json({ error: "You already have a playlist with that name" });
    } else {
      res.status(500).json({ error: err.message });
    }
  }
});

// DELETE /api/playlists/:id
app.delete("/api/playlists/:id", async (req, res) => {
  try {
    const { rowCount } = await pool.query(
      "DELETE FROM playlists WHERE playlist_id = $1",
      [req.params.id]
    );
    if (rowCount === 0) return res.status(404).json({ error: "Playlist not found" });
    res.json({ message: "Playlist deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
//  PLAYLIST SONGS  (CREATE / READ / DELETE)
// ─────────────────────────────────────────────

// GET /api/playlists/:id/songs
app.get("/api/playlists/:id/songs", async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT
         s.song_id, s.title, s.genre, s.popularity,
         s.duration_ms, s.explicit, s.energy, s.danceability,
         al.title  AS album,
         STRING_AGG(a.name, ', ' ORDER BY sa.billing_order) AS artists,
         ps.date_added
       FROM playlist_songs ps
       JOIN songs s ON s.song_id = ps.song_id
       JOIN albums al ON al.album_id = s.album_id
       LEFT JOIN song_artists sa ON sa.song_id = s.song_id
       LEFT JOIN artists a ON a.artist_id = sa.artist_id
       WHERE ps.playlist_id = $1
       GROUP BY s.song_id, al.title, ps.date_added
       ORDER BY ps.date_added DESC`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/playlists/:id/songs  { songId }
app.post("/api/playlists/:id/songs", async (req, res) => {
  const { songId } = req.body;
  if (!songId) return res.status(400).json({ error: "songId is required" });

  try {
    await pool.query(
      `INSERT INTO playlist_songs (playlist_id, song_id)
       VALUES ($1, $2)
       ON CONFLICT DO NOTHING`,
      [req.params.id, songId]
    );
    // Update playlist timestamp
    await pool.query(
      "UPDATE playlists SET updated_at = NOW() WHERE playlist_id = $1",
      [req.params.id]
    );
    res.status(201).json({ message: "Song added to playlist" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/playlists/:id/songs/:songId
app.delete("/api/playlists/:id/songs/:songId", async (req, res) => {
  try {
    const { rowCount } = await pool.query(
      "DELETE FROM playlist_songs WHERE playlist_id = $1 AND song_id = $2",
      [req.params.id, req.params.songId]
    );
    if (rowCount === 0)
      return res.status(404).json({ error: "Song not in playlist" });
    await pool.query(
      "UPDATE playlists SET updated_at = NOW() WHERE playlist_id = $1",
      [req.params.id]
    );
    res.json({ message: "Song removed from playlist" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
//  START
// ─────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () =>
  console.log(`🎵  Music Library running → http://localhost:${PORT}`)
);