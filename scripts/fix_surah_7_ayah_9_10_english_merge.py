"""
fix_surah_7_ayah_9_10_english_merge.py

One-time script to normalize the English Asad data for Surah 7 in
quran_asad.sqlite.

It repairs three related source-data issues:
    - split the merged verse text for ayahs 1 and 2
    - split the merged verse text for ayahs 9 and 10
    - extract embedded footnotes 6-10 from footnote 5 and restore the
        missing (8) marker at the end of ayah 9

Run from the repo root (the_message_of_the_quran/):
    python scripts/fix_surah_7_ayah_9_10_english_merge.py
"""

import os
import shutil
import sqlite3
import sys


ASAD_DB = os.path.join("assets", "db", "quran_asad.sqlite")
SURAH_NUMBER = 7
AYAH_1 = 1
AYAH_2 = 2
AYAH_9 = 9
AYAH_10 = 10
MERGED_AYAH_1_2_TEXT = (
    "Alif. Lam. Mim. Sad.(1) A DIVINE WRIT has been bestowed from on high "
    "upon thee - and let there be no doubt about this in thy heart - in "
    "order that thou mayest warn [the erring] thereby, and [thus] admonish "
    "the believers:(2)"
)
AYAH_1_TEXT = "Alif. Lam. Mim. Sad.(1)"
AYAH_2_TEXT = (
    "A DIVINE WRIT has been bestowed from on high upon thee - and let there "
    "be no doubt about this in thy heart - in order that thou mayest warn "
    "[the erring] thereby, and [thus] admonish the believers:(2)"
)
MERGED_TEXT = (
    "whereas those whose weight is light in the balance - it is they who "
    "will have squandered their own selves by their wilful rejection of Our "
    "messages! YEA, INDEED, [O men,] We have given you a [bountiful] place "
    "on earth, and appointed thereon means of livelihood for you: [yet] how "
    "seldom are you grateful!"
)
LEGACY_AYAH_9_TEXT = (
    "whereas those whose weight is light in the balance - it is they who "
    "will have squandered their own selves by their wilful rejection of Our "
    "messages!"
)
AYAH_9_TEXT = (
    "whereas those whose weight is light in the balance - it is they who "
    "will have squandered their own selves by their wilful rejection of Our "
    "messages!(8)"
)
AYAH_10_TEXT = (
    "YEA, INDEED, [O men,] We have given you a [bountiful] place on earth, "
    "and appointed thereon means of livelihood for you: [yet] how seldom "
    "are you grateful!"
)
FOOTNOTE_5_ORIGINAL_TEXT = (
    'Lit., "their plea was nothing but that they said". 6 Cf. 5:109. 7 '
    'Lit., "relate to them with knowledge".\n\n8 Lit., "for that they '
    'were wont to act wrongfully with regard to Our messages".\n\n9 The '
    'sequence of these two statements - "We have created you [i.e., '
    '"brought you into being as living organisms"] and then formed you" '
    '[or "given you your shape", i.e., as human beings]- is meant to '
    'bring out the fact of man\'s gradual development, in the individual '
    'sense, from the embryonic stage to full-fledged existence, as well as '
    'of the evolution of the human race as such.\n\n10 As regards God\'s '
    'allegorical command to the angels to "prostrate themselves" before '
    'Adam, see 2:30-34, and the corresponding notes. The reference to all '
    'mankind which precedes the story of Adam in this surah makes it clear '
    'that his name symbolizes, in this context, the whole human race.\n\n'
    'Western scholars usually take it for granted that the name "Iblis" is '
    'a corruption of the Greek word diabolos, from which the English '
    '"devil" is derived. There is, however, not the slightest evidence '
    'that the pre-Islamic Arabs borrowed this or any other mythological '
    'term from the Greeks - while on the other hand, it is established '
    'that the Greeks derived a good deal of their mythological concepts '
    '(including various deities and their functions) from the much earlier '
    'South-Arabian civilization (cf. Encyclopaedia of Islam I, 379 f.). '
    'One may, therefore, assume with something approaching certainty that '
    'the Greek diabolos is a Hellenized form of the Arabic name for the '
    'Fallen Angel, which, in turn, is derived from the root-verb ablasa, '
    '"he despaired" or "gave up hope" or "became broken in spirit" (see '
    'Lane I, 248). The fact that the noun diabolos ("slanderer" - derived '
    'from the verb diaballein, "to throw [something] across") is of '
    'genuinely Greek origin does not, by itself, detract anything from '
    'this hypothesis: for it is conceivable that the Greeks, with their '
    'well-known tendency to Hellenize foreign names, identified the name '
    '"Iblis" with the, to them, much more familiar term diabolos. - As '
    'regards Iblis\' statement, in the next verse, that he had been '
    'created "out of fire", see surah 38. note 60.'
)
FOOTNOTE_5_TEXT = 'Lit., "their plea was nothing but that they said".'
FOOTNOTE_6_TEXT = 'Cf. 5:109.'
FOOTNOTE_7_TEXT = 'Lit., "relate to them with knowledge".'
FOOTNOTE_8_TEXT = (
    'Lit., "for that they were wont to act wrongfully with regard to Our '
    'messages".'
)
FOOTNOTE_9_TEXT = (
    'The sequence of these two statements - "We have created you [i.e., '
    '"brought you into being as living organisms"] and then formed you" '
    '[or "given you your shape", i.e., as human beings]- is meant to '
    'bring out the fact of man\'s gradual development, in the individual '
    'sense, from the embryonic stage to full-fledged existence, as well as '
    'of the evolution of the human race as such.'
)
FOOTNOTE_10_TEXT = (
    'As regards God\'s allegorical command to the angels to "prostrate '
    'themselves" before Adam, see 2:30-34, and the corresponding notes. '
    'The reference to all mankind which precedes the story of Adam in this '
    'surah makes it clear that his name symbolizes, in this context, the '
    'whole human race.\n\nWestern scholars usually take it for granted '
    'that the name "Iblis" is a corruption of the Greek word diabolos, '
    'from which the English "devil" is derived. There is, however, not '
    'the slightest evidence that the pre-Islamic Arabs borrowed this or '
    'any other mythological term from the Greeks - while on the other '
    'hand, it is established that the Greeks derived a good deal of their '
    'mythological concepts (including various deities and their functions) '
    'from the much earlier South-Arabian civilization (cf. Encyclopaedia '
    'of Islam I, 379 f.). One may, therefore, assume with something '
    'approaching certainty that the Greek diabolos is a Hellenized form of '
    'the Arabic name for the Fallen Angel, which, in turn, is derived from '
    'the root-verb ablasa, "he despaired" or "gave up hope" or "became '
    'broken in spirit" (see Lane I, 248). The fact that the noun diabolos '
    '("slanderer" - derived from the verb diaballein, "to throw '
    '[something] across") is of genuinely Greek origin does not, by '
    'itself, detract anything from this hypothesis: for it is conceivable '
    'that the Greeks, with their well-known tendency to Hellenize foreign '
    'names, identified the name "Iblis" with the, to them, much more '
    'familiar term diabolos. - As regards Iblis\' statement, in the next '
    'verse, that he had been created "out of fire", see surah 38. note '
    '60.'
)
EXPECTED_FOOTNOTES = {
    5: FOOTNOTE_5_TEXT,
    6: FOOTNOTE_6_TEXT,
    7: FOOTNOTE_7_TEXT,
    8: FOOTNOTE_8_TEXT,
    9: FOOTNOTE_9_TEXT,
    10: FOOTNOTE_10_TEXT,
}


