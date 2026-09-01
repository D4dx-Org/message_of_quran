"""
apply_sep01_content_corrections.py

Applies the corrections supplied on 2026-09-01:

  malayalam_about_translator.bio   three wording fixes in the children list
  contact_us_content.description   adds Mishari Rashid Al-Afasy to the reciters
  authors.html_content             byline becomes "by K.C. Saleem"

Each edit is anchored on a phrase that must appear exactly once; anything
missing aborts the whole run before a single write, so a half-applied
database is not possible. The Malayalam replacements deliberately stop short
of the names themselves -- those carry zero-width joiners that are easy to
lose when retyping.

Idempotent: an edit whose replacement text is already in place is skipped.

    python scripts/apply_sep01_content_corrections.py <sqlite> [<sqlite> ...]
"""
import sqlite3
import sys

# (table, column, old, new)
EDITS = [
    (
        "malayalam_about_translator",
        "bio",
        "\u0d1c\u0d47\u0d23\u0d32\u0d3f\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d3e\u0d2f ",
        "\u0d1c\u0d47\u0d23\u0d32\u0d3f\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d41\u0d02 "
        "\u0d0e\u0d34\u0d41\u0d24\u0d4d\u0d24\u0d41\u0d15\u0d3e\u0d30\u0d3f\u0d2f\u0d41\u0d2e\u0d3e\u0d2f ",
    ),
    (
        "malayalam_about_translator",
        "bio",
        "\u0d15\u0d3e\u0d28\u0d21\u0d2f\u0d3f\u0d32\u0d46 \u0d12\u0d1f\u0d4d\u0d1f\u0d3e\u0d35\u0d2f\u0d3f\u0d32\u0d46 "
        "\u0d21\u0d3e\u0d31\u0d4d\u0d31\u0d3e \u0d0e\u0d1e\u0d4d\u0d1a\u0d3f\u0d28\u0d40\u0d2f\u0d7c ",
        "\u0d15\u0d3e\u0d28\u0d21\u0d2f\u0d3f\u0d32\u0d46 \u0d13\u0d1f\u0d4d\u0d1f\u0d35\u0d2f\u0d3f\u0d7d "
        "\u0d38\u0d40\u0d28\u0d3f\u0d2f\u0d7c \u0d21\u0d3e\u0d31\u0d4d\u0d31\u0d3e "
        "\u0d0e\u0d1e\u0d4d\u0d1a\u0d3f\u0d28\u0d40\u0d2f\u0d31\u0d3e\u0d2f ",
    ),
    (
        "malayalam_about_translator",
        "bio",
        "\u0d1f\u0d4a\u0d31\u0d7b\u0d4d\u0d31\u0d4b\u0d2f\u0d3f\u0d32\u0d46 "
        "\u0d13\u0d21\u0d3f\u0d2f\u0d4b\u0d33\u0d1c\u0d3f\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d4d ",
        "\u0d1f\u0d4a\u0d31\u0d7b\u0d4d\u0d31\u0d4b\u0d2f\u0d3f\u0d7d "
        "\u0d13\u0d21\u0d3f\u0d2f\u0d4b\u0d33\u0d1c\u0d3f\u0d38\u0d4d\u0d31\u0d4d\u0d31\u0d3e\u0d2f ",
    ),
    (
        "contact_us_content",
        "description",
        "Sheikh Abdul Rahman Al-Sudais and Abdul Rahman Al-Ossi",
        "Sheikh Abdul Rahman Al-Sudais, Mishari Rashid Al-Afasy and "
        "Abdul Rahman Al-Ossi",
    ),
    ("authors", "html_content", "<p>K.C. Saleem</p>", "<p>by K.C. Saleem</p>"),
]


def plan(conn):
    """Work out every edit up front so nothing is written unless all of them fit.

    Several edits land in the same row, so each one is applied to the running
    value rather than to the original -- otherwise the last write for a row
    would silently discard the earlier ones.
    """
    current = {}
    skipped = 0
    for table, column, old, new in EDITS:
        cur = conn.cursor()
        rows = cur.execute(f"SELECT rowid, {column} FROM {table}").fetchall()
        hit = False
        for rid, stored in rows:
            key = (table, column, rid)
            value = current.get(key, stored)
            if not value:
                continue
            if new in value:
                hit = True
                skipped += 1
                continue
            if old not in value:
                continue
            if value.count(old) != 1:
                raise SystemExit(
                    f"ABORTED: {table}.{column} rowid {rid} matches {old!r} "
                    f"{value.count(old)} times, expected 1"
                )
            current[key] = value.replace(old, new, 1)
            hit = True
        if not hit:
            raise SystemExit(f"ABORTED: {table}.{column} has no match for {old!r}")
    writes = [(t, c, rid, v) for (t, c, rid), v in current.items()]
    return writes, skipped


def apply(db_path):
    conn = sqlite3.connect(db_path)
    writes, skipped = plan(conn)
    for table, column, rid, value in writes:
        conn.execute(f"UPDATE {table} SET {column} = ? WHERE rowid = ?", (value, rid))
    conn.commit()
    conn.close()
    print(f"{db_path}: {len(writes)} row(s) written, {skipped} edit(s) already in place")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    for db in sys.argv[1:]:
        apply(db)
