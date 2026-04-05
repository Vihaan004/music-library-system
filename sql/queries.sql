-- 1. Browse the catalog with song, artist, album, and popularity details.
SELECT
	songs.song_id,
	songs.title AS track_name,
	STRING_AGG(artists.name, ', ' ORDER BY song_artists.billing_order) AS artists,
	albums.title AS album_name,
	songs.genre,
	songs.popularity,
	songs.duration_seconds
FROM songs
JOIN albums ON albums.album_id = songs.album_id
JOIN song_artists ON song_artists.song_id = songs.song_id
JOIN artists ON artists.artist_id = song_artists.artist_id
GROUP BY songs.song_id, songs.title, albums.title, songs.genre, songs.popularity, songs.duration_seconds
ORDER BY songs.popularity DESC, songs.title
LIMIT 25;

-- 2. Find songs by a specific artist.
SELECT
	artists.name AS artist_name,
	albums.title AS album_name,
	songs.title AS track_name,
	songs.genre,
	songs.popularity
FROM songs
JOIN albums ON albums.album_id = songs.album_id
JOIN song_artists ON song_artists.song_id = songs.song_id
JOIN artists ON artists.artist_id = song_artists.artist_id
WHERE artists.name ILIKE '%Jason Mraz%'
ORDER BY songs.popularity DESC, songs.title;

-- 3. Show all songs in a chosen album.
SELECT
	albums.title AS album_name,
	songs.title AS track_name,
	songs.track_id,
	songs.duration_seconds,
	songs.explicit,
	songs.genre
FROM albums
JOIN songs ON songs.album_id = albums.album_id
WHERE albums.title = 'Love Is a Four Letter Word'
ORDER BY songs.title;

-- 4. List playlists with their owners and song counts.
SELECT
	playlists.playlist_id,
	playlists.name AS playlist_name,
	app_users.username AS owner,
	playlists.created_date,
	COUNT(playlist_songs.song_id) AS song_count
FROM playlists
JOIN app_users ON app_users.user_id = playlists.user_id
LEFT JOIN playlist_songs ON playlist_songs.playlist_id = playlists.playlist_id
GROUP BY playlists.playlist_id, playlists.name, app_users.username, playlists.created_date
ORDER BY playlists.created_date DESC, playlists.name;

-- 5. Show the contents of a playlist.
SELECT
	playlists.name AS playlist_name,
	app_users.username AS owner,
	songs.title AS track_name,
	STRING_AGG(artists.name, ', ' ORDER BY song_artists.billing_order) AS artists,
	songs.genre,
	songs.popularity,
	playlist_songs.date_added
FROM playlists
JOIN app_users ON app_users.user_id = playlists.user_id
JOIN playlist_songs ON playlist_songs.playlist_id = playlists.playlist_id
JOIN songs ON songs.song_id = playlist_songs.song_id
JOIN song_artists ON song_artists.song_id = songs.song_id
JOIN artists ON artists.artist_id = song_artists.artist_id
WHERE playlists.name = 'Top Tracks'
GROUP BY playlists.name, app_users.username, songs.song_id, songs.title, songs.genre, songs.popularity, playlist_songs.date_added
ORDER BY playlist_songs.date_added DESC, songs.popularity DESC;

-- 6. Find the most common genres in the catalog.
SELECT
	songs.genre,
	COUNT(*) AS song_count,
	ROUND(AVG(songs.popularity)::NUMERIC, 2) AS average_popularity
FROM songs
GROUP BY songs.genre
ORDER BY song_count DESC, average_popularity DESC
LIMIT 15;

-- 7. Identify the most prolific artists by track count.
SELECT
	artists.name AS artist_name,
	COUNT(*) AS track_count
FROM song_artists
JOIN artists ON artists.artist_id = song_artists.artist_id
GROUP BY artists.name
ORDER BY track_count DESC, artist_name
LIMIT 20;