def _checkpoint_database(conn):
    cur = conn.cursor()
    full_result = cur.execute("PRAGMA wal_checkpoint(FULL)").fetchone()
    truncate_result = cur.execute("PRAGMA wal_checkpoint(TRUNCATE)").fetchone()
    print(f"Checkpoint FULL: {full_result}")
    print(f"Checkpoint TRUNCATE: {truncate_result}")


def _fetch_verse(cur, ayah_number):
    rows = cur.execute(
        "SELECT id, text FROM verses WHERE surah_number = ? AND verse_number = ?",
        (SURAH_NUMBER, ayah_number),
    ).fetchall()
    if len(rows) > 1:
        raise RuntimeError(
            f"Expected at most one row for {SURAH_NUMBER}:{ayah_number}, found {len(rows)}"
        )
    return rows[0] if rows else None


def _fetch_footnote(cur, footnote_number):
    rows = cur.execute(
        "SELECT id, text FROM footnotes WHERE surah_number = ? AND footnote_number = ?",
        (SURAH_NUMBER, footnote_number),
    ).fetchall()
    if len(rows) > 1:
        raise RuntimeError(
            f"Expected at most one footnote row for {SURAH_NUMBER}:{footnote_number}, "
            f"found {len(rows)}"
        )
    return rows[0] if rows else None


