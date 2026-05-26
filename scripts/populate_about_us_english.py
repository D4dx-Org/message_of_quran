"""
Adds an 'about_us' table to quran_asad.sqlite and inserts the
English About Us page content.
"""

import sqlite3
import os

DB_PATH = os.path.join(
    os.path.dirname(__file__), '..', 'assets', 'db', 'quran_asad.sqlite'
)

CREATE_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS about_us (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    description TEXT,
    signed_by TEXT
);
"""

TITLE = "About Us"

DESCRIPTION = (
    "The Message of The Qur'an by Muhammad Asad is a comprehensive digital platform "
    "developed by D4DX INNOVATIONS LLP with the aim of making the eternal message of "
    "the Holy Quran more accessible and meaningful to people around the world. Available "
    "on iOS, Android, and Web platforms, this initiative is a user-friendly system that "
    "helps people read, understand, and apply the Quran in their lives.\n\n"
    "The platform aims to provide a seamless experience across devices by combining "
    "modern technology with authentic Islamic content. This will make it possible to "
    "learn the concepts of the Quran, understand its meanings and explanations, and "
    "establish a closer connection with the Book of Allah.\n\n"
    "Designed with simplicity, ease of use, and spiritual growth in mind, this platform "
    "will undoubtedly serve as a spiritual companion for learning, reflection, and "
    "personal growth. Through such initiatives, D4DX INNOVATIONS LLP aims to leverage "
    "the potential of digital technology to bring beneficial knowledge to more people."
)

SIGNED_BY = "D4DX INNOVATIONS LLP"


def main():
    db_path = os.path.normpath(DB_PATH)
    print(f"Opening database: {db_path}")

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Drop existing table if any (for idempotent re-runs)
    cursor.execute("DROP TABLE IF EXISTS about_us")
    cursor.execute(CREATE_TABLE_SQL)

    cursor.execute(
        "INSERT INTO about_us (title, description, signed_by) VALUES (?, ?, ?)",
        (TITLE, DESCRIPTION, SIGNED_BY),
    )

    conn.commit()

    # Verify
    cursor.execute("SELECT * FROM about_us")
    rows = cursor.fetchall()
    print(f"Inserted {len(rows)} row(s) into about_us table.")
    for row in rows:
        print(f"  id={row[0]}, title={row[1]}, signed_by={row[3]}")

    conn.close()
    print("Done.")


if __name__ == "__main__":
    main()
