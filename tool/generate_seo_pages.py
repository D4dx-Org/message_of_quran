"""
generate_seo_pages.py

Generates static, crawlable HTML for the Qur'an text and writes it into web/.

The site is a Flutter CanvasKit app: it paints into a canvas, so a crawler
receives a document with no words in it and nothing here can be indexed. These
pages put the actual text — Arabic, Muhammad Asad's English, the Malayalam
translation and Asad's footnotes — into real HTML that search engines can read,
each one linking into the app for the reading experience.

Netlify serves a matching file before falling back to the SPA redirect, so
these paths resolve to the static page while every app route still works.

Reads the app's bundled sqlite, which holds the whole book:

    python tool/generate_seo_pages.py ../message_of_quran/assets/db/quran_asad_combined_nw.sqlite
"""
import html
import io
import os
import re
import shutil
import sqlite3
import sys

SITE = 'https://quranasadmalayalam.in'
OUT_ROOT = os.path.join('web', 'quran')

# Asad marks footnotes inline as "(12)"; the Malayalam carries "[^12]".
EN_MARKER = re.compile(r'\((\d{1,3})\)')
ML_MARKER = re.compile(r'\s*\[\^\d{1,4}\]')


def slugify(name):
    s = name.lower()
    s = s.replace("'", '').replace('’', '')
    s = re.sub(r'[^a-z0-9]+', '-', s)
    return s.strip('-')


def esc(text):
    return html.escape(text or '', quote=False)


def english_with_notes(text):
    """Turn Asad's inline (12) into a superscript link to the footnote."""
    def repl(m):
        n = m.group(1)
        return f'<sup><a href="#note-{n}">{n}</a></sup>'
    return EN_MARKER.sub(repl, esc(text))


