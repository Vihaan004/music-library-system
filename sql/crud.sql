BEGIN;

INSERT INTO app_users (username, email, password_hash)
VALUES ('demo_user', 'demo_user@example.com', '$2b$12$demodemo_demo_demo_demo_demo_demo_demo_demo_demo_demo_d');

INSERT INTO playlists (user_id, name)
SELECT user_id, 'Weekend Queue'
FROM app_users
WHERE username = 'demo_user';

INSERT INTO playlist_songs (playlist_id, song_id)
SELECT playlists.playlist_id, songs.song_id
FROM playlists
JOIN songs ON songs.genre = 'acoustic'
WHERE playlists.name = 'Weekend Queue'
ORDER BY songs.popularity DESC, songs.song_id
LIMIT 1;

UPDATE playlists
SET name = 'Weekend Favorites', updated_at = NOW()
WHERE name = 'Weekend Queue'
  AND user_id = (SELECT user_id FROM app_users WHERE username = 'demo_user');

DELETE FROM playlist_songs
WHERE playlist_id = (
    SELECT playlist_id
    FROM playlists
    WHERE name = 'Weekend Favorites'
      AND user_id = (SELECT user_id FROM app_users WHERE username = 'demo_user')
)
AND song_id = (
    SELECT songs.song_id
    FROM songs
    WHERE songs.genre = 'acoustic'
    ORDER BY songs.popularity DESC, songs.song_id
    LIMIT 1
);

DELETE FROM playlists
WHERE name = 'Weekend Favorites'
  AND user_id = (SELECT user_id FROM app_users WHERE username = 'demo_user');

DELETE FROM app_users
WHERE username = 'demo_user';

COMMIT;