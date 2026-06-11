"""
populate_malayalam_part3.py

Parses assets/db/Part III_word.docx and inserts Malayalam Quran data
for surahs 19-36 into assets/db/quran_asad_combined_nw.sqlite.

Populates tables:
  - malayalam_surahs    (surah metadata + introduction)
  - malayalam_verses    (verse translations with [^N] footnote markers)
  - malayalam_footnotes (footnote content, globally unique footnote_number)

Run from repo root:
    python scripts/populate_malayalam_part3.py
"""

import os
import sys
import io
import re
import shutil
import sqlite3
import zipfile

# Ensure UTF-8 output on Windows (Malayalam characters)
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

from docx import Document
from docx.oxml.ns import qn
from lxml import etree

# Global footnote numbers for surahs 1-18 end at 1430.
# Part III footnotes start from 1431 (or fetched dynamically from DB).
PART3_FN_START = 1431

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
DB_PATH = os.path.join(REPO_ROOT, "assets", "db", "quran_asad_combined_nw.sqlite")
DOCX_PATH = os.path.join(REPO_ROOT, "assets", "db", "Part III_word.docx")
BACKUP_PATH = DB_PATH + ".bak_part3"

# Sidecar files that must be removed to avoid corruption
WAL_PATH = DB_PATH + "-wal"
SHM_PATH = DB_PATH + "-shm"

# ---------------------------------------------------------------------------
# Surah metadata for surahs 19-36
# (arabic_name, english_translation)
# ---------------------------------------------------------------------------
SURAH_META = {
    19: ("Maryam",       "Mary"),
    20: ("Ta-Ha",        "O Man"),
    21: ("Al-Anbiya",    "The Prophets"),
    22: ("Al-Hajj",      "The Pilgrimage"),
    23: ("Al-Mu'minun",  "The Believers"),
    24: ("An-Nur",       "The Light"),
    25: ("Al-Furqan",    "The Criterion"),
    26: ("Ash-Shu'ara",  "The Poets"),
    27: ("An-Naml",      "The Ants"),
    28: ("Al-Qasas",     "The Story"),
    29: ("Al-Ankabut",   "The Spider"),
    30: ("Ar-Rum",       "The Romans"),
    31: ("Luqman",       "Luqman"),
    32: ("As-Sajda",     "The Prostration"),
    33: ("Al-Ahzab",     "The Confederates"),
    34: ("Saba",         "Sheba"),
    35: ("Al-Fatir",     "The Creator"),
    36: ("Ya-Sin",       "Ya Sin"),
}

# Verse-number prefix pattern.
# Handles all observed variants in the document:
#   Normal:    "19.1 "   "19:1 "   "(19.6) "  "(19:11) "
#   Space:     "26: 20 "
#   Semicolon: "26;72 "  "28;5 "
#   Hyphen:    "26-59 "
#   Bracket:   "[27:38 "
VERSE_PREFIX_RE = re.compile(r"^\[?\(?(\d+)[-.:;]\s*(\d+)\)?\]?\s*")

# Hardcoded verse-number corrections for specific document typos.
# Key: (current_chapter, raw_surah, raw_verse) → correct_verse_number
# Only needed when the sequential-fallback heuristic cannot infer the right number.
VERSE_TYPO_FIXES: dict = {
    # "27:8" appears in chapter 28's section between v6 and v8 — should be v7.
    # raw_verse=8 is within +4 of last_verse=6, so it would be accepted as 8 without this fix.
    (28, 27, 8): 7,
}


# ---------------------------------------------------------------------------
# Footnote helpers
# ---------------------------------------------------------------------------

