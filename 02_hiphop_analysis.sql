-- ================================================================
--  HIP-HOP MUSIC ANALYSIS — SQL QUERIES
--  File: 02_hiphop_analysis.sql
--
--  Run these in DB Browser for SQLite after opening hiphop_store.db
--
--  TIP: Highlight any single query and press Ctrl+Enter
--       to run just that one. Don't run the whole file at once.
-- ================================================================


-- ================================================================
--  CHAPTER 1: GET YOUR BEARINGS
--  First look at what's in the database
-- ================================================================

-- QUERY 1: What genres do we have?
SELECT *
FROM genres;

-- QUERY 2: How many of everything do we have?
SELECT
    (SELECT COUNT(*) FROM artists) AS total_artists,
    (SELECT COUNT(*) FROM albums)  AS total_albums,
    (SELECT COUNT(*) FROM tracks)  AS total_tracks;

-- QUERY 3: Preview the tracks table — what columns are there?
SELECT *
FROM tracks
LIMIT 10;

-- QUERY 4: What does the audio data look like for a few tracks?
-- danceability, energy, valence are all 0.0 to 1.0
-- tempo is BPM, loudness is in decibels
SELECT
    t.track_name,
    ar.artist_name,
    t.popularity,
    t.danceability,
    t.energy,
    t.tempo,
    t.valence
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
LIMIT 15;

-- QUERY 5: What's the range of each audio feature?
-- This gives you a feel for what "high" and "low" mean
SELECT
    ROUND(MIN(danceability), 2)  AS dance_min,
    ROUND(MAX(danceability), 2)  AS dance_max,
    ROUND(AVG(danceability), 2)  AS dance_avg,
    ROUND(MIN(energy), 2)        AS energy_min,
    ROUND(MAX(energy), 2)        AS energy_max,
    ROUND(AVG(energy), 2)        AS energy_avg,
    ROUND(MIN(tempo), 1)         AS bpm_min,
    ROUND(MAX(tempo), 1)         AS bpm_max,
    ROUND(AVG(tempo), 1)         AS bpm_avg,
    ROUND(MIN(popularity), 0)    AS pop_min,
    ROUND(MAX(popularity), 0)    AS pop_max,
    ROUND(AVG(popularity), 1)    AS pop_avg
FROM tracks;


-- ================================================================
--  CHAPTER 2: ARTIST ANALYSIS
--  Who's the biggest? Who puts out the most music?
-- ================================================================

-- QUERY 6: How many tracks does each artist have?
SELECT
    ar.artist_name,
    COUNT(*) AS track_count
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
GROUP BY ar.artist_id, ar.artist_name
ORDER BY track_count DESC
LIMIT 20;

-- QUERY 7: How many albums does each artist have?
SELECT
    ar.artist_name,
    COUNT(DISTINCT al.album_id) AS album_count,
    COUNT(t.track_id)           AS total_tracks
FROM artists AS ar
JOIN albums  AS al ON ar.artist_id = al.artist_id
JOIN tracks  AS t  ON al.album_id  = t.album_id
GROUP BY ar.artist_id, ar.artist_name
ORDER BY album_count DESC
LIMIT 20;

