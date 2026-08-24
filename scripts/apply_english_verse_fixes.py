"""One-off: apply the English verse-split fixes (recovered from body_raw
parsing gaps) to the app's bundled sqlite, mirroring the same fix already
applied to the backend's staging sqlite.

Idempotent: re-running just re-applies the same UPDATE/INSERT-or-replace,
safe to run more than once.
"""
import json
import sqlite3
import sys


def apply_fixes(db_path, diff_path):
    with open(diff_path, encoding="utf-8") as f:
        diff = json.load(f)

    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    for row in diff["updates"]:
        cur.execute(
            "UPDATE verses SET text = ? WHERE surah_number = ? AND verse_number = ?",
            (row["text"], row["surah"], row["verse"]),
        )

    for row in diff["inserts"]:
        cur.execute(
            "DELETE FROM verses WHERE surah_number = ? AND verse_number = ?",
            (row["surah"], row["verse"]),
        )
        cur.execute(
            "INSERT INTO verses (surah_number, verse_number, text) VALUES (?, ?, ?)",
            (row["surah"], row["verse"], row["text"]),
        )

    conn.commit()
    conn.close()
    print(f"Applied {len(diff['updates'])} updates, {len(diff['inserts'])} inserts to {db_path}")


if __name__ == "__main__":
    for path in sys.argv[1:]:
        apply_fixes(path, "../MOQ Backend/scripts/_verse-fix-diff.json")
