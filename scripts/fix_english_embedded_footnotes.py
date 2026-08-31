"""
fix_english_embedded_footnotes.py

Extracts English footnotes that were absorbed into the *preceding*
footnote's text during the original import, leaving a hole in the
`footnotes` table while the verses still carried the marker. Tapping
such a marker in the app shows nothing.

Same defect class the repo already fixed once in fix_footnotes_v3.py --
a footnote number left inline as plain text, e.g. footnote 2:21 ending
'...preceding passages. 22 Lit., "establish on earth a successor"...',
where "22 " begins footnote 22.

Repairs 27 footnotes across 8 surahs:
    2 (22), 6 (82-83), 11 (96-102), 12 (103), 15 (39-42),
    16 (113-118), 20 (25-28), 62 (3-4)

NOT repaired -- 14 footnotes are genuinely absent, with no embedded
text anywhere (their neighbours are clean, self-contained footnotes),
so they need the printed source:
    6 (139), 7 (151), 10 (1, 76), 15 (59, 71-73),
    20 (79), 39 (37, 68), 43 (51-53)

No footnote text is invented: every restored footnote is lifted
verbatim out of the row that swallowed it.

Idempotent: a footnote that already exists is left alone. Aborts
without writing if an expected marker cannot be located.

    python scripts/fix_english_embedded_footnotes.py <path-to-sqlite> [...]
"""
import re
import sqlite3
import sys

# surah -> runs of consecutive missing footnote numbers
EXPECTED = {
    2: [[22]],
    6: [[82, 83]],
    11: [[96, 97, 98, 99, 100, 101, 102]],
    12: [[103]],
    15: [[39, 40, 41, 42]],
    16: [[113, 114, 115, 116, 117, 118]],
    20: [[25, 26, 27, 28]],
    62: [[3, 4]],
}


# Verses whose text begins with their own verse number in parentheses --
# a scanning artifact, not a footnote marker: a marker never precedes the
# text it annotates, and in each case the number is far beyond the number
# of footnotes the surah actually has (e.g. surah 100 has 3 footnotes but
# verse 6 began "(6) VERILY, ..."). The reader renders these as dead
# footnote badges. Same class as the "(0)" damage the backend repairs.
STRAY_VERSE_PREFIXES = [(37, 98), (90, 18), (96, 13), (100, 6)]


def marker_re(n):
    # A footnote number standing on its own after sentence-ending
    # punctuation or a newline, followed by the footnote's opening word.
    return re.compile(
        rf"(?:(?<=[.!?\"';:\)\]])|(?<=\n))\s*\b{n}\s+(?=[A-Z\"'(I])"
    )


def apply(db_path):
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    created, skipped = [], []

    for surah, runs in EXPECTED.items():
        for run in runs:
            present = [
                n
                for n in run
                if cur.execute(
                    "SELECT 1 FROM footnotes WHERE surah_number = ? AND footnote_number = ?",
                    (surah, n),
                ).fetchone()
            ]
            if len(present) == len(run):
                skipped.append(f"{surah}:{run} already present")
                continue
            if present:
                raise SystemExit(
                    f"ABORTED: surah {surah} run {run} is half-repaired "
                    f"(present: {present}); refusing to guess."
                )

            holder = cur.execute(
                "SELECT footnote_number, text FROM footnotes "
                "WHERE surah_number = ? AND footnote_number < ? "
                "ORDER BY footnote_number DESC LIMIT 1",
                (surah, run[0]),
            ).fetchone()
            if holder is None or not holder[1]:
                raise SystemExit(f"ABORTED: no holder footnote before {surah}:{run[0]}")

            text = holder[1]
            spans = []
            for n in run:
                m = marker_re(n).search(text)
                if m is None:
                    raise SystemExit(
                        f"ABORTED: marker for footnote {n} not found inside "
                        f"{surah}:{holder[0]}"
                    )
                spans.append((n, m.start(), m.end()))

            if any(spans[i][1] >= spans[i + 1][1] for i in range(len(spans) - 1)):
                raise SystemExit(
                    f"ABORTED: markers out of order inside {surah}:{holder[0]}"
                )

            for i, (n, start, end) in enumerate(spans):
                stop = spans[i + 1][1] if i + 1 < len(spans) else len(text)
                body = text[end:stop].strip()
                if not body:
                    raise SystemExit(f"ABORTED: empty body for {surah}:{n}")
                cur.execute(
                    "INSERT INTO footnotes (surah_number, footnote_number, text) "
                    "VALUES (?, ?, ?)",
                    (surah, n, body),
                )
                created.append(f"{surah}:{n} ({len(body)} chars)")

            trimmed = text[: spans[0][1]].strip()
            if not trimmed:
                raise SystemExit(f"ABORTED: trimming {surah}:{holder[0]} left it empty")
            cur.execute(
                "UPDATE footnotes SET text = ? WHERE surah_number = ? AND footnote_number = ?",
                (trimmed, surah, holder[0]),
            )

    # --- strip stray leading verse numbers -------------------------------
    for surah, verse in STRAY_VERSE_PREFIXES:
        row = cur.execute(
            "SELECT text FROM verses WHERE surah_number = ? AND verse_number = ?",
            (surah, verse),
        ).fetchone()
        if row is None or not row[0]:
            raise SystemExit(f"ABORTED: verse {surah}:{verse} missing")
        stripped = re.sub(rf"^\(\s*{verse}\s*\)\s*", "", row[0].strip())
        if stripped == row[0].strip():
            skipped.append(f"{surah}:{verse} prefix already removed")
            continue
        if not stripped:
            raise SystemExit(f"ABORTED: stripping {surah}:{verse} left it empty")
        cur.execute(
            "UPDATE verses SET text = ? WHERE surah_number = ? AND verse_number = ?",
            (stripped, surah, verse),
        )
        created.append(f"stray '({verse})' prefix removed from verse {surah}:{verse}")

    conn.commit()
    conn.close()
    print(f"{db_path}: restored {len(created)} footnote(s)")
    for c in created:
        print("   +", c)
    for s in skipped:
        print("   =", s)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    for path in sys.argv[1:]:
        apply(path)
