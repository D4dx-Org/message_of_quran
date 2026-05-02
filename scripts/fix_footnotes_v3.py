#!/usr/bin/env python3
"""
Migration script v3: Extract ALL embedded footnotes from quran_asad.sqlite.

Handles:
  - Footnotes separated by \\n\\n
  - First footnote glued to verse text (space-separated)
  - Footnotes nested within other footnotes' text
  - Wraps inline refs in (N) format for Dart regex
"""

import sqlite3
import re
import os

DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'assets', 'db', 'quran_asad.sqlite')

# Regex: sentence-end char (optionally followed by inline-ref digits),
# then whitespace, then a standalone footnote number, then space + text.
_FN_SPLIT_RE = re.compile(
    r'(?<=[.!?";:\]\)])'   # lookbehind: sentence-ending punctuation
    r'(\d*)'               # optional inline-ref digits glued to punctuation
    r'\s+'                 # whitespace gap
    r'(\d+)'               # standalone footnote number
    r'\s+'                 # space before text
    r'(?=[A-Za-z"\'\(])'   # lookahead: footnote text starts with letter/quote/paren
)


def split_text_block(text):
    """
    Split a text block that may contain multiple footnotes into
    (leading_text, [(fn_num, fn_text), ...]).

    The leading text is everything before the first embedded footnote start.
    """
    m = _FN_SPLIT_RE.search(text)
    if not m:
        return text, []

    # Decide the split position:
    # - group(1) is the inline-ref digits (part of leading text)
    # - group(2) is the footnote number (start of embedded footnote)
    inline_ref = m.group(1)  # may be empty
    fn_num = int(m.group(2))

    leading_end = m.start() + len(inline_ref)
    fn_body_start = m.end()

    leading = text[:leading_end].strip()
    remainder = text[fn_body_start:].strip()

    # The remainder is: "<fn_text> ... maybe more footnotes"
    # Recursively split:
    footnotes = []
    current_num = fn_num
    current_text = remainder

    # Try to find the NEXT footnote start within this remainder
    while True:
        m2 = _FN_SPLIT_RE.search(current_text)
        if m2:
            inline2 = m2.group(1)
            next_num = int(m2.group(2))
            split_end = m2.start() + len(inline2)
            fn_body = current_text[:split_end].strip()

            if len(fn_body) > 10:  # sanity: footnote text should be substantial
                footnotes.append((current_num, fn_body))
            else:
                # Too short — likely a false split. Keep as part of previous text.
                footnotes.append((current_num, current_text.strip()))
                break

            current_num = next_num
            current_text = current_text[m2.end():].strip()
        else:
            # No more splits — remaining text is last footnote
            if current_text.strip():
                footnotes.append((current_num, current_text.strip()))
            break

    return leading, footnotes


def extract_verse_and_footnotes(text):
    """
    Full extraction: split verse text into clean verse + all footnotes.
    """
    # Step 1: Split by double-newline
    parts = text.split('\n\n')

    # Process parts[1:] — each should be a footnote (possibly multi-footnote)
    later_fns = []
    for part in parts[1:]:
        part = part.strip()
        m = re.match(r'^(\d+)\s+(.*)', part, re.DOTALL)
        if m:
            fn_num = int(m.group(1))
            fn_text = m.group(2).strip()
            # Check if this footnote text contains more footnotes
            _, sub_fns = split_text_block(f".{fn_num} {fn_text}")
            if sub_fns:
                # First sub_fn's text may be truncated — reconstruct
                leading, nested = split_text_block(fn_text)
                later_fns.append((fn_num, leading))
                later_fns.extend(nested)
            else:
                later_fns.append((fn_num, fn_text))

    # Step 2: Process parts[0] — contains verse text + possibly first footnote(s)
    first_part = parts[0]
    leading, first_fns = split_text_block(first_part)

    # leading = clean verse text
    # first_fns = footnotes found within the first text block

    all_fns = first_fns + later_fns
    return leading, all_fns


def wrap_inline_refs(verse_text, valid_fn_numbers):
    """
    Replace bare inline footnote refs with (N) format.
    Only wraps numbers present in valid_fn_numbers.
    """
    def replacer(match):
        num = int(match.group(1))
        if num in valid_fn_numbers:
            return f'({num})'
        return match.group(0)

    return re.sub(
        r'(?<=[^\d\s])(\d+)(?=[\s,.;:!?\-\]\)]|$)',
        replacer,
        verse_text,
    )


def main():
    db = sqlite3.connect(DB_PATH)
    db.execute('PRAGMA journal_mode=WAL')

    # Existing footnotes
    existing = {}
    for row in db.execute('SELECT surah_number, footnote_number FROM footnotes'):
        existing.setdefault(row[0], set()).add(row[1])

    stats = {'extracted': 0, 'cleaned': 0, 'wrapped': 0}

    for surah in range(1, 115):
        verses = db.execute(
            'SELECT id, verse_number, text FROM verses WHERE surah_number=? ORDER BY verse_number',
            (surah,),
        ).fetchall()

        surah_fns = existing.get(surah, set())

        # Pass 1: Extract embedded footnotes
        cleaned_verses = []
        for vid, vnum, text in verses:
            verse_text, footnotes = extract_verse_and_footnotes(text)

            if footnotes:
                stats['cleaned'] += 1
                for fn_num, fn_text in footnotes:
                    if fn_num not in surah_fns and len(fn_text) > 10:
                        db.execute(
                            'INSERT INTO footnotes (surah_number, footnote_number, text) VALUES (?, ?, ?)',
                            (surah, fn_num, fn_text),
                        )
                        surah_fns.add(fn_num)
                        stats['extracted'] += 1

            cleaned_verses.append((vid, vnum, verse_text, text))

        # Pass 2: Wrap inline refs
        for vid, vnum, verse_text, original_text in cleaned_verses:
            new_text = wrap_inline_refs(verse_text, surah_fns)
            if new_text != original_text:
                db.execute('UPDATE verses SET text=? WHERE id=?', (new_text, vid))
                stats['wrapped'] += 1

        existing[surah] = surah_fns

    db.commit()

    # Report
    total = db.execute('SELECT COUNT(*) FROM footnotes').fetchone()[0]
    print(f"Extracted {stats['extracted']} new footnotes")
    print(f"Cleaned  {stats['cleaned']} verses")
    print(f"Wrapped  {stats['wrapped']} verses")
    print(f"Total footnotes: {total}")

    # Spot checks
    print("\n--- Spot checks ---")
    for s, v in [(1, 1), (1, 7), (2, 3), (2, 30), (2, 34), (2, 40), (2, 71)]:
        t = db.execute(
            'SELECT text FROM verses WHERE surah_number=? AND verse_number=?', (s, v)
        ).fetchone()[0]
        print(f"  s{s}v{v}: {t[:140]}")

    # Check remaining bare refs
    print("\n--- Remaining bare refs ---")
    total_bare = 0
    for surah in range(1, 115):
        verses = db.execute(
            'SELECT verse_number, text FROM verses WHERE surah_number=?', (surah,)
        ).fetchall()
        surah_fns = existing.get(surah, set())
        for vn, t in verses:
            bare = re.findall(r'(?<=[^\d\s(])(\d+)(?=[\s,.;:!?\-\]\)]|$)', t)
            for b in bare:
                num = int(b)
                if num not in surah_fns:
                    total_bare += 1
    print(f"  Total bare refs without footnote in table: {total_bare}")

    db.close()


if __name__ == '__main__':
    main()
