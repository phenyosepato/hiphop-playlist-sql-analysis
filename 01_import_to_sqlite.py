# ================================================================
#  HIP-HOP MUSIC STORE — DATA IMPORT SCRIPT
#  File: 01_import_to_sqlite.py
#
#  WHAT THIS DOES:
#  Reads the Spotify CSV you downloaded from Kaggle, filters it
#  down to hip-hop and rap tracks, splits it into clean tables,
#  and saves everything into a SQLite database file.
#
#  HOW TO SET UP IN VISUAL STUDIO 2022:
#  1. Open VS 2022
#  2. Go to: Tools → Get Tools and Features
#  3. Make sure "Python development" workload is installed
#     (if not, tick it and hit Modify — takes a few minutes)
#  4. Create a new project: Python → Python Application
#  5. Paste this file in, OR: File → Open → File → pick this file
#  6. Open the Terminal: View → Terminal
#  7. Run this command to install the one library you need:
#        pip install pandas
#  8. Put the downloaded CSV file (dataset.csv) in the SAME
#     folder as this script
#  9. Press F5 (or the green Run button) to run the script
#  10. You'll see a hiphop_store.db file appear in that folder
#      — open THAT file in DB Browser for SQLite!
#
#  REQUIREMENTS:
#    pip install pandas
#    Python 3.8+  (comes with VS 2022 Python workload)
# ================================================================

import pandas as pd
import sqlite3
import os

# ----------------------------------------------------------------
# STEP 1 — Load the CSV from Kaggle
# ----------------------------------------------------------------
# The Kaggle dataset filename is "dataset.csv"
# Make sure it's in the same folder as this script!

CSV_FILE = "dataset.csv"
DB_FILE  = "hiphop_store.db"

print("=" * 55)
print("  HIP-HOP DATABASE BUILDER")
print("=" * 55)

# Check the CSV exists before trying to open it
if not os.path.exists(CSV_FILE):
    print(f"\nERROR: Could not find '{CSV_FILE}'")
    print("Make sure you placed the Kaggle CSV in the same")
    print("folder as this script, and that it's named dataset.csv")
    exit()

print(f"\n[1/6] Loading {CSV_FILE} ...")
df = pd.read_csv(CSV_FILE)
print(f"      Loaded {len(df):,} total tracks across all genres")


# ----------------------------------------------------------------
# STEP 2 — Filter to hip-hop and rap only
# ----------------------------------------------------------------
print("\n[2/6] Filtering to hip-hop and rap ...")

# The 'track_genre' column has values like 'hip-hop', 'rap', 'pop', etc.
hiphop_df = df[df['track_genre'].isin(['hip-hop', 'rap'])].copy()

# Drop duplicate track IDs (some tracks appear in multiple genre lists)
hiphop_df = hiphop_df.drop_duplicates(subset='track_id')

# Reset the index so row numbers are clean
hiphop_df = hiphop_df.reset_index(drop=True)

print(f"      Found {len(hiphop_df):,} hip-hop / rap tracks")


# ----------------------------------------------------------------
# STEP 3 — Clean up the data
# ----------------------------------------------------------------
print("\n[3/6] Cleaning data ...")

# The 'artists' column can have multiple artists like "Drake;Lil Wayne"
# We'll take just the first (primary) artist for simplicity
hiphop_df['primary_artist'] = (
    hiphop_df['artists']
    .str.split(';')
    .str[0]
    .str.strip()
)

# Convert duration from milliseconds to seconds (easier to read)
hiphop_df['duration_sec'] = (hiphop_df['duration_ms'] / 1000).round(0).astype(int)

# Convert the explicit column to 1 (yes) or 0 (no)
hiphop_df['explicit'] = hiphop_df['explicit'].astype(int)

print("      Done — artists cleaned, duration converted to seconds")


# ----------------------------------------------------------------
# STEP 4 — Build the normalized tables
#
# Instead of one giant flat table, we split into clean tables
# that link to each other. This is "normalization" — the same
# thing you'd do in a real database.
# ----------------------------------------------------------------
print("\n[4/6] Building normalized tables ...")