def get_docx_footnotes(docx_path: str) -> dict:
    """Read all built-in Word footnotes directly from word/footnotes.xml in the docx ZIP.

    Returns {local_id (int): text (str)}.
    Skips Word's separator entries (IDs -1 and 0).
    Uses lxml directly to avoid python-docx API limitations.
    """
    W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"

    def wqn(tag):
        return "{" + W + "}" + tag

    try:
        with zipfile.ZipFile(docx_path) as z:
            if "word/footnotes.xml" not in z.namelist():
                return {}
            fn_xml = z.read("word/footnotes.xml")
    except Exception:
        return {}

    try:
        root = etree.fromstring(fn_xml)
    except Exception:
        return {}

    result = {}
    for fn in root.findall(wqn("footnote")):
        fn_id_str = fn.get(wqn("id"))
        if fn_id_str is None:
            continue
        fn_id = int(fn_id_str)
        if fn_id < 1:  # skip Word's separator entries (-1, 0)
            continue
        texts = [t.text for t in fn.iter(wqn("t")) if t.text]
        text = "".join(texts).strip()
        # Strip leading footnote-number prefix that Word includes in the text
        # (e.g. "6. " or "6 " at the start of footnote content)
        text = re.sub(r"^\d+\.?\s*", "", text).strip()
        if text:
            result[fn_id] = text
    return result


def build_verse_text_with_fn_refs(para, local_to_global: dict) -> str:
    """Reconstruct paragraph text with [^N] markers where footnote references appear.

    Word stores footnote references as <w:footnoteReference w:id="N"/> elements
    inside a run.  para.text silently drops these — so we iterate runs manually.
    """
    parts = []
    for run in para.runs:
        if run.text:
            parts.append(run.text)
        for fn_ref in run._r.findall(qn("w:footnoteReference")):
            local_id_str = fn_ref.get(qn("w:id"))
            if local_id_str is None:
                continue
            local_id = int(local_id_str)
            global_id = local_to_global.get(local_id)
            if global_id is not None:
                parts.append(f"[^{global_id}]")
    return "".join(parts).strip()


# ---------------------------------------------------------------------------
# General helpers
# ---------------------------------------------------------------------------

def get_font_size(para):
    """Return font size (pt) of the paragraph's first run that declares one,
    whether or not that run contains text (e.g. footnote-reference-only runs
    still carry font formatting).  Falls back to the paragraph style font
    size, then returns None."""
    for run in para.runs:
        if run.font.size:
            return round(run.font.size.pt, 1)
    if para.style and para.style.font.size:
        return round(para.style.font.size.pt, 1)
    return None


def is_normal(para):
    return para.style and para.style.name == "Normal"


# ---------------------------------------------------------------------------
# Parse docx
# ---------------------------------------------------------------------------

