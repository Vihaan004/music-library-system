# Music Library System – Phase 03 App

A Node.js + Express web application that connects to the PostgreSQL database from Phase 02 and exposes full CRUD operations through a browser-based UI.

---

## Tech Stack

| Layer    | Technology                  |
|----------|-----------------------------|
| Frontend | Vanilla HTML / CSS / JS (SPA) |
| Backend  | Node.js + Express 4         |
| Database | PostgreSQL (Phase 02 schema) |
| Driver   | `pg` (node-postgres)        |

---

## Prerequisites

- Node.js ≥ 18
- npm ≥ 9
- PostgreSQL running with the `music_library_database` already loaded (run `ddl.sql` then `data_load.sql`)

---

## Setup

```bash
# 1. Enter the app directory
cd app

# 2. Install dependencies
npm install

# 3. Configure environment
cp .env.example .env
#   Open .env and set DB_PASSWORD (and any other values that differ)

# 4. Start the server
npm start
#   Development (auto-reload):
npm run dev
```

Then open **http://localhost:3000** in your browser.

---

## Environment Variables (`.env`)

| Variable    | Default                  | Description              |
|-------------|--------------------------|--------------------------|
| DB_HOST     | localhost                | PostgreSQL host          |
| DB_PORT     | 5432                     | PostgreSQL port          |
| DB_NAME     | music_library_database   | Database name            |
| DB_USER     | postgres                 | Database user            |
| DB_PASSWORD | *(empty)*                | Database password        |
| PORT        | 3000                     | HTTP port for the server |

---

## API Reference

### Songs
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/songs?search=&genre=&limit=&offset=` | List / search songs |
| GET | `/api/genres` | List all distinct genres |

### Users (CREATE / READ / DELETE)
| Method | Path | Body | Description |
|--------|------|------|-------------|
| GET | `/api/users` | — | List all users |
| POST | `/api/users` | `{username, email, password}` | Create user |
| DELETE | `/api/users/:id` | — | Delete user |

### Playlists (CREATE / READ / UPDATE / DELETE)
| Method | Path | Body | Description |
|--------|------|------|-------------|
| GET | `/api/users/:userId/playlists` | — | List user's playlists |
| POST | `/api/playlists` | `{userId, name}` | Create playlist |
| PUT | `/api/playlists/:id` | `{name}` | Rename playlist |
| DELETE | `/api/playlists/:id` | — | Delete playlist |

### Playlist Songs (CREATE / READ / DELETE)
| Method | Path | Body | Description |
|--------|------|------|-------------|
| GET | `/api/playlists/:id/songs` | — | List songs in playlist |
| POST | `/api/playlists/:id/songs` | `{songId}` | Add song to playlist |
| DELETE | `/api/playlists/:id/songs/:songId` | — | Remove song from playlist |

---

## CRUD Operations Demonstrated

| Operation | Where in UI | Database table(s) |
|-----------|------------|-------------------|
| **Create** | Add User form / New Playlist / + Playlist button on song card | `app_users`, `playlists`, `playlist_songs` |
| **Read** | Browse Songs page, Playlists panel | `songs`, `artists`, `albums`, `playlists`, `playlist_songs` |
| **Update** | Rename Playlist (✏️ button) | `playlists` |
| **Delete** | Delete User / Delete Playlist / Remove song from playlist | `app_users`, `playlists`, `playlist_songs` |

---

## Default Seeded Users (from Phase 02)

| Username | Email |
|----------|-------|
| ava | ava@example.com |
| leo | leo@example.com |
| mia | mia@example.com |