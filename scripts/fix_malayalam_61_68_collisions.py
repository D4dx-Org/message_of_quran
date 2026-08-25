"""One-off: fix the footnote_number collisions in the bundled sqlite's
malayalam_footnotes table for surahs 61-68.

Root cause: unlike surahs 7-40 and 69-77, each of surahs 61-68 was
originally inserted with footnote_number reset to 1..N instead of
continuing the pool-wide counter (the app's lookup in
interpretations_db_helper.dart has no surah filter -- footnote_number
must be pool-wide unique across surahs 7-114, since the bundled db has
no surah_number column). This caused up to 9-way collisions with the
earlier, correctly-numbered surahs 7-40.

The 8 broken blocks were identified by their id ranges (contiguous,
freshly-inserted, footnote_number resetting to 1 at each boundary) and
confirmed against MOQ Backend's staging db (which has a surah_number
column and is unaffected) by matching row counts exactly, in order:

    surah  id range         count
    61     8970-8985        16
    62     8986-8999        14
    63     9000-9011        12
    64     9012-9026        15
    65     9027-9045        19
    66     9046-9071        26
    67     9072-9093        22
    68     9094-9122        29

This script renumbers each block to continue after the current global
max footnote_number, and shifts the matching [^N] markers in each
surah's malayalam_verses text by the same offset. Only touches the
bundled sqlite (assets/db/quran_asad_combined_nw.sqlite) -- the MOQ
Backend staging db already has correct per-surah numbering via its
surah_number column and needs no fix.

Idempotent guard: refuses to run if it doesn't find exactly the expected
row counts at the expected id ranges (i.e. if already fixed or the db
has changed since this script was written).

    python scripts/fix_malayalam_61_68_collisions.py <path-to-bundled-sqlite>
"""
import re
import sqlite3
import sys

BLOCKS = [
    (61, 8970, 8985, 16),
    (62, 8986, 8999, 14),
    (63, 9000, 9011, 12),
    (64, 9012, 9026, 15),
    (65, 9027, 9045, 19),
    (66, 9046, 9071, 26),
    (67, 9072, 9093, 22),
    (68, 9094, 9122, 29),
]


def shift_markers(text, offset):
    return re.sub(r"\[\^(\d+)\]", lambda m: f"[^{int(m.group(1)) + offset}]", text)


def fix(db_path):
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    running_max = cur.execute("SELECT MAX(footnote_number) FROM malayalam_footnotes").fetchone()[0]

    for surah, start_id, end_id, expected_count in BLOCKS:
        rows = cur.execute(
            "SELECT id, footnote_number FROM malayalam_footnotes WHERE id BETWEEN ? AND ? ORDER BY id",
            (start_id, end_id),
        ).fetchall()
        if len(rows) != expected_count or rows[0][1] != 1:
            conn.close()
            raise SystemExit(
                f"Surah {surah}: expected {expected_count} rows starting at footnote_number 1 "
                f"in id range {start_id}-{end_id}, found {len(rows)} rows "
                f"(first footnote_number: {rows[0][1] if rows else 'n/a'}). "
                f"Refusing to run -- db state doesn't match what this script expects."
            )

        offset = running_max
        cur.execute(
            "UPDATE malayalam_footnotes SET footnote_number = footnote_number + ? "
            "WHERE id BETWEEN ? AND ?",
            (offset, start_id, end_id),
        )

        verse_rows = cur.execute(
            "SELECT id, malayalam_translation FROM malayalam_verses WHERE surah_id = ?",
            (surah,),
        ).fetchall()
        for verse_id, text in verse_rows:
            new_text = shift_markers(text, offset)
            if new_text != text:
                cur.execute(
                    "UPDATE malayalam_verses SET malayalam_translation = ? WHERE id = ?",
                    (new_text, verse_id),
                )

        running_max += expected_count
        print(f"Surah {surah}: renumbered footnote_number by +{offset} (now {offset + 1}-{running_max})")

    conn.commit()
    conn.close()
    print(f"Done. New global max footnote_number: {running_max}")


if __name__ == "__main__":
    for path in sys.argv[1:]:
        fix(path)
