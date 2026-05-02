#!/usr/bin/env python3
"""
Migration script v2: Extract embedded footnotes from quran_asad.sqlite verse text.

Strategy:
  1. For each verse, split text into VERSE portion and FOOTNOTE portion(s).
  2. The split point is found by looking for a SPACE-preceded number after
     sentence-ending punctuation, which signals the start of embedded footnote text.
  3. Each embedded footnote starts with its number (e.g., "31 This passage...").
  4. Extracted footnotes go into the `footnotes` table.
  5. Inline footnote refs (bare numbers after punctuation/letters) are wrapped
     in parentheses so the Dart regex \\(\\d+\\) can find them.
"""

import sqlite3
import re
import os

DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'assets', 'db', 'quran_asad.sqlite')

# Sentence-ending punctuation characters
SENT_END = set('.!?";')


def split_verse_and_footnotes(text):
    """
    Split a verse row's text into (verse_text, [(fn_num, fn_text), ...]).

    Algorithm:
      1. Split by \\n\\n — parts[1:] are clearly embedded footnotes if they
         start with a number.
      2. In parts[0], search for the first embedded footnote start:
         - A number preceded by whitespace (after sentence-end punctuation)
         - Followed by substantial text (>15 chars).
    """
    # ---- Step 1: double-newline split ----
    parts = text.split('\n\n')
    later_fns = []
    for part in parts[1:]:
        part = part.strip()
        m = re.match(r'^(\d+)\s+(.*)', part, re.DOTALL)
        if m:
            later_fns.append((int(m.group(1)), m.group(2).strip()))

    first_part = parts[0]

    # ---- Step 2: find embedded footnote start within first_part ----
    # Pattern: sentence-ending char, then possible inline ref (digits glued to
    # the punctuation), then whitespace, then a standalone number, then a space
    # and the beginning of the footnote text.
    #
    # Examples:
    #   "...truth.26 23 Lit.,"       → split before " 23 "
    #   "...in awe! 31 This passage" → split before " 31 "
    #   "...it."22 They said"        → NOT a split (22 is inline ref, no space)

    # Search for:  <sentence-end-char>[optional-inline-ref-digits] <space(s)> <standalone-number> <space> <letter>
    # The standalone number is preceded by at least one space (distinguishing it from inline refs).
    split_match = re.search(
        r'(?<=[.!?";:\]\)])(\d*)\s+(\d+)\s+(?=[A-Za-z"\'])',
        first_part,
    )

    verse_text = first_part
    first_fn = None

    if split_match:
        # The inline ref (if any) is group(1), the footnote number is group(2)
        fn_num = int(split_match.group(2))
        fn_body_start = split_match.end()
        fn_body = first_part[fn_body_start:].strip()

        # Sanity: at least 15 chars of footnote text
        if len(fn_body) > 15:
            # Verse text = everything up to (and including) the inline ref
            # The inline ref is the digits in group(1) (may be empty)
            inline_ref_part = split_match.group(1)
            verse_end = split_match.start() + len(inline_ref_part)
            verse_text = first_part[:verse_end].strip()
            first_fn = (fn_num, fn_body)

    # ---- Step 3: the first_fn body might contain MORE footnotes (single-spaced) ----
    # e.g., "23 Lit., ...from 7:11.\n\n24 Namely,..." — already handled above.
    # But sometimes multiple footnotes are within the same paragraph separated
    # by a pattern like "... end of fn23 text. 24 Start of fn24 text ..."
    # We handle this in a second pass after combining all footnotes.

    all_fns = []
    if first_fn:
        all_fns.append(first_fn)
    all_fns.extend(later_fns)

    # ---- Step 4: split combined footnote text that has multiple footnotes ----
    final_fns = []
    for fn_num, fn_text in all_fns:
        # Check if fn_text contains other footnote starts
        # Pattern: ". N " or similar where N is a different footnote number
        sub_parts = re.split(r'\n\n', fn_text)
        if len(sub_parts) > 1:
            # First sub-part belongs to current footnote
            final_fns.append((fn_num, sub_parts[0].strip()))
            for sp in sub_parts[1:]:
                sp = sp.strip()
                m = re.match(r'^(\d+)\s+(.*)', sp, re.DOTALL)
                if m:
                    final_fns.append((int(m.group(1)), m.group(2).strip()))
        else:
            final_fns.append((fn_num, fn_text))

    return verse_text, final_fns


def wrap_inline_refs(verse_text, valid_fn_numbers):
    """
    Replace bare inline footnote refs with parenthesized versions.
    "Grace:1" → "Grace:(1)", "truth6" → "truth(6)"

    Only wraps numbers present in valid_fn_numbers to avoid false positives.
    """
    def replacer(match):
        num = int(match.group(1))
        if num in valid_fn_numbers:
            return f'({num})'
        return match.group(0)

    # Number directly after a non-digit non-space character,
    # followed by space, comma, period, or end of string.
    return re.sub(r'(?<=[^\d\s])(\d+)(?=[\s,.;:!?\-\]\)]|$)', replacer, verse_text)


def main():
    db = sqlite3.connect(DB_PATH)
    db.execute('PRAGMA journal_mode=WAL')

    # Collect existing footnotes
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

        # ----- Pass 1: Extract embedded footnotes -----
        cleaned_verses = []
        for vid, vnum, text in verses:
            verse_text, footnotes = split_verse_and_footnotes(text)

            if footnotes:
                stats['cleaned'] += 1
                for fn_num, fn_text in footnotes:
                    if fn_num not in surah_fns:
                        db.execute(
                            'INSERT INTO footnotes (surah_number, footnote_number, text) VALUES (?, ?, ?)',
                            (surah, fn_num, fn_text),
                        )
                        surah_fns.add(fn_num)
                        stats['extracted'] += 1

            cleaned_verses.append((vid, vnum, verse_text, text))

        # ----- Pass 2: Wrap inline refs -----
        for vid, vnum, verse_text, original_text in cleaned_verses:
            new_text = wrap_inline_refs(verse_text, surah_fns)
            if new_text != original_text:
                db.execute('UPDATE verses SET text=? WHERE id=?', (new_text, vid))
                stats['wrapped'] += 1

        existing[surah] = surah_fns

    db.commit()

    # ----- Report -----
    total = db.execute('SELECT COUNT(*) FROM footnotes').fetchone()[0]
    print(f"Extracted {stats['extracted']} new footnotes")
    print(f"Cleaned  {stats['cleaned']} verses (removed embedded text)")
    print(f"Wrapped  {stats['wrapped']} verses (inline refs → (N))")
    print(f"Total footnotes in table: {total}")

    # Spot checks
    print("\n--- Spot checks ---")
    for (s, v) in [(1, 1), (1, 7), (2, 3), (2, 30), (2, 34), (2, 40)]:
        t = db.execute(
            'SELECT text FROM verses WHERE surah_number=? AND verse_number=?', (s, v)
        ).fetchone()[0]
        print(f"  s{s}v{v}: {t[:130]}")

    # Check problematic surahs
    print("\n--- Footnote counts for previously-incomplete surahs ---")
    for s in [2, 7, 10, 101, 109]:
        c = db.execute('SELECT COUNT(*) FROM footnotes WHERE surah_number=?', (s,)).fetchone()[0]
        print(f"  Surah {s}: {c} footnotes")

    db.close()


if __name__ == '__main__':
    main()
