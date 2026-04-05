BEGIN;

TRUNCATE TABLE raw_tracks;

CREATE TEMP TABLE raw_tracks_import (
    source_row INTEGER,
    track_id VARCHAR(64),
    artists TEXT,
    album_name TEXT,
    track_name TEXT,
    popularity SMALLINT,
    duration_ms INTEGER,
    explicit BOOLEAN,
    danceability DOUBLE PRECISION,
    energy DOUBLE PRECISION,
    track_key SMALLINT,
    loudness DOUBLE PRECISION,
    mode SMALLINT,
    speechiness DOUBLE PRECISION,
    acousticness DOUBLE PRECISION,
    instrumentalness DOUBLE PRECISION,
    liveness DOUBLE PRECISION,
    valence DOUBLE PRECISION,
    tempo DOUBLE PRECISION,
    time_signature SMALLINT,
    track_genre TEXT
);

\copy raw_tracks_import FROM 'data/dataset.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '')

INSERT INTO raw_tracks (
    source_row,
    track_id,
    artists,
    album_name,
    track_name,
    popularity,
    duration_ms,
    explicit,
    danceability,
    energy,
    track_key,
    loudness,
    mode,
    speechiness,
    acousticness,
    instrumentalness,
    liveness,
    valence,
    tempo,
    time_signature,
    track_genre
)
SELECT
    source_row,
    btrim(track_id),
    btrim(artists),
    btrim(album_name),
    btrim(track_name),
    popularity,
    duration_ms,
    explicit,
    danceability,
    energy,
    track_key,
    loudness,
    mode,
    speechiness,
    acousticness,
    instrumentalness,
    liveness,
    valence,
    tempo,
    time_signature,
    btrim(track_genre)
FROM raw_tracks_import
WHERE source_row IS NOT NULL
  AND track_id IS NOT NULL AND btrim(track_id) <> ''
  AND artists IS NOT NULL AND btrim(artists) <> ''
  AND album_name IS NOT NULL AND btrim(album_name) <> ''
  AND track_name IS NOT NULL AND btrim(track_name) <> ''
  AND popularity IS NOT NULL AND popularity BETWEEN 0 AND 100
  AND duration_ms IS NOT NULL AND duration_ms > 0
  AND explicit IS NOT NULL
  AND danceability IS NOT NULL AND danceability BETWEEN 0 AND 1
  AND energy IS NOT NULL AND energy BETWEEN 0 AND 1
  AND track_key IS NOT NULL AND track_key BETWEEN 0 AND 11
  AND loudness IS NOT NULL
  AND mode IS NOT NULL AND mode IN (0, 1)
  AND speechiness IS NOT NULL AND speechiness BETWEEN 0 AND 1
  AND acousticness IS NOT NULL AND acousticness BETWEEN 0 AND 1
  AND instrumentalness IS NOT NULL AND instrumentalness BETWEEN 0 AND 1
  AND liveness IS NOT NULL AND liveness BETWEEN 0 AND 1
  AND valence IS NOT NULL AND valence BETWEEN 0 AND 1
  AND tempo IS NOT NULL AND tempo > 0
  AND time_signature IS NOT NULL AND time_signature BETWEEN 1 AND 12
  AND track_genre IS NOT NULL AND btrim(track_genre) <> '';

INSERT INTO artists (name)
SELECT DISTINCT btrim(artist_name) AS name
FROM raw_tracks
CROSS JOIN LATERAL unnest(string_to_array(raw_tracks.artists, ';')) AS artist_names(artist_name)
WHERE btrim(artist_name) <> ''
ORDER BY 1
ON CONFLICT (name) DO NOTHING;

INSERT INTO albums (title, primary_artist_id, release_year)
SELECT DISTINCT
    raw_tracks.album_name AS title,
    artists.artist_id AS primary_artist_id,
    NULL::INTEGER AS release_year
FROM raw_tracks
JOIN artists
    ON artists.name = btrim(split_part(raw_tracks.artists, ';', 1))
ON CONFLICT (title, primary_artist_id) DO NOTHING;

ALTER TABLE songs
DROP CONSTRAINT IF EXISTS songs_album_title_unique;

ALTER TABLE artists
ALTER COLUMN name TYPE TEXT;

ALTER TABLE albums
ALTER COLUMN title TYPE TEXT;

ALTER TABLE songs
ALTER COLUMN title TYPE TEXT;

