import sqlite3
import os

DB_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'db')
ASAD_DB = os.path.join(DB_DIR, 'quran_asad.sqlite')
MAL_DB = os.path.join(DB_DIR, 'quran_malayalam_.db')

mal_conn = sqlite3.connect(MAL_DB)
asad_conn = sqlite3.connect(ASAD_DB)
mal_cur = mal_conn.cursor()
asad_cur = asad_conn.cursor()

# 1. Add malayalam_name column to surahs (if not exists)
asad_cur.execute("PRAGMA table_info(surahs)")
columns = [col[1] for col in asad_cur.fetchall()]
if 'malayalam_name' not in columns:
    asad_cur.execute("ALTER TABLE surahs ADD COLUMN malayalam_name TEXT DEFAULT ''")
    print("Added malayalam_name column")
else:
    print("malayalam_name column already exists")

# 2. Populate malayalam_name from quran_malayalam_.db suras.name
mal_cur.execute("SELECT sura_number, name FROM suras")
rows = mal_cur.fetchall()
for sn, name in rows:
    asad_cur.execute(
        "UPDATE surahs SET malayalam_name = ? WHERE number = ?",
        (name or '', sn)
    )
print(f"Migrated {len(rows)} malayalam surah names")

asad_conn.commit()

# 3. Verify
print("\n--- Verification ---")
asad_cur.execute("SELECT number, name, malayalam_name FROM surahs LIMIT 5")
for r in asad_cur.fetchall():
    print(f"  Surah {r[0]}: {r[1]} | {r[2]}")

mal_conn.close()
asad_conn.close()
print("\nDone!")
