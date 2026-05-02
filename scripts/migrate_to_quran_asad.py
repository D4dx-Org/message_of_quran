import sqlite3
import os

DB_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'db')
ASAD_DB = os.path.join(DB_DIR, 'quran_asad.sqlite')
MAL_DB = os.path.join(DB_DIR, 'quran_malayalam_.db')

mal_conn = sqlite3.connect(MAL_DB)
asad_conn = sqlite3.connect(ASAD_DB)
mal_cur = mal_conn.cursor()
asad_cur = asad_conn.cursor()

# 1. Add arabic_name and ayath_count columns to surahs
asad_cur.execute("PRAGMA table_info(surahs)")
columns = [col[1] for col in asad_cur.fetchall()]
if 'arabic_name' not in columns:
    asad_cur.execute("ALTER TABLE surahs ADD COLUMN arabic_name TEXT DEFAULT ''")
    print("Added arabic_name column")
else:
    print("arabic_name already exists")
if 'ayath_count' not in columns:
    asad_cur.execute("ALTER TABLE surahs ADD COLUMN ayath_count INTEGER DEFAULT 0")
    print("Added ayath_count column")
else:
    print("ayath_count already exists")

# 2. Populate arabic_name and ayath_count from quran_malayalam_.db
mal_cur.execute("SELECT sura_number, arabic_name, ayath_count FROM suras")
for sn, an, ac in mal_cur.fetchall():
    asad_cur.execute(
        "UPDATE surahs SET arabic_name = ?, ayath_count = ? WHERE number = ?",
        (an or '', ac or 0, sn)
    )
print("Migrated arabic names + ayath counts")

# 3. Copy arabic_ayahs table
asad_cur.execute("DROP TABLE IF EXISTS arabic_ayahs")
asad_cur.execute(
    "CREATE TABLE arabic_ayahs ("
    "chapter_no INTEGER, verse_from INTEGER, verse_to INTEGER, data_arabic TEXT)"
)
mal_cur.execute("SELECT chapter_no, verse_from, verse_to, data_arabic FROM arabic_ayahs")
rows = mal_cur.fetchall()
asad_cur.executemany("INSERT INTO arabic_ayahs VALUES (?, ?, ?, ?)", rows)
print(f"Migrated {len(rows)} arabic_ayahs rows")

# 4. Copy tajweed_words table
asad_cur.execute("DROP TABLE IF EXISTS tajweed_words")
asad_cur.execute(
    "CREATE TABLE tajweed_words ("
    "surah_no INTEGER, ayah_no INTEGER, word_pos INTEGER, word_text TEXT, image_url TEXT)"
)
mal_cur.execute("SELECT surah_no, ayah_no, word_pos, word_text, image_url FROM tajweed_words")
tj = mal_cur.fetchall()
asad_cur.executemany("INSERT INTO tajweed_words VALUES (?, ?, ?, ?, ?)", tj)
print(f"Migrated {len(tj)} tajweed rows")

# 5. Copy juzzs and hizbs tables
for t in ['juzzs', 'hizbs']:
    asad_cur.execute(f"DROP TABLE IF EXISTS {t}")
    asad_cur.execute(
        f"CREATE TABLE {t} (custom_id INTEGER, chapter_no INTEGER, verse_no INTEGER)"
    )
    mal_cur.execute(f"SELECT custom_id, chapter_no, verse_no FROM {t}")
    r = mal_cur.fetchall()
    asad_cur.executemany(f"INSERT INTO {t} VALUES (?, ?, ?)", r)
    print(f"Migrated {len(r)} {t} rows")

asad_conn.commit()

# Verify
print("\n--- Verification ---")
asad_cur.execute("SELECT number, name, arabic_name, ayath_count FROM surahs LIMIT 3")
for r in asad_cur.fetchall():
    print(f"  Surah {r[0]}: {r[1]} | {r[2]} | {r[3]} ayahs")
asad_cur.execute("SELECT COUNT(*) FROM arabic_ayahs")
print(f"  arabic_ayahs: {asad_cur.fetchone()[0]}")
asad_cur.execute("SELECT COUNT(*) FROM tajweed_words")
print(f"  tajweed_words: {asad_cur.fetchone()[0]}")
asad_cur.execute("SELECT COUNT(*) FROM juzzs")
print(f"  juzzs: {asad_cur.fetchone()[0]}")
asad_cur.execute("SELECT COUNT(*) FROM hizbs")
print(f"  hizbs: {asad_cur.fetchone()[0]}")

mal_conn.close()
asad_conn.close()
print("\nMIGRATION COMPLETE")