INSERT INTO songs (
    track_id,
    album_id,
    title,
    popularity,
    duration_ms,
    explicit,
    danceability,
    energy,
    track_key,
    loudness,
    mode,
    speechiness,
    acousticness,
    instrumentalness,
    liveness,
    valence,
    tempo,
    time_signature,
    genre
)
SELECT DISTINCT ON (raw_tracks.track_id)
    raw_tracks.track_id,
    albums.album_id,
    raw_tracks.track_name,
    raw_tracks.popularity,
    raw_tracks.duration_ms,
    raw_tracks.explicit,
    raw_tracks.danceability,
    raw_tracks.energy,
    raw_tracks.track_key,
    raw_tracks.loudness,
    raw_tracks.mode,
    raw_tracks.speechiness,
    raw_tracks.acousticness,
    raw_tracks.instrumentalness,
    raw_tracks.liveness,
    raw_tracks.valence,
    raw_tracks.tempo,
    raw_tracks.time_signature,
    raw_tracks.track_genre
FROM raw_tracks
JOIN artists
    ON artists.name = btrim(split_part(raw_tracks.artists, ';', 1))
JOIN albums
    ON albums.title = raw_tracks.album_name
   AND albums.primary_artist_id = artists.artist_id
ORDER BY raw_tracks.track_id, raw_tracks.source_row
ON CONFLICT (track_id) DO NOTHING;

INSERT INTO song_artists (song_id, artist_id, billing_order)
SELECT
    songs.song_id,
    artists.artist_id,
    artists_rank.ordinality::SMALLINT
FROM raw_tracks
JOIN songs
    ON songs.track_id = raw_tracks.track_id
CROSS JOIN LATERAL unnest(string_to_array(raw_tracks.artists, ';')) WITH ORDINALITY AS artists_rank(artist_name, ordinality)
JOIN artists
    ON artists.name = btrim(artists_rank.artist_name)
ON CONFLICT (song_id, artist_id) DO NOTHING;

INSERT INTO app_users (username, email, password_hash)
VALUES
    ('ava', 'ava@example.com', '$2b$12$avaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
    ('leo', 'leo@example.com', '$2b$12$leooooooooooooooooooooooooooooooooooooooooooooooooooooooo'),
    ('mia', 'mia@example.com', '$2b$12$miaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa')
ON CONFLICT (username) DO NOTHING;

INSERT INTO playlists (user_id, name, created_date)
SELECT user_id, 'Top Tracks', CURRENT_DATE - 6
FROM app_users
WHERE username = 'ava'
ON CONFLICT (user_id, name) DO NOTHING;

INSERT INTO playlists (user_id, name, created_date)
SELECT user_id, 'Acoustic Favorites', CURRENT_DATE - 4
FROM app_users
WHERE username = 'mia'
ON CONFLICT (user_id, name) DO NOTHING;

INSERT INTO playlists (user_id, name, created_date)
SELECT user_id, 'High Energy Mix', CURRENT_DATE - 2
FROM app_users
WHERE username = 'leo'
ON CONFLICT (user_id, name) DO NOTHING;

INSERT INTO playlist_songs (playlist_id, song_id)
SELECT playlists.playlist_id, ranked.song_id
FROM playlists
JOIN LATERAL (
    SELECT songs.song_id
    FROM songs
    ORDER BY songs.popularity DESC, songs.song_id
    LIMIT 12
) AS ranked ON TRUE
WHERE playlists.name = 'Top Tracks'
ON CONFLICT (playlist_id, song_id) DO NOTHING;

INSERT INTO playlist_songs (playlist_id, song_id)
SELECT playlists.playlist_id, ranked.song_id
FROM playlists
JOIN LATERAL (
    SELECT songs.song_id
    FROM songs
    WHERE songs.genre = 'acoustic'
    ORDER BY songs.popularity DESC, songs.song_id
    LIMIT 12
) AS ranked ON TRUE
WHERE playlists.name = 'Acoustic Favorites'
ON CONFLICT (playlist_id, song_id) DO NOTHING;

INSERT INTO playlist_songs (playlist_id, song_id)
SELECT playlists.playlist_id, ranked.song_id
FROM playlists
JOIN LATERAL (
    SELECT songs.song_id
    FROM songs
    WHERE songs.energy >= 0.75
    ORDER BY songs.popularity DESC, songs.song_id
    LIMIT 12
) AS ranked ON TRUE
WHERE playlists.name = 'High Energy Mix'
ON CONFLICT (playlist_id, song_id) DO NOTHING;

COMMIT;