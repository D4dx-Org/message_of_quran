# -*- coding: utf-8 -*-
"""
update_malayalam_surah_names_asad.py

Update the Malayalam surah names (and their bracketed meanings) for surahs 1-18
in the `malayalam_surahs` table of the bundled combined database
`assets/db/quran_asad_combined_nw.sqlite`.

Only the `malayalam_name` column is touched. No other tables or columns change.

The runtime parser (lib/core/utils/surah_name_localizer.dart) splits the stored
value on parentheses: the text before "(" is the title, and the text inside
"( )" is the meaning subtitle. So each value is stored as "Name (meaning)".

Idempotent: running multiple times produces the same result.

Usage:
    python scripts/update_malayalam_surah_names_asad.py
"""

import shutil
import sqlite3
import sys
from pathlib import Path

DB_PATH = Path("assets/db/quran_asad_combined_nw.sqlite")

# chapter_number -> "Name (meaning)"
NEW_NAMES = {
    1: "അൽ ഫാതിഹഃ (പ്രാരംഭം)",
    2: "അൽ ബഖറ (പശു)",
    3: "ആലു ഇംറാൻ (ഇംറാൻ കുടുംബം)",
    4: "അന്നിസാഅ് (സ്ത്രീകൾ)",
    5: "അൽ മാഇദ (ഭക്ഷണത്തളിക)",
    6: "അൽ അൻആം (കാലികൾ)",
    7: "അല്‍ അഅ്റാഫ് (വേർതിരിവിന്റെ ഇടം)",
    8: "അന്‍ഫാല്‍ (യുദ്ധമുതലുകൾ)",
    9: "അത്തൗബ (പശ്ചാത്താപം)",
    10: "യൂനുസ് (യോന)",
    11: "ഹൂദ് (പ്രവാചകൻ ഹൂദ്)",
    12: "യൂസുഫ് (യോസേഫ്)",
    13: "അർറഅ്ദ് (ഇടിമുഴക്കം)",
    14: "ഇബ്രാഹീം (അബ്രഹാം)",
    15: "അൽ ഹിജ്ർ (പാറക്കെട്ട്)",
    16: "അന്നഹ്ൽ (തേനീച്ച)",
    17: "അല്‍ ഇസ്റാഅ് (നിശാപ്രയാണം)",
    18: "അൽ-കഹ്ഫ് (ഗുഹ)",
}


def main() -> int:
    if not DB_PATH.exists():
        print(f"ERROR: database not found at {DB_PATH.resolve()}", file=sys.stderr)
        return 1

    backup = DB_PATH.with_suffix(DB_PATH.suffix + ".bak")
    shutil.copy2(DB_PATH, backup)
    print(f"Backup written to {backup}")

    conn = sqlite3.connect(str(DB_PATH))
    try:
        # Ensure changes land in the main DB file with no WAL/SHM sidecars,
        # because the app copies only the main .sqlite bytes from assets.
        conn.execute("PRAGMA journal_mode=DELETE;")

        updated = 0
        for chapter_number, name in sorted(NEW_NAMES.items()):
            cur = conn.execute(
                "UPDATE malayalam_surahs SET malayalam_name = ? "
                "WHERE chapter_number = ?",
                (name, chapter_number),
            )
            if cur.rowcount > 0:
                updated += cur.rowcount

        conn.commit()
        print(f"Updated {updated} row(s) in malayalam_surahs.")

        # Verify
        rows = conn.execute(
            "SELECT chapter_number, malayalam_name FROM malayalam_surahs "
            "WHERE chapter_number <= 18 ORDER BY chapter_number"
        ).fetchall()
        print("\nVerification (chapter -> malayalam_name):")
        for chapter_number, name in rows:
            ok = NEW_NAMES.get(chapter_number) == name
            print(f"  {chapter_number:>2} {'OK ' if ok else 'XX '} {name}")
    finally:
        conn.close()

    # Remove any leftover sidecar files just in case.
    for suffix in ("-wal", "-shm"):
        sidecar = Path(str(DB_PATH) + suffix)
        if sidecar.exists():
            sidecar.unlink()
            print(f"Removed sidecar {sidecar}")

    print("\nDone. Remember to bump DbConstants.quranAsadDbVersion.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
