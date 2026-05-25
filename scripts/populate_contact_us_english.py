"""
Adds a 'contact_us_content' table to quran_asad.sqlite and inserts the
English contact page content.
"""

import sqlite3
import os

DB_PATH = os.path.join(
    os.path.dirname(__file__), '..', 'assets', 'db', 'quran_asad.sqlite'
)

CREATE_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS contact_us_content (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    description TEXT,
    address TEXT,
    email TEXT,
    mobile TEXT
);
"""

TITLE = "Contact Us"

DESCRIPTION = (
    "The website, www.quranasadmalayalam.in based in India, is a free non-profit "
    "Islamic knowledge resource with Malayalam and English language translations of "
    "Muhammad Asad's Qur'an commentary, The Message of The Qur'an with links to "
    "several other Qur'an and Hadeeth translations. The site sincerely attempts to "
    "provide and promote authentic knowledge base for the global audience by creating "
    "Islamic software and services - Apps for iOS, Android and the web - that are "
    "beneficial for not only the Muslims but also for anyone interested in learning "
    "Islam, its holy book, the Qur'an and Prophet's traditions and history. This has "
    "a complete Qur'an text (Mus'haf) and an option (with links) for Qur'an audio "
    "with recitations of the most popular and globally recognized reciters like "
    "Sheikh Abdul Rahman Al-Sudais and Abdul Rahman Al-Ossi who are renowned Quranic "
    "reciters celebrated for their distinct, melodious, and emotionally moving styles "
    "that will have a profound impact on listeners.\n\n"
    "We will continuously try to improve the site and expand its contents with new "
    "and useful features. If you feel that this venture is beneficial to the seekers "
    "of TRUTH, please DONATE NOW. Your contributions will be a sure way for us to "
    "continue this noble endeavour, making this available free of cost and ads free "
    "for generations."
)

ADDRESS = "Shadan, Check Post Road, Puthiyangadi, Kozhikode - 673021. Kerala. India."
EMAIL = "kcsaleem07@gmail.com"
MOBILE = "+91 9447 486930"


def main():
    db_path = os.path.normpath(DB_PATH)
    print(f"Opening database: {db_path}")

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Drop existing table if any (for idempotent re-runs)
    cursor.execute("DROP TABLE IF EXISTS contact_us_content")
    cursor.execute(CREATE_TABLE_SQL)

    cursor.execute(
        "INSERT INTO contact_us_content (title, description, address, email, mobile) VALUES (?, ?, ?, ?, ?)",
        (TITLE, DESCRIPTION, ADDRESS, EMAIL, MOBILE),
    )

    conn.commit()

    # Verify
    cursor.execute("SELECT * FROM contact_us_content")
    rows = cursor.fetchall()
    print(f"Inserted {len(rows)} row(s) into contact_us_content table.")
    for row in rows:
        print(f"  id={row[0]}, title={row[1][:30]}..., address={row[3]}")

    conn.close()
    print("Done.")


if __name__ == "__main__":
    main()
