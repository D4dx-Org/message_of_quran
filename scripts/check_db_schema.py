import sqlite3, os, sys

db_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'db', 'quran_asad_combined_nw.sqlite')
con = sqlite3.connect(db_path)
c = con.cursor()

c.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [r[0] for r in c.fetchall()]
print('Tables:', tables)

for t in tables:
    c.execute(f'PRAGMA table_info({t})')
    cols = c.fetchall()
    print(f'\n{t}:')
    for col in cols:
        print(f'  {col}')

# Sample data from each malayalam table
for t in ['malayalam_surahs', 'malayalam_verses', 'malayalam_footnotes']:
    if t in tables:
        c.execute(f'SELECT * FROM {t} ORDER BY id DESC LIMIT 3')
        rows = c.fetchall()
        print(f'\nLast 3 rows of {t}:')
        for r in rows:
            print(f'  {r}')
        c.execute(f'SELECT COUNT(*) FROM {t}')
        cnt = c.fetchone()[0]
        print(f'  Total rows: {cnt}')

# Check max footnote_number
c.execute("SELECT MAX(footnote_number) FROM malayalam_footnotes")
mx = c.fetchone()[0]
print(f'\nMax footnote_number in malayalam_footnotes: {mx}')

# Check max chapter_number in malayalam_surahs
c.execute("SELECT MAX(chapter_number) FROM malayalam_surahs")
mx2 = c.fetchone()[0]
print(f'Max chapter_number in malayalam_surahs: {mx2}')

# Show existing surah info for last 3 surahs
c.execute("SELECT id, chapter_number, arabic_name, malayalam_name, revelation_period FROM malayalam_surahs ORDER BY chapter_number DESC LIMIT 3")
rows = c.fetchall()
print('\nLast 3 surahs:')
for r in rows:
    print(f'  {r}')

con.close()