# --- GENRES table ---
# Just the unique genre names (hip-hop, rap)
genres = pd.DataFrame({
    'genre_id':   range(1, hiphop_df['track_genre'].nunique() + 1),
    'genre_name': hiphop_df['track_genre'].unique()
})
print(f"      genres:  {len(genres)} rows")

# --- ARTISTS table ---
# One row per unique artist name
unique_artists = hiphop_df['primary_artist'].unique()
artists = pd.DataFrame({
    'artist_id':   range(1, len(unique_artists) + 1),
    'artist_name': unique_artists
})
print(f"      artists: {len(artists)} rows")

# --- ALBUMS table ---
# One row per unique album, linked to its primary artist
albums_raw = (
    hiphop_df[['album_name', 'primary_artist']]
    .drop_duplicates()
    .merge(artists, left_on='primary_artist', right_on='artist_name')
    [['album_name', 'artist_id']]
    .reset_index(drop=True)
)
albums = albums_raw.copy()
albums.insert(0, 'album_id', range(1, len(albums) + 1))
print(f"      albums:  {len(albums)} rows")

# --- TRACKS table ---
# The main table — one row per track, with foreign keys to all other tables
tracks_merged = (
    hiphop_df
    .merge(artists, left_on='primary_artist', right_on='artist_name')
    .merge(genres,  left_on='track_genre',    right_on='genre_name')
    .merge(albums,  on=['album_name', 'artist_id'], how='left')
)

tracks = tracks_merged[[
    'track_id',
    'track_name',
    'artist_id',
    'album_id',
    'genre_id',
    'popularity',       # 0–100 Spotify popularity score
    'duration_sec',     # length in seconds
    'explicit',         # 1 = explicit, 0 = clean
    'danceability',     # 0–1 how suitable for dancing
    'energy',           # 0–1 intensity and activity
    'loudness',         # dB (usually -60 to 0)
    'speechiness',      # 0–1 presence of spoken words (high = more rap-like)
    'acousticness',     # 0–1 confidence it's acoustic
    'valence',          # 0–1 musical positivity / happiness
    'tempo'             # BPM (beats per minute)
]].copy()

# Remove any tracks where album_id didn't match (very rare)
tracks = tracks.dropna(subset=['album_id'])
tracks['album_id'] = tracks['album_id'].astype(int)

print(f"      tracks:  {len(tracks):,} rows")


# ----------------------------------------------------------------
# STEP 5 — Write everything to SQLite
# ----------------------------------------------------------------
print(f"\n[5/6] Writing to {DB_FILE} ...")

# Delete old database if it exists (so we get a fresh start)
if os.path.exists(DB_FILE):
    os.remove(DB_FILE)
    print(f"      (Deleted old {DB_FILE} to start fresh)")

conn = sqlite3.connect(DB_FILE)

# if_exists='replace' means: drop and recreate the table each time
genres.to_sql('genres',   conn, if_exists='replace', index=False)
artists.to_sql('artists', conn, if_exists='replace', index=False)
albums.to_sql('albums',   conn, if_exists='replace', index=False)
tracks.to_sql('tracks',   conn, if_exists='replace', index=False)

conn.close()
print("      All tables written successfully!")


# ----------------------------------------------------------------
# STEP 6 — Quick verification
# ----------------------------------------------------------------
print("\n[6/6] Verifying the database ...")
conn = sqlite3.connect(DB_FILE)

for table in ['genres', 'artists', 'albums', 'tracks']:
    count = pd.read_sql(f"SELECT COUNT(*) AS n FROM {table}", conn).iloc[0]['n']
    print(f"      {table:<10} {count:>6,} rows")

conn.close()

print("\n" + "=" * 55)
print("  SUCCESS! Your database is ready.")
print(f"  File: {DB_FILE}")
print("")
print("  Next step:")
print("  Open DB Browser for SQLite → Open Database")
print(f"  → navigate to this folder → select {DB_FILE}")
print("=" * 55)