def page(title, description, canonical, body, extra_head=''):
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{esc(title)}</title>
<meta name="description" content="{html.escape(description, quote=True)}">
<link rel="canonical" href="{canonical}">
<meta name="robots" content="index, follow, max-snippet:-1">
<meta property="og:type" content="article">
<meta property="og:site_name" content="Quran Asad Malayalam">
<meta property="og:title" content="{html.escape(title, quote=True)}">
<meta property="og:description" content="{html.escape(description, quote=True)}">
<meta property="og:url" content="{canonical}">
<meta property="og:image" content="{SITE}/icons/Icon-512.png">
{extra_head}<style>
:root {{ color-scheme: light dark; }}
body {{ margin:0 auto; padding:1.5rem 1.25rem 4rem; max-width:44rem;
  font:16px/1.65 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;
  color:#1a1a1a; background:#fffdf7; }}
a {{ color:#1b4571; }}
header nav {{ font-size:.9rem; margin-bottom:1.5rem; }}
h1 {{ font-size:1.6rem; line-height:1.3; margin:.2rem 0 .4rem; }}
h2 {{ font-size:1.15rem; margin:2.5rem 0 .75rem; }}
.sub {{ color:#555; margin:0 0 1.5rem; }}
.verse {{ padding:1rem 0; border-bottom:1px solid #e8e3d8; }}
.num {{ font-size:.8rem; color:#777; }}
.ar {{ font-size:1.5rem; line-height:2.1; direction:rtl; text-align:right; margin:.4rem 0; }}
.en {{ margin:.5rem 0; }}
.ml {{ margin:.5rem 0; color:#333; }}
.notes li {{ margin-bottom:.9rem; }}
.cta {{ display:inline-block; margin:1.25rem 0; padding:.7rem 1.1rem;
  background:#1b4571; color:#fff; border-radius:8px; text-decoration:none; }}
footer {{ margin-top:3rem; font-size:.85rem; color:#666; }}
@media (prefers-color-scheme: dark) {{
  body {{ color:#e8e8e8; background:#12181f; }}
  a {{ color:#7fb2e5; }} .ml {{ color:#ccc; }}
  .verse {{ border-bottom-color:#2a323b; }} .sub, .num, footer {{ color:#9aa4ae; }}
}}
</style>
</head>
<body>
{body}
<footer>
<p><a href="{SITE}/">Quran Asad Malayalam</a> — The Message of the Qur'an by
Muhammad Asad, with the Malayalam translation by K.C. Saleem. Free to read, no
advertising.</p>
</footer>
</body>
</html>
"""


def main(db_path):
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    surahs = cur.execute(
        'SELECT number, name, translation, period, ayath_count, malayalam_name '
        'FROM surahs ORDER BY number'
    ).fetchall()
    if len(surahs) != 114:
        raise SystemExit(f'ABORTED: expected 114 surahs, found {len(surahs)}')

    if os.path.isdir(OUT_ROOT):
        shutil.rmtree(OUT_ROOT)
    os.makedirs(OUT_ROOT)

    slugs = {}
    for number, name, translation, period, ayahs, ml_name in surahs:
        slugs[number] = f'{number}-{slugify(name)}'

    written = []
    for idx, (number, name, translation, period, ayahs, ml_name) in enumerate(surahs):
        arabic = dict(
            cur.execute(
                'SELECT ayaid, AyaHText FROM quranayas WHERE suraid = ?', (number,)
            ).fetchall()
        )
        english = dict(
            cur.execute(
                'SELECT verse_number, text FROM verses WHERE surah_number = ?', (number,)
            ).fetchall()
        )
        malayalam = dict(
            cur.execute(
                'SELECT verse_number, malayalam_translation FROM malayalam_verses '
                'WHERE surah_id = ?',
                (number,),
            ).fetchall()
        )
        notes = cur.execute(
            'SELECT footnote_number, text FROM footnotes WHERE surah_number = ? '
            'ORDER BY footnote_number',
            (number,),
        ).fetchall()

        ml_title = (ml_name or '').split('(')[0].strip()
        title = (
            f"Surah {name} ({translation}) — Muhammad Asad translation "
            f"with Malayalam"
        )
        description = (
            f"Surah {name}, {translation} — all {ayahs} verses with Muhammad "
            f"Asad's English translation from The Message of the Qur'an, the "
            f"Malayalam translation by K.C. Saleem, the Arabic text and Asad's "
            f"footnotes."
        )
        canonical = f'{SITE}/quran/{slugs[number]}/'

        rows = []
        for verse in range(1, (ayahs or 0) + 1):
            ar = arabic.get(verse, '')
            en = english.get(verse, '')
            ml = ML_MARKER.sub('', malayalam.get(verse, '') or '').strip()
            if not (ar or en or ml):
                continue
            block = [f'<div class="verse" id="v{verse}">',
                     f'<div class="num">{number}:{verse}</div>']
            if ar:
                block.append(f'<p class="ar" lang="ar" dir="rtl">{esc(ar)}</p>')
            if en:
                block.append(f'<p class="en">{english_with_notes(en)}</p>')
            if ml:
                block.append(f'<p class="ml" lang="ml">{esc(ml)}</p>')
            block.append('</div>')
            rows.append('\n'.join(block))

        note_items = '\n'.join(
            f'<li id="note-{n}"><strong>{n}.</strong> {esc(t)}</li>' for n, t in notes
        )

        prev_link = (
            f'<a href="{SITE}/quran/{slugs[number - 1]}/">← Surah {surahs[idx - 1][1]}</a>'
            if number > 1 else ''
        )
        next_link = (
            f'<a href="{SITE}/quran/{slugs[number + 1]}/">Surah {surahs[idx + 1][1]} →</a>'
            if number < 114 else ''
        )

        jsonld = f"""<script type="application/ld+json">
{{"@context":"https://schema.org","@type":"Article",
"headline":{sql_json(title)},
"description":{sql_json(description)},
"inLanguage":["en","ml","ar"],
"isPartOf":{{"@type":"Book","name":"The Message of the Qur'an",
"author":{{"@type":"Person","name":"Muhammad Asad"}},
"translator":{{"@type":"Person","name":"K.C. Saleem"}}}},
"mainEntityOfPage":"{canonical}"}}
</script>
"""

        body = f"""<header>
<nav><a href="{SITE}/">Home</a> › <a href="{SITE}/quran/">The Message of the Qur'an</a> › Surah {esc(name)}</nav>
<h1>Surah {esc(name)} — {esc(translation)}</h1>
<p class="sub">{esc(ml_title)} · Surah {number} of 114 · {ayahs} verses · Revealed in {esc(period)}<br>
Muhammad Asad's English translation with the Malayalam translation by K.C. Saleem.</p>
<a class="cta" href="{SITE}/surah/{number}">Read Surah {esc(name)} in the app →</a>
</header>
<main>
{chr(10).join(rows)}
{f'<h2>Footnotes by Muhammad Asad</h2><ol class="notes">{note_items}</ol>' if note_items else ''}
</main>
<nav>{prev_link} {next_link}</nav>
"""
        out_dir = os.path.join(OUT_ROOT, slugs[number])
        os.makedirs(out_dir, exist_ok=True)
        io.open(os.path.join(out_dir, 'index.html'), 'w', encoding='utf-8',
                newline='\n').write(page(title, description, canonical, body, jsonld))
        written.append((number, name, translation, ayahs, period, slugs[number]))

    # index of all 114
    items = '\n'.join(
        f'<li><a href="{SITE}/quran/{slug}/">{n}. Surah {esc(nm)}</a> — '
        f'{esc(tr)} · {ay} verses · {esc(pd)}</li>'
        for n, nm, tr, ay, pd, slug in written
    )
    index_body = f"""<header>
<nav><a href="{SITE}/">Home</a> › The Message of the Qur'an</nav>
<h1>The Message of the Qur'an — Muhammad Asad</h1>
<p class="sub">All 114 surahs with Muhammad Asad's English translation, the
Malayalam translation by K.C. Saleem, the Arabic text and Asad's footnotes.</p>
<a class="cta" href="{SITE}/">Open the app →</a>
</header>
<main>
<p><strong>The Message of the Qur'an</strong> is Muhammad Asad's translation and
commentary, first published in 1980 after a lifetime's research, and widely held
to be among the most significant English renderings of the Qur'an. Asad — born
Leopold Weiss in 1900 — spent years among the Bedouin of Arabia, and that
grounding in classical Arabic usage shapes the translation throughout. This site
carries his complete text together with the Malayalam translation by
K.C. Saleem.</p>
<h2>All 114 surahs</h2>
<ol>{items}</ol>
</main>
"""
    io.open(os.path.join(OUT_ROOT, 'index.html'), 'w', encoding='utf-8',
            newline='\n').write(page(
        "The Message of the Qur'an by Muhammad Asad — all 114 surahs, English and Malayalam",
        "Muhammad Asad's complete translation of the Qur'an, The Message of the "
        "Qur'an, with the Malayalam translation by K.C. Saleem: all 114 surahs "
        "verse by verse with the Arabic text and Asad's footnotes.",
        f'{SITE}/quran/', index_body))

    print(f'wrote {len(written)} surah pages plus the index into {OUT_ROOT}')
    return written


def sql_json(text):
    import json
    return json.dumps(text, ensure_ascii=False)


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    main(sys.argv[1])
