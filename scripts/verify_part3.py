import sqlite3, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

con = sqlite3.connect('assets/db/quran_asad_combined_nw.sqlite')
c = con.cursor()

expected = {
    19:98, 20:135, 21:112, 22:78, 23:118, 24:64, 25:77, 26:227,
    27:93, 28:88, 29:69, 30:60, 31:34, 32:30, 33:73, 34:54, 35:45, 36:83
}

print('=== Verse counts ===')
all_ok = True
for ch in range(19, 37):
    c.execute('SELECT COUNT(*) FROM malayalam_verses WHERE surah_id=?', (ch,))
    got = c.fetchone()[0]
    exp = expected.get(ch)
    ok = got == exp
    if not ok:
        all_ok = False
    status = 'OK' if ok else 'MISMATCH'
    print(f'Surah {ch:2d}: {got:3d}/{exp:3d} {status}')

print()
print('=== Sample verses (first and last of a few surahs) ===')
for ch, label in [(19, 'Maryam'), (26, 'Ash-Shuara'), (36, 'Ya-Sin')]:
    c.execute(
        'SELECT verse_number, malayalam_translation FROM malayalam_verses '
        'WHERE surah_id=? ORDER BY verse_number LIMIT 1', (ch,))
    row = c.fetchone()
    print(f'  S{ch} v{row[0]}: {row[1][:70]!r}')
    c.execute(
        'SELECT verse_number, malayalam_translation FROM malayalam_verses '
        'WHERE surah_id=? ORDER BY verse_number DESC LIMIT 1', (ch,))
    row = c.fetchone()
    print(f'  S{ch} v{row[0]}: {row[1][:70]!r}')

print()
print('=== Surah introductions (first 100 chars) ===')
c.execute(
    'SELECT chapter_number, arabic_name, introduction FROM malayalam_surahs '
    'WHERE chapter_number >= 19 AND chapter_number <= 22')
for row in c.fetchall():
    intro_preview = row[2][:100].replace('\n', ' | ') if row[2] else ''
    print(f'  ch={row[0]} {row[1]}: {intro_preview!r}')

print()
print('All counts match!' if all_ok else 'WARNING: Some mismatches (see above)')
con.close()