-- QUERY 8: Average Spotify popularity per artist
-- (Only artists with 5+ tracks, so we're not fooled by one viral hit)
SELECT
    ar.artist_name,
    COUNT(*)                      AS tracks,
    ROUND(AVG(t.popularity), 1)   AS avg_popularity,
    MAX(t.popularity)             AS peak_popularity
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
GROUP BY ar.artist_id, ar.artist_name
HAVING tracks >= 5
ORDER BY avg_popularity DESC
LIMIT 20;

-- QUERY 9: Artists with the most explicit tracks
-- speechiness > 0.66 generally means mostly spoken word (very rap-like)
SELECT
    ar.artist_name,
    COUNT(*)                                     AS total_tracks,
    SUM(t.explicit)                              AS explicit_tracks,
    ROUND(SUM(t.explicit) * 100.0 / COUNT(*), 1) AS pct_explicit
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
GROUP BY ar.artist_id, ar.artist_name
HAVING total_tracks >= 5
ORDER BY pct_explicit DESC
LIMIT 15;


-- ================================================================
--  CHAPTER 3: TRACK DEEP DIVES
--  Finding specific tracks by audio features
-- ================================================================

-- QUERY 10: Top 20 most popular tracks overall
SELECT
    t.track_name,
    ar.artist_name,
    al.album_name,
    t.popularity
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
JOIN albums  AS al ON t.album_id  = al.album_id
ORDER BY t.popularity DESC
LIMIT 20;

-- QUERY 11: Most DANCEABLE tracks (great playlist material)
-- danceability close to 1.0 = very danceable
SELECT
    t.track_name,
    ar.artist_name,
    ROUND(t.danceability, 3) AS danceability,
    ROUND(t.energy, 3)       AS energy,
    ROUND(t.tempo, 1)        AS bpm,
    t.popularity
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
ORDER BY t.danceability DESC
LIMIT 20;

-- QUERY 12: Most ENERGETIC tracks (hype / workout music)
SELECT
    t.track_name,
    ar.artist_name,
    ROUND(t.energy, 3)       AS energy,
    ROUND(t.loudness, 1)     AS loudness_db,
    ROUND(t.tempo, 1)        AS bpm
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
ORDER BY t.energy DESC
LIMIT 20;

-- QUERY 13: Most "RAP-LIKE" tracks by speechiness score
-- Spotify uses speechiness to detect spoken word content
-- > 0.66 = mostly speech, 0.33–0.66 = music AND speech, < 0.33 = music
SELECT
    t.track_name,
    ar.artist_name,
    ROUND(t.speechiness, 3) AS speechiness,
    t.popularity
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
WHERE t.speechiness > 0.33
ORDER BY t.speechiness DESC
LIMIT 20;

-- QUERY 14: HAPPIEST tracks (high valence = more positive/upbeat mood)
-- Low valence = darker/sadder tone (think drill or emo rap)
SELECT
    t.track_name,
    ar.artist_name,
    ROUND(t.valence, 3)      AS happiness_score,
    ROUND(t.danceability, 3) AS danceability,
    t.popularity
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
ORDER BY t.valence DESC
LIMIT 15;

-- QUERY 15: DARKEST / most melancholy tracks (low valence)
SELECT
    t.track_name,
    ar.artist_name,
    ROUND(t.valence, 3)  AS happiness_score,
    ROUND(t.energy, 3)   AS energy,
    t.popularity
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
ORDER BY t.valence ASC
LIMIT 15;

-- QUERY 16: Longest tracks (rap has some LONG songs)
-- duration_sec / 60 converts seconds to minutes
SELECT
    t.track_name,
    ar.artist_name,
    al.album_name,
    ROUND(t.duration_sec / 60.0, 2) AS duration_mins
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
JOIN albums  AS al ON t.album_id  = al.album_id
ORDER BY t.duration_sec DESC
LIMIT 15;

-- QUERY 17: BPM distribution — what tempos are most common in rap?
-- We bucket the BPM into ranges using CASE WHEN
SELECT
    CASE
        WHEN tempo < 70  THEN '< 70 BPM (very slow)'
        WHEN tempo < 90  THEN '70–89 BPM (slow)'
        WHEN tempo < 110 THEN '90–109 BPM (mid)'
        WHEN tempo < 130 THEN '110–129 BPM (uptempo)'
        WHEN tempo < 150 THEN '130–149 BPM (fast)'
        ELSE                  '150+ BPM (very fast)'
    END AS bpm_range,
    COUNT(*) AS track_count
FROM tracks
GROUP BY bpm_range
ORDER BY MIN(tempo);
-- CASE WHEN is like an IF statement — super useful!


-- ================================================================
--  CHAPTER 4: ALBUM ANALYSIS
-- ================================================================

-- QUERY 18: Which albums have the most tracks?
SELECT
    al.album_name,
    ar.artist_name,
    COUNT(*) AS track_count,
    ROUND(AVG(t.popularity), 1) AS avg_track_popularity
FROM albums AS al
JOIN artists AS ar ON al.artist_id = ar.artist_id
JOIN tracks  AS t  ON al.album_id  = t.album_id
GROUP BY al.album_id, al.album_name, ar.artist_name
ORDER BY track_count DESC
LIMIT 20;

-- QUERY 19: Most consistent albums (highest avg popularity with 8+ tracks)
-- A high average means no filler — every track is solid
SELECT
    al.album_name,
    ar.artist_name,
    COUNT(*)                      AS tracks,
    ROUND(AVG(t.popularity), 1)   AS avg_popularity,
    MIN(t.popularity)             AS lowest_track,
    MAX(t.popularity)             AS highest_track
FROM albums AS al
JOIN artists AS ar ON al.artist_id = ar.artist_id
JOIN tracks  AS t  ON al.album_id  = t.album_id
GROUP BY al.album_id, al.album_name, ar.artist_name
HAVING tracks >= 8
ORDER BY avg_popularity DESC
LIMIT 15;

-- QUERY 20: Album vibes — audio fingerprint per album
-- This tells you the "feel" of an album at a glance
SELECT
    al.album_name,
    ar.artist_name,
    COUNT(*)                         AS tracks,
    ROUND(AVG(t.danceability), 2)    AS avg_danceability,
    ROUND(AVG(t.energy), 2)          AS avg_energy,
    ROUND(AVG(t.valence), 2)         AS avg_valence,
    ROUND(AVG(t.tempo), 1)           AS avg_bpm,
    ROUND(AVG(t.speechiness), 3)     AS avg_speechiness
FROM albums AS al
JOIN artists AS ar ON al.artist_id = ar.artist_id
JOIN tracks  AS t  ON al.album_id  = t.album_id
GROUP BY al.album_id, al.album_name, ar.artist_name
HAVING tracks >= 5
ORDER BY avg_danceability DESC
LIMIT 20;


-- ================================================================
--  CHAPTER 5: FILTERING & COMBINING CONDITIONS
--  WHERE with AND, OR, BETWEEN — the power moves
-- ================================================================

-- QUERY 21: Banger filter — popular AND danceable AND energetic
-- This is how you'd build a "banger" playlist
SELECT
    t.track_name,
    ar.artist_name,
    t.popularity,
    ROUND(t.danceability, 2) AS dance,
    ROUND(t.energy, 2)       AS energy
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
WHERE t.popularity    >= 70
  AND t.danceability  >= 0.7
  AND t.energy        >= 0.6
ORDER BY t.popularity DESC;

-- QUERY 22: Chill rap — popular tracks with lower energy and higher valence
SELECT
    t.track_name,
    ar.artist_name,
    t.popularity,
    ROUND(t.energy, 2)   AS energy,
    ROUND(t.valence, 2)  AS valence,
    ROUND(t.tempo, 1)    AS bpm
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
WHERE t.energy  < 0.5
  AND t.valence > 0.5
  AND t.popularity > 50
ORDER BY t.valence DESC
LIMIT 20;

-- QUERY 23: BETWEEN — tracks in a specific BPM range (classic rap tempo)
SELECT
    t.track_name,
    ar.artist_name,
    ROUND(t.tempo, 1)        AS bpm,
    ROUND(t.danceability, 2) AS danceability,
    t.popularity
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
WHERE t.tempo BETWEEN 85 AND 100    -- classic boom-bap range
ORDER BY t.popularity DESC
LIMIT 20;

-- QUERY 24: Find a specific artist's tracks (change the name!)
-- LIKE with % is a wildcard — finds anything containing "Drake"
SELECT
    t.track_name,
    al.album_name,
    t.popularity,
    ROUND(t.danceability, 2) AS danceability,
    ROUND(t.energy, 2)       AS energy
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
JOIN albums  AS al ON t.album_id  = al.album_id
WHERE ar.artist_name LIKE '%Drake%'   -- <- Change this to any artist!
ORDER BY t.popularity DESC;


-- ================================================================
--  CHAPTER 6: AGGREGATIONS & GROUPING
-- ================================================================

-- QUERY 25: Clean vs explicit tracks breakdown
SELECT
    CASE WHEN explicit = 1 THEN 'Explicit' ELSE 'Clean' END AS type,
    COUNT(*)                      AS track_count,
    ROUND(AVG(popularity), 1)     AS avg_popularity,
    ROUND(AVG(danceability), 2)   AS avg_danceability,
    ROUND(AVG(energy), 2)         AS avg_energy
FROM tracks
GROUP BY explicit;

-- QUERY 26: Hip-hop vs rap comparison (audio characteristics by genre)
SELECT
    g.genre_name,
    COUNT(*)                      AS tracks,
    ROUND(AVG(t.popularity), 1)   AS avg_popularity,
    ROUND(AVG(t.danceability), 2) AS avg_danceability,
    ROUND(AVG(t.energy), 2)       AS avg_energy,
    ROUND(AVG(t.tempo), 1)        AS avg_bpm,
    ROUND(AVG(t.speechiness), 3)  AS avg_speechiness,
    ROUND(AVG(t.valence), 2)      AS avg_valence
FROM tracks AS t
JOIN genres AS g ON t.genre_id = g.genre_id
GROUP BY g.genre_id, g.genre_name;

-- QUERY 27: Popularity distribution — how many tracks at each tier?
SELECT
    CASE
        WHEN popularity >= 80 THEN '80–100 (viral)'
        WHEN popularity >= 60 THEN '60–79  (popular)'
        WHEN popularity >= 40 THEN '40–59  (decent)'
        WHEN popularity >= 20 THEN '20–39  (niche)'
        ELSE                       '0–19   (obscure)'
    END AS popularity_tier,
    COUNT(*) AS tracks
FROM tracks
GROUP BY popularity_tier
ORDER BY MIN(popularity) DESC;

-- QUERY 28: Artists sorted by "vibe" — who makes the most energetic music?
SELECT
    ar.artist_name,
    COUNT(*)                      AS tracks,
    ROUND(AVG(t.energy), 2)       AS avg_energy,
    ROUND(AVG(t.danceability), 2) AS avg_dance,
    ROUND(AVG(t.valence), 2)      AS avg_vibe,
    ROUND(AVG(t.tempo), 1)        AS avg_bpm
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
GROUP BY ar.artist_id, ar.artist_name
HAVING tracks >= 10
ORDER BY avg_energy DESC
LIMIT 20;


-- ================================================================
--  CHAPTER 7: SUBQUERIES — Advanced analysis
-- ================================================================

-- QUERY 29: Tracks more popular than the genre average
-- Inner query calculates the average; outer query filters against it
SELECT
    t.track_name,
    ar.artist_name,
    g.genre_name,
    t.popularity,
    ROUND((SELECT AVG(popularity) FROM tracks), 1) AS overall_avg
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
JOIN genres  AS g  ON t.genre_id  = g.genre_id
WHERE t.popularity > (SELECT AVG(popularity) FROM tracks)
ORDER BY t.popularity DESC
LIMIT 25;

-- QUERY 30: The most popular track for EACH artist
-- This is a classic "greatest per group" pattern
SELECT
    ar.artist_name,
    t.track_name,
    t.popularity
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
WHERE t.popularity = (
    -- For this artist, find their max popularity score
    SELECT MAX(t2.popularity)
    FROM tracks AS t2
    WHERE t2.artist_id = t.artist_id
)
ORDER BY t.popularity DESC
LIMIT 30;

-- QUERY 31: Artists whose avg danceability beats the overall average
SELECT
    ar.artist_name,
    COUNT(*)                     AS tracks,
    ROUND(AVG(t.danceability), 3) AS avg_danceability
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
GROUP BY ar.artist_id, ar.artist_name
HAVING avg_danceability > (SELECT AVG(danceability) FROM tracks)
   AND tracks >= 10
ORDER BY avg_danceability DESC
LIMIT 20;


-- ================================================================
--  CHAPTER 8: REAL ANALYSIS — Questions a music exec would ask
-- ================================================================

-- QUERY 32: The "perfect banger" score
-- Combine danceability + energy + popularity into one score
-- This is called a derived / calculated column
SELECT
    t.track_name,
    ar.artist_name,
    t.popularity,
    ROUND(t.danceability, 2)                                        AS dance,
    ROUND(t.energy, 2)                                              AS energy,
    ROUND((t.danceability + t.energy + t.popularity/100.0) / 3, 3) AS banger_score
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
ORDER BY banger_score DESC
LIMIT 20;

-- QUERY 33: Hidden gems — high danceability but LOW popularity (underrated!)
SELECT
    t.track_name,
    ar.artist_name,
    t.popularity,
    ROUND(t.danceability, 2) AS danceability,
    ROUND(t.energy, 2)       AS energy
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
WHERE t.danceability > 0.80
  AND t.popularity   < 40
ORDER BY t.danceability DESC
LIMIT 20;

-- QUERY 34: Artist versatility — which artists have the WIDEST range of sounds?
-- High standard deviation in valence/energy = very versatile
-- We approximate this with MAX - MIN as a "range" score
SELECT
    ar.artist_name,
    COUNT(*)                                       AS tracks,
    ROUND(MAX(t.energy)   - MIN(t.energy), 2)      AS energy_range,
    ROUND(MAX(t.valence)  - MIN(t.valence), 2)     AS mood_range,
    ROUND(MAX(t.tempo)    - MIN(t.tempo), 1)       AS bpm_range
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
GROUP BY ar.artist_id, ar.artist_name
HAVING tracks >= 10
ORDER BY mood_range DESC
LIMIT 20;

-- QUERY 35: THE FULL PICTURE — one row tells you everything about a track
SELECT
    t.track_name,
    ar.artist_name,
    al.album_name,
    g.genre_name,
    t.popularity,
    ROUND(t.duration_sec / 60.0, 2)  AS duration_mins,
    CASE WHEN t.explicit = 1 THEN 'Yes' ELSE 'No' END AS explicit,
    ROUND(t.danceability, 2)          AS danceability,
    ROUND(t.energy, 2)                AS energy,
    ROUND(t.valence, 2)               AS mood,
    ROUND(t.speechiness, 3)           AS speechiness,
    ROUND(t.tempo, 1)                 AS bpm,
    ROUND(t.loudness, 1)              AS loudness_db
FROM tracks AS t
JOIN artists AS ar ON t.artist_id = ar.artist_id
JOIN albums  AS al ON t.album_id  = al.album_id
JOIN genres  AS g  ON t.genre_id  = g.genre_id
ORDER BY t.popularity DESC
LIMIT 30;


-- ================================================================
--  CHALLENGE QUERIES — Try writing these yourself!
-- ================================================================

-- CHALLENGE 1:
-- Which artist has the highest SINGLE track popularity score?
-- (Just one track, their absolute peak)

-- CHALLENGE 2:
-- List all tracks where danceability > energy.
-- How many are there? Which artist appears most?

-- CHALLENGE 3:
-- What's the average track length (in minutes) per artist?
-- Show only artists with at least 10 tracks.

-- CHALLENGE 4:
-- Find tracks where tempo is between 160–180 BPM AND energy > 0.8.
-- These are the absolute hype tracks.

-- CHALLENGE 5:
-- Which album has the highest ratio of explicit tracks?
-- (Only albums with 5+ tracks)