def parse_docx(path, fn_start: int):
    """Parse the Word document and return (surahs, footnotes).

    surahs: list of dicts with keys:
        chapter_number, arabic_name, malayalam_name, english_translation,
        revelation_period, introduction, verses (list of (verse_num, text))

    footnotes: list of (global_id, content) tuples.
    """
    doc = Document(path)
    paras = doc.paragraphs

    # --- Build footnote id mapping ----------------------------------------
    doc_footnotes = get_docx_footnotes(path)  # {local_id: text}
    sorted_local_ids = sorted(doc_footnotes.keys())
    local_to_global = {
        local_id: fn_start + idx
        for idx, local_id in enumerate(sorted_local_ids)
    }
    footnotes_to_insert = [
        (local_to_global[lid], doc_footnotes[lid])
        for lid in sorted_local_ids
    ]
    if doc_footnotes:
        print(f"  Found {len(doc_footnotes)} footnotes in Word document "
              f"(global IDs {fn_start}\u2013{fn_start + len(doc_footnotes) - 1})")
    else:
        print("  No built-in Word footnotes found in document.")

    # --- Parse paragraphs -------------------------------------------------
    surahs = []
    current = None
    surah_number = 18  # will be incremented to 19 on first heading
    collecting_intro = False

    # Per-surah verse tracking (reset on each new surah heading)
    last_verse_num = 0
    seen_verse_nums: set = set()

    for para in paras:
        # Use plain text for non-verse paragraphs (headings, period, intro)
        plain_text = para.text.strip()
        if not plain_text:
            continue

        sz = get_font_size(para)
        normal = is_normal(para)

        # ---- Surah heading: Normal, ~18 pt ---------------------------------
        if normal and sz is not None and abs(sz - 18.0) < 0.6:
            surah_number += 1
            if surah_number > 36:
                break  # done with Part III

            arabic_name, english_trans = SURAH_META.get(
                surah_number, ("Unknown", "Unknown")
            )
            current = {
                "chapter_number": surah_number,
                "arabic_name": arabic_name,
                "malayalam_name": plain_text,
                "english_translation": english_trans,
                "revelation_period": "",
                "intro_parts": [],  # collect 9pt paragraphs
                "verses": [],
            }
            surahs.append(current)
            collecting_intro = False
            last_verse_num = 0
            seen_verse_nums = set()
            continue

        if current is None:
            continue

        # ---- Revelation period: Normal, ~8 pt ------------------------------
        if normal and sz is not None and abs(sz - 8.0) < 0.6:
            if not current["revelation_period"]:
                current["revelation_period"] = plain_text
                collecting_intro = True
            continue

        # ---- Introduction text: Normal, ~9 pt ------------------------------
        if normal and sz is not None and abs(sz - 9.0) < 0.6 and collecting_intro:
            current["intro_parts"].append(plain_text)
            continue

        # ---- Arabic verse / Bismillah: Normal, ~16 pt ----------------------
        if normal and sz is not None and abs(sz - 16.0) < 0.6:
            collecting_intro = False  # intro ends when Arabic text begins
            continue

        # ---- Malayalam verse translation: Normal, ~9.5 pt (or 12 pt) ------
        if normal and sz is not None and (
            abs(sz - 9.5) < 0.6 or abs(sz - 12.0) < 0.6
        ):
            # Use marker-aware builder so [^N] refs are embedded in verse text
            full_text = build_verse_text_with_fn_refs(para, local_to_global)
            if not full_text:
                continue

            # Some verse paragraphs have a footnote reference run (no text) as
            # their very first element — before the "NN:NN" verse-number prefix.
            # E.g. "[^1431] (36:9) text…"
            # Peel off any leading [^N] markers so the verse-prefix regex can
            # match, then re-attach them to the front of the verse body text.
            LEADING_FN_RE = re.compile(r"^((?:\[\^\d+\]\s*)+)(.*)", re.DOTALL)
            lm = LEADING_FN_RE.match(full_text)
            if lm:
                leading_fn_str = lm.group(1).rstrip()
                prefix_search_text = lm.group(2)
            else:
                leading_fn_str = ""
                prefix_search_text = full_text

            m = VERSE_PREFIX_RE.match(prefix_search_text)
            if not m:
                # No verse-number prefix → Bismillah translation or similar; skip
                continue

            raw_surah = int(m.group(1))
            raw_verse = int(m.group(2))
            # Re-attach leading [^N] markers to the start of the verse body
            body = prefix_search_text[m.end():]
            if leading_fn_str:
                verse_text = leading_fn_str + (" " if body and not body.startswith(" ") else "") + body
            else:
                verse_text = body

            # Check for combined-verse range suffix (e.g., "34:30-31 text").
            # If present, we will store the text under EVERY verse in the range.
            combined_end: int | None = None
            range_m = re.match(r"^-(\d+)\s*", verse_text)
            if range_m:
                combined_end = int(range_m.group(1))
                verse_text = verse_text[range_m.end():]

            # Accept only paragraphs whose surah tag is within ±15 of the current
            # chapter (catches common surah-number typos in the document).
            if abs(raw_surah - current["chapter_number"]) > 15:
                continue

            # Apply hardcoded verse-number corrections
            fix_key = (current["chapter_number"], raw_surah, raw_verse)
            if fix_key in VERSE_TYPO_FIXES:
                raw_verse = VERSE_TYPO_FIXES[fix_key]

            # Decide actual verse number:
            # • If raw_verse is the natural next verse (1–4 ahead of last),
            #   trust it as-is.
            # • Otherwise (large jump forward, backwards, or duplicate) fall
            #   back to sequential: last_verse_num + 1.
            if (
                raw_verse > last_verse_num
                and raw_verse <= last_verse_num + 4
                and raw_verse not in seen_verse_nums
            ):
                actual_verse = raw_verse
            else:
                # Sequential fallback — skip any already-seen numbers
                actual_verse = last_verse_num + 1
                while actual_verse in seen_verse_nums:
                    actual_verse += 1

            current["verses"].append((actual_verse, verse_text))
            seen_verse_nums.add(actual_verse)
            last_verse_num = actual_verse

            # Also store under every additional verse in a combined range (e.g. 30-31)
            if combined_end and combined_end > actual_verse:
                for extra_verse in range(actual_verse + 1, combined_end + 1):
                    if extra_verse not in seen_verse_nums:
                        current["verses"].append((extra_verse, verse_text))
                        seen_verse_nums.add(extra_verse)
                        last_verse_num = extra_verse
            continue

    # Build final introduction string for each surah
    for surah in surahs:
        parts = surah.pop("intro_parts")
        rev = surah["revelation_period"]
        if parts:
            surah["introduction"] = rev + "\n\n" + "\n".join(parts)
        else:
            surah["introduction"] = rev

    return surahs, footnotes_to_insert


# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------

def get_current_fn_max(db_path: str) -> int:
    """Return the current maximum footnote_number in malayalam_footnotes."""
    con = sqlite3.connect(db_path)
    c = con.cursor()
    c.execute("SELECT MAX(footnote_number) FROM malayalam_footnotes")
    row = c.fetchone()
    con.close()
    return row[0] if row and row[0] is not None else 0


# ---------------------------------------------------------------------------
# Database insertion
# ---------------------------------------------------------------------------

def insert_into_db(db_path, surahs, footnotes):
    con = sqlite3.connect(db_path)
    c = con.cursor()

    # Use DELETE journal mode (required by app)
    c.execute("PRAGMA journal_mode=DELETE")

    # Remove existing data for surahs 19-36 (idempotency)
    print("Removing any existing rows for chapter_number 19-36 ...")

    # Find surah IDs for chapters 19-36
    c.execute(
        "SELECT id FROM malayalam_surahs WHERE chapter_number >= 19 AND chapter_number <= 36"
    )
    existing_surah_ids = [row[0] for row in c.fetchall()]
    if existing_surah_ids:
        placeholders = ",".join("?" for _ in existing_surah_ids)
        c.execute(
            f"DELETE FROM malayalam_verses WHERE surah_id IN ({placeholders})",
            existing_surah_ids,
        )
    c.execute(
        "DELETE FROM malayalam_surahs WHERE chapter_number >= 19 AND chapter_number <= 36"
    )

    # Remove any existing Part III footnotes (idempotency)
    if footnotes:
        first_fn_num = footnotes[0][0]
        c.execute(
            "DELETE FROM malayalam_footnotes WHERE footnote_number >= ?",
            (first_fn_num,),
        )
        print(f"Removing existing footnotes with footnote_number >= {first_fn_num} ...")

    con.commit()

    # Insert surahs and verses
    total_verses = 0
    for surah in surahs:
        cn = surah["chapter_number"]
        fn_verse_count = sum(1 for _, vt in surah["verses"] if "[^" in vt)
        print(
            f"  Inserting Surah {cn} ({surah['arabic_name']}): "
            f"{len(surah['verses'])} verses, {fn_verse_count} with footnote refs ..."
        )

        c.execute(
            """
            INSERT INTO malayalam_surahs
                (id, chapter_number, arabic_name, malayalam_name,
                 english_translation, revelation_period, introduction)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (
                cn,
                cn,
                surah["arabic_name"],
                surah["malayalam_name"],
                surah["english_translation"],
                surah["revelation_period"],
                surah["introduction"],
            ),
        )

        for verse_num, verse_text in surah["verses"]:
            c.execute(
                """
                INSERT INTO malayalam_verses
                    (surah_id, verse_number, malayalam_translation)
                VALUES (?, ?, ?)
                """,
                (cn, verse_num, verse_text),
            )
        total_verses += len(surah["verses"])

    # Insert footnotes
    print(f"\nInserting {len(footnotes)} footnotes ...")
    for global_id, content in footnotes:
        c.execute(
            "INSERT INTO malayalam_footnotes (footnote_number, content) "
            "VALUES (?, ?)",
            (global_id, content),
        )

    con.commit()
    con.close()
    return total_verses


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    print(f"DB   : {DB_PATH}")
    print(f"Docx : {DOCX_PATH}")

    if not os.path.exists(DOCX_PATH):
        sys.exit(f"ERROR: Word document not found: {DOCX_PATH}")
    if not os.path.exists(DB_PATH):
        sys.exit(f"ERROR: Database not found: {DB_PATH}")

    # fn_start is always PART3_FN_START (1431).
    # The delete inside insert_into_db removes any previously inserted Part III
    # footnotes before re-inserting, so this is always idempotent.
    fn_start = PART3_FN_START
    print(f"Footnote IDs will start at: {fn_start}")

    # --- Backup ---
    print(f"\nBacking up DB to: {BACKUP_PATH}")
    shutil.copy2(DB_PATH, BACKUP_PATH)

    # --- Remove WAL/SHM sidecar files ---
    for sidecar in (WAL_PATH, SHM_PATH):
        if os.path.exists(sidecar):
            os.remove(sidecar)
            print(f"Removed sidecar: {sidecar}")

    # --- Parse ---
    print("\nParsing Word document ...")
    surahs, footnotes = parse_docx(DOCX_PATH, fn_start)

    print(f"\nParsed {len(surahs)} surahs:")
    for s in surahs:
        fn_count = sum(1 for _, vt in s["verses"] if "[^" in vt)
        print(
            f"  Surah {s['chapter_number']:2d} {s['arabic_name']:<15} "
            f"| {len(s['verses']):3d} verses | {fn_count:3d} with fn refs"
        )

    if len(surahs) != 18:
        print(
            f"\nWARNING: Expected 18 surahs (19-36), got {len(surahs)}. "
            "Check parsing output above before proceeding."
        )
        resp = input("Continue anyway? [y/N] ")
        if resp.strip().lower() != "y":
            sys.exit("Aborted.")

    # --- Insert ---
    print("\nInserting into DB ...")
    total_verses = insert_into_db(DB_PATH, surahs, footnotes)

    # --- Verify ---
    print("\n--- Verification ---")
    con = sqlite3.connect(DB_PATH)
    c = con.cursor()

    c.execute("SELECT COUNT(*) FROM malayalam_surahs")
    surah_count = c.fetchone()[0]
    c.execute("SELECT COUNT(*) FROM malayalam_verses")
    verse_count = c.fetchone()[0]
    c.execute("SELECT COUNT(*) FROM malayalam_footnotes")
    fn_total = c.fetchone()[0]
    c.execute(
        "SELECT COUNT(*) FROM malayalam_verses "
        "WHERE surah_id >= 19 AND malayalam_translation LIKE '%[^%'"
    )
    verses_with_fn = c.fetchone()[0]

    # Sample annotated verses in surah 19
    c.execute(
        "SELECT verse_number, malayalam_translation FROM malayalam_verses "
        "WHERE surah_id = 19 AND malayalam_translation LIKE '%[^%' "
        "ORDER BY verse_number LIMIT 3"
    )
    samples = c.fetchall()
    con.close()

    print(f"malayalam_surahs  total rows  : {surah_count}")
    print(f"malayalam_verses  total rows  : {verse_count}")
    print(f"malayalam_footnotes total rows: {fn_total}")
    print(f"Part-III verses with [^N]     : {verses_with_fn}")
    if samples:
        print("\nSample annotated verses (Surah 19):")
        for vn, vt in samples:
            print(f"  v{vn}: {vt[:120]}")

    print(f"\nDone. Inserted {len(surahs)} surahs, {total_verses} verses, "
          f"{len(footnotes)} footnotes.")


if __name__ == "__main__":
    main()