def _print_state(cur, label):
    verse_rows = cur.execute(
        "SELECT id, verse_number, text FROM verses "
        "WHERE surah_number = ? AND verse_number IN (?, ?, ?, ?) "
        "ORDER BY verse_number ASC",
        (SURAH_NUMBER, AYAH_1, AYAH_2, AYAH_9, AYAH_10),
    ).fetchall()
    print(label)
    print("  Verses:")
    for row in verse_rows:
        print(f"  id={row[0]} verse={row[1]} text={row[2]!r}")
    if not verse_rows:
        print("  <no rows>")

    footnote_rows = cur.execute(
        "SELECT id, footnote_number, text FROM footnotes "
        "WHERE surah_number = ? AND footnote_number BETWEEN ? AND ? "
        "ORDER BY footnote_number ASC",
        (SURAH_NUMBER, 5, 10),
    ).fetchall()
    print("  Footnotes:")
    for row in footnote_rows:
        print(f"  id={row[0]} footnote={row[1]} text={row[2]!r}")
    if not footnote_rows:
        print("  <no footnotes>")


def _upsert_footnote(cur, footnote_number, expected_text):
    row = _fetch_footnote(cur, footnote_number)
    if row is None:
        cur.execute(
            "INSERT INTO footnotes (surah_number, footnote_number, text) VALUES (?, ?, ?)",
            (SURAH_NUMBER, footnote_number, expected_text),
        )
        return

    footnote_id, current_text = row
    if current_text != expected_text:
        cur.execute(
            "UPDATE footnotes SET text = ? WHERE id = ?",
            (expected_text, footnote_id),
        )


