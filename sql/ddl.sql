BEGIN;

DROP TABLE IF EXISTS playlist_songs CASCADE;
DROP TABLE IF EXISTS song_artists CASCADE;
DROP TABLE IF EXISTS playlists CASCADE;
DROP TABLE IF EXISTS songs CASCADE;
DROP TABLE IF EXISTS albums CASCADE;
DROP TABLE IF EXISTS artists CASCADE;
DROP TABLE IF EXISTS app_users CASCADE;
DROP TABLE IF EXISTS raw_tracks CASCADE;

CREATE TABLE app_users (
	user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	username VARCHAR(50) NOT NULL UNIQUE,
	email VARCHAR(255) NOT NULL UNIQUE,
	password_hash VARCHAR(255) NOT NULL,
	created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE artists (
	artist_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	name TEXT NOT NULL UNIQUE,
	country VARCHAR(100),
	created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE albums (
	album_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	title TEXT NOT NULL,
	primary_artist_id BIGINT NOT NULL REFERENCES artists(artist_id) ON UPDATE CASCADE ON DELETE RESTRICT,
	release_year INTEGER,
	created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
	CONSTRAINT albums_release_year_check CHECK (release_year IS NULL OR release_year BETWEEN 1900 AND EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER + 1),
	CONSTRAINT albums_title_artist_unique UNIQUE (title, primary_artist_id)
);

CREATE TABLE songs (
	song_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	track_id VARCHAR(64) NOT NULL UNIQUE,
	album_id BIGINT NOT NULL REFERENCES albums(album_id) ON UPDATE CASCADE ON DELETE RESTRICT,
	title TEXT NOT NULL,
	popularity SMALLINT NOT NULL CHECK (popularity BETWEEN 0 AND 100),
	duration_ms INTEGER NOT NULL CHECK (duration_ms > 0),
	duration_seconds NUMERIC(10, 3) GENERATED ALWAYS AS (ROUND(duration_ms::NUMERIC / 1000, 3)) STORED,
	explicit BOOLEAN NOT NULL,
	danceability DOUBLE PRECISION NOT NULL CHECK (danceability BETWEEN 0 AND 1),
	energy DOUBLE PRECISION NOT NULL CHECK (energy BETWEEN 0 AND 1),
	track_key SMALLINT NOT NULL CHECK (track_key BETWEEN 0 AND 11),
	loudness DOUBLE PRECISION NOT NULL,
	mode SMALLINT NOT NULL CHECK (mode IN (0, 1)),
	speechiness DOUBLE PRECISION NOT NULL CHECK (speechiness BETWEEN 0 AND 1),
	acousticness DOUBLE PRECISION NOT NULL CHECK (acousticness BETWEEN 0 AND 1),
	instrumentalness DOUBLE PRECISION NOT NULL CHECK (instrumentalness BETWEEN 0 AND 1),
	liveness DOUBLE PRECISION NOT NULL CHECK (liveness BETWEEN 0 AND 1),
	valence DOUBLE PRECISION NOT NULL CHECK (valence BETWEEN 0 AND 1),
	tempo DOUBLE PRECISION NOT NULL CHECK (tempo > 0),
	time_signature SMALLINT NOT NULL CHECK (time_signature BETWEEN 1 AND 12),
	genre VARCHAR(100) NOT NULL,
	created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE song_artists (
	song_id BIGINT NOT NULL REFERENCES songs(song_id) ON UPDATE CASCADE ON DELETE CASCADE,
	artist_id BIGINT NOT NULL REFERENCES artists(artist_id) ON UPDATE CASCADE ON DELETE RESTRICT,
	billing_order SMALLINT NOT NULL DEFAULT 1 CHECK (billing_order > 0),
	PRIMARY KEY (song_id, artist_id)
);

CREATE TABLE playlists (
	playlist_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	user_id BIGINT NOT NULL REFERENCES app_users(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
	name VARCHAR(120) NOT NULL,
	created_date DATE NOT NULL DEFAULT CURRENT_DATE,
	updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
	CONSTRAINT playlists_user_name_unique UNIQUE (user_id, name)
);

CREATE TABLE playlist_songs (
	playlist_id BIGINT NOT NULL REFERENCES playlists(playlist_id) ON UPDATE CASCADE ON DELETE CASCADE,
	song_id BIGINT NOT NULL REFERENCES songs(song_id) ON UPDATE CASCADE ON DELETE CASCADE,
	date_added TIMESTAMPTZ NOT NULL DEFAULT NOW(),
	PRIMARY KEY (playlist_id, song_id)
);

CREATE TABLE raw_tracks (
	source_row INTEGER PRIMARY KEY,
	track_id VARCHAR(64) NOT NULL,
	artists TEXT NOT NULL,
	album_name TEXT NOT NULL,
	track_name TEXT NOT NULL,
	popularity SMALLINT NOT NULL,
	duration_ms INTEGER NOT NULL,
	explicit BOOLEAN NOT NULL,
	danceability DOUBLE PRECISION NOT NULL,
	energy DOUBLE PRECISION NOT NULL,
	track_key SMALLINT NOT NULL,
	loudness DOUBLE PRECISION NOT NULL,
	mode SMALLINT NOT NULL,
	speechiness DOUBLE PRECISION NOT NULL,
	acousticness DOUBLE PRECISION NOT NULL,
	instrumentalness DOUBLE PRECISION NOT NULL,
	liveness DOUBLE PRECISION NOT NULL,
	valence DOUBLE PRECISION NOT NULL,
	tempo DOUBLE PRECISION NOT NULL,
	time_signature SMALLINT NOT NULL,
	track_genre TEXT NOT NULL
);

CREATE INDEX idx_albums_primary_artist_id ON albums(primary_artist_id);
CREATE INDEX idx_songs_album_id ON songs(album_id);
CREATE INDEX idx_songs_genre ON songs(genre);
CREATE INDEX idx_songs_popularity ON songs(popularity DESC);
CREATE INDEX idx_song_artists_artist_id ON song_artists(artist_id);
CREATE INDEX idx_playlists_user_id ON playlists(user_id);
CREATE INDEX idx_playlist_songs_song_id ON playlist_songs(song_id);

COMMIT;
