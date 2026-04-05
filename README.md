## Music Library System Database

This repository contains the PostgreSQL schema, sample data loader, CRUD demo, and query examples for the Music Library System phase.

### Files

- [sql/ddl.sql](sql/ddl.sql) creates the relational schema, constraints, indexes, and a staging table for the CSV import.
- [sql/data_load.sql](sql/data_load.sql) imports [data/dataset.csv](data/dataset.csv), normalizes artists/albums/songs, and seeds sample users and playlists.
- [sql/crud.sql](sql/crud.sql) demonstrates basic create, update, and delete operations.
- [sql/queries.sql](sql/queries.sql) contains read queries that match realistic application use cases.

### How to run in psql

Start psql from the repository root, then connect to your database:
(Make sure you have created `music_library_database` in PostgreSQL before running these commands.)

```bash
psql -U postgres -d music_library_database
```

Inside psql, run the scripts in this order:

```sql
\i sql/ddl.sql
\i sql/data_load.sql
\i sql/crud.sql
\i sql/queries.sql
```

If you are using Windows psql and see an encoding error during CSV load, run this once before `\i sql/data_load.sql`:

```sql
\encoding UTF8
```

If you want to inspect the schema after loading, use:

```sql
\dt
\d artists
\d albums
\d songs
\d playlists
```

### Notes

- The CSV contains a leading row index column, so the loader uses a staging table that matches the file layout exactly.
- The loader first imports to a temporary raw table and filters out incomplete/malformed rows before inserting into `raw_tracks`.
- `songs.track_id` is the canonical unique key; duplicate song titles within the same album are allowed because the source data includes such cases.
- The schema keeps the ER design entities, but it also adds `song_artists` so collaboration credits from the CSV can be preserved.
- Playlist data is seeded with sample users so the many-to-many relationship can be demonstrated immediately.
