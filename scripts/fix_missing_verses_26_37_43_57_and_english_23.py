"""
fix_missing_verses_26_37_43_57_and_english_23.py

Repairs five blank/missing verse rows that came in defective from the
original bulk import. NO translation text is invented here -- every
repair either splits text that is already present in the database
(where two verses were merged into one row) or restores text recovered
from the original source document.

Repairs:

  1. Malayalam 26:62  -- row was empty. In the source document
     (assets/db/Part III_word.docx, recoverable from git commit
     8ebcfa8^), the "26:62" verse marker sits alone on its own
     paragraph with the translation on the FOLLOWING paragraph, so the
     importer captured nothing. Text restored verbatim from that
     source paragraph.

  2. Malayalam 37:42  -- merged into 37:41. The tail of 37:41
     ("അങ്ങനെ അവർ ആദരിക്കപ്പെടും") is the English 37:42 content
     ("and honoured shall they be"). Split.

  3. Malayalam 43:32  -- merged into 43:31. Everything after the
     [^3228] marker is the English 43:32 content ("But is it they who
     distribute thy Sustainer's grace? ..."). Split.

  4. Malayalam 57:28  -- merged into 57:27, with a literal "57 28"
     verse marker left embedded mid-text. Split on that marker.

  5. English 23:95    -- merged into the row numbered 96, leaving no
     row 95 at all. The first sentence of that row is the 23:95 text.
     Split, and insert the missing row 95.

Idempotent: each repair checks whether it is still needed and verifies
its anchor before writing. If an anchor is not found the script aborts
without modifying anything, so it can never silently corrupt data.

    python scripts/fix_missing_verses_26_37_43_57_and_english_23.py <path-to-sqlite> [...]
"""
import sqlite3
import sys

# Recovered verbatim from Part III_word.docx (paragraph following the
# bare "26:62" marker line). English counterpart: "He replied: 'Nay
# indeed! My Sustainer is with me, [and] He will guide me!'"
ML_26_62 = (
    "അദ്ദേഹം മറുപടി പറഞ്ഞു: ‘തീര്‍ച്ചയായും അങ്ങനെയല്ല! "
    "എന്റെ നാഥന്‍ എന്നോടൊപ്പമുണ്ട്, [അപ്പോള്‍] അവന്‍ എന്നെ നയിക്കും!’"
)

# Anchors: the split point is the START of the following verse's text.
ML_SPLITS = [
    # (surah, verse_holding_both, verse_to_restore, anchor beginning the 2nd verse)
    (37, 41, 42, "അങ്ങനെ അവർ"),
    (43, 31, 32, "അവരാണോ രക്ഷിതാവിന്റെ"),
    (57, 27, 28, "ഹേ സത്യവിശ്വാസികളേ!"),
]

EN_23_95 = (
    "[Pray thus -] for, behold, We are most certainly able to let thee "
    "witness [the fulfilment, even in this world, of] whatever We promise them!"
)
EN_23_96 = (
    "[But whatever they may say or do,] repel the evil [which they commit] "
    "with something that is better:(57) We are fully aware of what they "
    "attribute [to Us]."
)


def fail(msg):
    raise SystemExit(f"ABORTED (nothing written): {msg}")


def apply(db_path):
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    done = []

    # --- 1. restore Malayalam 26:62 -------------------------------------
    row = cur.execute(
        "SELECT malayalam_translation FROM malayalam_verses "
        "WHERE surah_id = 26 AND verse_number = 62"
    ).fetchone()
    if row is None:
        fail("26:62 row does not exist at all; expected an empty row")
    if row[0]:
        done.append("26:62 already populated, skipped")
    else:
        cur.execute(
            "UPDATE malayalam_verses SET malayalam_translation = ? "
            "WHERE surah_id = 26 AND verse_number = 62",
            (ML_26_62,),
        )
        done.append("26:62 restored from source document")

    # --- 2-4. split merged Malayalam verses ------------------------------
    for surah, held, restore, anchor in ML_SPLITS:
        tgt = cur.execute(
            "SELECT malayalam_translation FROM malayalam_verses "
            "WHERE surah_id = ? AND verse_number = ?",
            (surah, restore),
        ).fetchone()
        if tgt is None:
            fail(f"{surah}:{restore} row missing entirely")
        if tgt[0]:
            done.append(f"{surah}:{restore} already populated, skipped")
            continue

        src = cur.execute(
            "SELECT malayalam_translation FROM malayalam_verses "
            "WHERE surah_id = ? AND verse_number = ?",
            (surah, held),
        ).fetchone()
        if src is None or not src[0]:
            fail(f"{surah}:{held} has no text to split")
        text = src[0]
        idx = text.find(anchor)
        if idx == -1:
            fail(f"anchor {anchor!r} not found in {surah}:{held}")

        first, second = text[:idx].strip(), text[idx:].strip()
        # 57:27 carries a literal "57 28" verse marker before the split point
        for junk in ("57 28",):
            if first.endswith(junk):
                first = first[: -len(junk)].strip()
        if not first or not second:
            fail(f"split of {surah}:{held} produced an empty half")

        cur.execute(
            "UPDATE malayalam_verses SET malayalam_translation = ? "
            "WHERE surah_id = ? AND verse_number = ?",
            (first, surah, held),
        )
        cur.execute(
            "UPDATE malayalam_verses SET malayalam_translation = ? "
            "WHERE surah_id = ? AND verse_number = ?",
            (second, surah, restore),
        )
        done.append(f"{surah}:{held} split -> {surah}:{restore} restored")

    # --- 5. split merged English 23:95 / 23:96 ---------------------------
    has95 = cur.execute(
        "SELECT COUNT(*) FROM verses WHERE surah_number = 23 AND verse_number = 95"
    ).fetchone()[0]
    if has95:
        done.append("EN 23:95 already present, skipped")
    else:
        merged = cur.execute(
            "SELECT text FROM verses WHERE surah_number = 23 AND verse_number = 96"
        ).fetchone()
        if merged is None:
            fail("EN 23:96 row missing")
        if not merged[0].startswith(EN_23_95[:40]):
            fail("EN 23:96 does not begin with the expected 23:95 text")
        cur.execute(
            "INSERT INTO verses (surah_number, verse_number, text) VALUES (23, 95, ?)",
            (EN_23_95,),
        )
        cur.execute(
            "UPDATE verses SET text = ? WHERE surah_number = 23 AND verse_number = 96",
            (EN_23_96,),
        )
        done.append("EN 23:95 inserted, 23:96 trimmed")

    conn.commit()
    conn.close()
    print(f"{db_path}:")
    for d in done:
        print("   -", d)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    for path in sys.argv[1:]:
        apply(path)
