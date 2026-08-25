"""One-off: copy the Malayalam surahs/verses/footnotes for surahs 41-60
from the MOQ Backend staging sqlite (which already has this data, entered
in earlier work, keyed correctly via its surah_number column) into the
app's bundled sqlite, which is missing them entirely.

Same schema-aware offset scheme as add_malayalam_surah69.py onward: the
bundled db has no surah_number column on malayalam_footnotes, so
footnote_number must be pool-wide unique across surahs 7-114. Each
surah's footnote_number range (1..N in staging) and its verses' [^N]
markers are shifted together by a running offset continuing the bundled
db's current global max (3092, after fixing the 61-68 collisions).

Numbering order doesn't need to match surah order -- only uniqueness
matters for the app's lookup -- so these are simply appended after
whatever the current max is.

Idempotent: deletes any existing surah 41-60 rows in the target first,
safe to re-run.

    python scripts/backfill_malayalam_41_60.py <staging-sqlite> <bundled-sqlite>
"""
import re
import sqlite3
import sys

SURAHS = range(41, 61)


def shift_markers(text, offset):
    if offset == 0 or text is None:
        return text
    return re.sub(r"\[\^(\d+)\]", lambda m: f"[^{int(m.group(1)) + offset}]", text)


def backfill(staging_path, bundled_path):
    staging = sqlite3.connect(staging_path)
    scur = staging.cursor()
    bundled = sqlite3.connect(bundled_path)
    bcur = bundled.cursor()

    running_max = bcur.execute("SELECT MAX(footnote_number) FROM malayalam_footnotes").fetchone()[0] or 0

    for surah in SURAHS:
        surah_row = scur.execute(
            "SELECT chapter_number, arabic_name, malayalam_name, english_translation, "
            "revelation_period, introduction FROM malayalam_surahs WHERE chapter_number = ?",
            (surah,),
        ).fetchone()
        if surah_row is None:
            raise SystemExit(f"Surah {surah}: not found in staging db {staging_path}")

        verse_rows = scur.execute(
            "SELECT verse_number, malayalam_translation FROM malayalam_verses "
            "WHERE surah_id = ? ORDER BY verse_number",
            (surah,),
        ).fetchall()
        footnote_rows = scur.execute(
            "SELECT footnote_number, content FROM malayalam_footnotes "
            "WHERE surah_number = ? ORDER BY footnote_number",
            (surah,),
        ).fetchall()

        offset = running_max
        bcur.execute("DELETE FROM malayalam_surahs WHERE chapter_number = ?", (surah,))
        bcur.execute(
            "INSERT INTO malayalam_surahs "
            "(chapter_number, arabic_name, malayalam_name, english_translation, "
            "revelation_period, introduction) VALUES (?, ?, ?, ?, ?, ?)",
            surah_row,
        )

        bcur.execute("DELETE FROM malayalam_verses WHERE surah_id = ?", (surah,))
        for verse_number, text in verse_rows:
            bcur.execute(
                "INSERT INTO malayalam_verses (surah_id, verse_number, malayalam_translation) "
                "VALUES (?, ?, ?)",
                (surah, verse_number, shift_markers(text, offset)),
            )

        for footnote_number, content in footnote_rows:
            bcur.execute(
                "INSERT INTO malayalam_footnotes (footnote_number, content) VALUES (?, ?)",
                (footnote_number + offset, content),
            )

        running_max += len(footnote_rows)
        print(
            f"Surah {surah}: copied {len(verse_rows)} verses, {len(footnote_rows)} footnotes "
            f"(footnote_number {offset + 1}-{running_max})"
        )

    bundled.commit()
    staging.close()
    bundled.close()
    print(f"Done. New global max footnote_number: {running_max}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("usage: python scripts/backfill_malayalam_41_60.py <staging-sqlite> <bundled-sqlite>")
    backfill(sys.argv[1], sys.argv[2])