def _apply_fix(cur):
    ayah_1_row = _fetch_verse(cur, AYAH_1)
    ayah_2_row = _fetch_verse(cur, AYAH_2)
    ayah_9_row = _fetch_verse(cur, AYAH_9)
    ayah_10_row = _fetch_verse(cur, AYAH_10)
    footnote_rows = {
        number: _fetch_footnote(cur, number) for number in range(5, 11)
    }

    if ayah_1_row is None:
        raise RuntimeError(f"Missing required row for {SURAH_NUMBER}:{AYAH_1}")
    if ayah_9_row is None:
        raise RuntimeError(f"Missing required row for {SURAH_NUMBER}:{AYAH_9}")
    if footnote_rows[5] is None:
        raise RuntimeError(f"Missing required footnote row for {SURAH_NUMBER}:5")

    ayah_1_id, ayah_1_text = ayah_1_row
    ayah_2_id = ayah_2_row[0] if ayah_2_row else None
    ayah_2_text = ayah_2_row[1] if ayah_2_row else None
    ayah_9_id, ayah_9_text = ayah_9_row
    ayah_10_id = ayah_10_row[0] if ayah_10_row else None
    ayah_10_text = ayah_10_row[1] if ayah_10_row else None
    footnote_5_id, footnote_5_text = footnote_rows[5]

    already_fixed = (
        ayah_1_text == AYAH_1_TEXT
        and ayah_2_text == AYAH_2_TEXT
        and ayah_9_text == AYAH_9_TEXT
        and ayah_10_text == AYAH_10_TEXT
        and all(
            footnote_rows[number] is not None
            and footnote_rows[number][1] == EXPECTED_FOOTNOTES[number]
            for number in EXPECTED_FOOTNOTES
        )
    )
    if already_fixed:
        print(
            "No changes needed: Surah 7 ayahs 1-2, 9-10, and footnotes 5-10 are already normalized."
        )
        return False

    if ayah_1_text not in {MERGED_AYAH_1_2_TEXT, AYAH_1_TEXT}:
        raise RuntimeError(
            "Unexpected Surah 7:1 text. Aborting to avoid overwriting unknown data."
        )

    if ayah_2_text not in {None, "", AYAH_2_TEXT}:
        raise RuntimeError(
            "Unexpected Surah 7:2 text. Aborting to avoid overwriting unknown data."
        )

    if ayah_9_text not in {MERGED_TEXT, LEGACY_AYAH_9_TEXT, AYAH_9_TEXT}:
        raise RuntimeError(
            "Unexpected Surah 7:9 text. Aborting to avoid overwriting unknown data."
        )

    if ayah_10_text not in {None, "", AYAH_10_TEXT}:
        raise RuntimeError(
            "Unexpected Surah 7:10 text. Aborting to avoid overwriting unknown data."
        )

    if footnote_5_text not in {FOOTNOTE_5_ORIGINAL_TEXT, FOOTNOTE_5_TEXT}:
        raise RuntimeError(
            "Unexpected Surah 7:5 footnote text. Aborting to avoid overwriting unknown data."
        )

    for number in range(6, 11):
        row = footnote_rows[number]
        if row is not None and row[1] != EXPECTED_FOOTNOTES[number]:
            raise RuntimeError(
                f"Unexpected Surah 7 footnote {number} text. Aborting to avoid overwriting unknown data."
            )

    if ayah_1_text != AYAH_1_TEXT:
        cur.execute(
            "UPDATE verses SET text = ? WHERE id = ?",
            (AYAH_1_TEXT, ayah_1_id),
        )

    if ayah_2_id is None:
        cur.execute(
            "INSERT INTO verses (surah_number, verse_number, text) VALUES (?, ?, ?)",
            (SURAH_NUMBER, AYAH_2, AYAH_2_TEXT),
        )
    elif ayah_2_text != AYAH_2_TEXT:
        cur.execute(
            "UPDATE verses SET text = ? WHERE id = ?",
            (AYAH_2_TEXT, ayah_2_id),
        )

    if ayah_9_text != AYAH_9_TEXT:
        cur.execute(
            "UPDATE verses SET text = ? WHERE id = ?",
            (AYAH_9_TEXT, ayah_9_id),
        )

    if ayah_10_id is None:
        cur.execute(
            "INSERT INTO verses (surah_number, verse_number, text) VALUES (?, ?, ?)",
            (SURAH_NUMBER, AYAH_10, AYAH_10_TEXT),
        )
    elif ayah_10_text != AYAH_10_TEXT:
        cur.execute(
            "UPDATE verses SET text = ? WHERE id = ?",
            (AYAH_10_TEXT, ayah_10_id),
        )

    if footnote_5_text != FOOTNOTE_5_TEXT:
        cur.execute(
            "UPDATE footnotes SET text = ? WHERE id = ?",
            (FOOTNOTE_5_TEXT, footnote_5_id),
        )

    for number in range(6, 11):
        _upsert_footnote(cur, number, EXPECTED_FOOTNOTES[number])

    return True


def main():
    if not os.path.isfile(ASAD_DB):
        print(f"ERROR: DB not found at {ASAD_DB}")
        sys.exit(1)

    backup = ASAD_DB + ".bak"
    temp_db = ASAD_DB + ".tmp"
    patched_db = ASAD_DB + ".patched"
    shutil.copy2(ASAD_DB, temp_db)
    print(f"Working copy {ASAD_DB} -> {temp_db}")

    conn = sqlite3.connect(temp_db)
    replace_succeeded = False
    try:
        cur = conn.cursor()
        _print_state(cur, "Before:")
        changed = _apply_fix(cur)
        if changed:
            shutil.copy2(ASAD_DB, backup)
            print(f"Backed up {ASAD_DB} -> {backup}")
            conn.commit()
            _checkpoint_database(conn)
        _print_state(cur, "After:")
        if changed:
            conn.close()
            conn = None
            try:
                os.replace(temp_db, ASAD_DB)
                replace_succeeded = True
                if os.path.exists(patched_db):
                    os.remove(patched_db)
            except PermissionError as exc:
                shutil.copy2(temp_db, patched_db)
                raise RuntimeError(
                    "Could not replace assets/db/quran_asad.sqlite because another "
                    "app still has it open. Close DB Browser for SQLite (or any "
                    "other app using the file) and rerun this script. A patched copy "
                    f"was saved to {patched_db}."
                ) from exc
            print("Done.")
    finally:
        if conn is not None:
            conn.close()
        if os.path.exists(temp_db):
            os.remove(temp_db)


if __name__ == "__main__":
    main()