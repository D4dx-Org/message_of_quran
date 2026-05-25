"""
Add 'translator' table to quran_asad.sqlite with K.C. Saleem's bio.
Run from the project root:
    python scripts/add_english_translator.py
"""

import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'assets', 'db', 'quran_asad.sqlite')

BIO = """Born in 1954 as the son of Moosa Nasih, a prominent Urdu and Persian language scholar and poet, and the Malayalam translator of Muhammad Iqbal's poem Saare Jahan Se Acha into Malayalam language, and Cheerayil Pathootty. Studied at Mubaraka High School and Government Brennen College. Master's degree from Calicut University, Kerala, India.

Worked as a correspondent for the Times of Oman published from Oman, sub editor of Prabodhanam Weekly, founding editorial board member of Malarvadi children's magazine, and founding editor of an online portal called Interactive. He was the Regional Director in the State Information and Public Relations Department. He was an Information Officer in various districts and in New Delhi.

He authored four books, Thankunju Ponkunju, a book on Islamic parenting, Nanmayude Vrikshangal, selected articles, Muhammad Asad's Travels and Other Reading Journeys, a collection of articles and an autobiography named Life's Colours in Memories. He translated into Malayalam more than a dozen books of renowned authors that include The Quran with References to the Bible by Dr. Safi Kaskas and Dr. David Hungerford which is a comparative reading of the Quran and Bible, Muhammad Asad's Qur'an commentary The Message of the Qur'an, and Ziauddin Sardar's Desperately Seeking Paradise.

In addition, he translated three books by the U.A.E. Vice President, Prime Minister and Ruler of Dubai Sheikh Mohammed bin Rashid Al Maktoum - My Vision, Flashes of Thought and Reflections on Happiness and Positivity, two books by Ismail Raji Al Farooqui, Tawheed: Its Implications for Thought and Life and Islamization of Knowledge, Muhammed Asad's Principles of State and Government in Islam, and Mohammed A.J. Al Fahim's From Rags to Riches: A Story of Abu Dhabi.

His wife is Shameem, who was a teacher and head in various government high schools. Children are Shauqeen Mizaj, engineer, writer, and journalist by profession and wife of Riyas Babu, a senior officer in the Indian Information Service, senior data engineer Javed Farzan in Ottawa, Canada who married Dr. Labeeba Mahmood, and audiologist Farishtha Thahseen in Toronto, wife of Inswaf Rahmatullah (Bell, Canada)."""

EMAIL = "kcsaleem07@gmail.com"
ADDRESS = "Shadan, Check Post Road, Puthiyangadi, Kozhikode - 673021. Kerala. India."

def main():
    db_path = os.path.abspath(DB_PATH)
    print(f"Opening database: {db_path}")

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Drop existing table if re-running
    cursor.execute("DROP TABLE IF EXISTS translator")

    # Create translator table
    cursor.execute("""
        CREATE TABLE translator (
            id INTEGER PRIMARY KEY,
            name TEXT,
            role TEXT,
            bio TEXT,
            email TEXT,
            address TEXT
        )
    """)

    # Insert K.C. Saleem's data
    cursor.execute(
        "INSERT INTO translator (id, name, role, bio, email, address) VALUES (?, ?, ?, ?, ?, ?)",
        (1, "K.C. Saleem", "Translator", BIO, EMAIL, ADDRESS)
    )

    conn.commit()
    conn.close()
    print("Done! 'translator' table created and populated.")


if __name__ == "__main__":
    main()
