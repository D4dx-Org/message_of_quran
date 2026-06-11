import sqlite3
import shutil
import os

DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'assets', 'db', 'quran_asad_combined_nw.sqlite')

conn = sqlite3.connect(DB_PATH)

# Show current values before update
print('Before:')
rows = conn.execute(
    'SELECT chapter_number, revelation_period FROM malayalam_surahs WHERE chapter_number IN (22, 29)'
).fetchall()
for r in rows:
    print(r)

# Fix the two inconsistent values
conn.execute(
    "UPDATE malayalam_surahs SET revelation_period = 'കാലഘട്ടം അവ്യക്തം' WHERE chapter_number IN (22, 29)"
)
conn.commit()

# Verify
print('\nAfter:')
rows = conn.execute(
    'SELECT chapter_number, revelation_period FROM malayalam_surahs WHERE chapter_number IN (13, 22, 29)'
).fetchall()
for r in rows:
    print(r)

conn.close()
print('\nDone.')
