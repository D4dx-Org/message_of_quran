"""
generate_app_pages.py

Gives the app's own routes something to show while Flutter is still loading.

The site is a Flutter CanvasKit app: 2.8MB of engine and application code has
to arrive before a single word is painted, which is 5 seconds on a good
connection and far worse on mobile data. Until then the document is empty.

tool/generate_seo_pages.py already writes the whole book into /quran/ for
crawlers. These pages solve the other half: the routes people actually open.
Each one carries the start of the surah as real HTML that paints with the
document, and the Flutter bootstrap underneath it. When the app announces its
first frame the static layer is removed and the real screen takes over.

Netlify serves a matching file before falling back to the SPA redirect, so
/surah/2 resolves to the generated page while every other app route still
falls through to index.html as before. The pages are written as <n>.html
rather than <n>/index.html because Netlify answers a directory request with
a 301 to its trailing-slash form, and that redirect costs a round trip on
exactly the request this is meant to make fast.

    python tool/generate_app_pages.py
"""
import html
import io
import json
import os
import re
import shutil
import sys
import urllib.request

SITE = 'https://quranasadmalayalam.in'
API = 'https://asad-pwuw2.ondigitalocean.app/api/v1'
OUT_ROOT = os.path.join('web', 'surah')
INDEX = os.path.join('web', 'index.html')

# How much of a surah to prerender. Enough to fill the screen a few times over
# for someone who starts reading immediately -- the app replaces this with the
# full, interactive surah within seconds, and /quran/ carries the whole text
# for anyone (or anything) that wants it without JavaScript.
PRERENDER_VERSES = 20

# Asad marks footnotes inline as "(12)"; the Malayalam carries "[^12]". Neither
# marker means anything without the footnote list, which is not prerendered.
EN_MARKER = re.compile(r'\((\d{1,3})\)')
ML_MARKER = re.compile(r'\s*\[\^\d{1,4}\]')

# Kept in step with tool/generate_seo_pages.py so both point at the same URLs.
SLUG_STRIP = re.compile(r'[^a-z0-9]+')


def slugify(name):
    s = (name or '').lower().replace("'", '').replace('’', '')
    return SLUG_STRIP.sub('-', s).strip('-')


def esc(text):
    return html.escape(text or '', quote=False)


def attr(text):
    return html.escape(text or '', quote=True)


def get(path, query=None):
    url = API + path
    if query:
        url += '?' + '&'.join('%s=%s' % kv for kv in query.items())
    with urllib.request.urlopen(url, timeout=60) as r:
        return json.loads(r.read().decode('utf-8'))


def clean_en(text):
    """Drop Asad's inline note markers; the notes themselves are not here."""
    return EN_MARKER.sub('', esc(text)).replace('  ', ' ').strip()


def clean_ml(text):
    return ML_MARKER.sub('', esc(text or '')).strip()


# The static layer sits above the Flutter view and scrolls on its own, so a
# reader can start before the engine has arrived. Styling deliberately mirrors
# the app's reading screen -- cream page, navy accents, centred column -- so
# the handoff reads as the same page finishing loading rather than a swap.
STYLE = """
:root { color-scheme: light dark; }
html, body { margin:0; padding:0; height:100%; }
#prerender {
  position:fixed; inset:0; overflow-y:auto; z-index:1000;
  background:#fffdf7; color:#1a1a1a;
  font:16px/1.7 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;
  transition:opacity 200ms ease-out;
  -webkit-overflow-scrolling:touch;
}
#prerender.is-done { opacity:0; pointer-events:none; }
#prerender .wrap { max-width:44rem; margin:0 auto; padding:1.25rem 1.25rem 5rem; }
#prerender .top {
  display:flex; align-items:center; gap:.6rem;
  border-bottom:1px solid #e8e3d8; padding-bottom:.9rem; margin-bottom:1.5rem;
}
#prerender .top b { font-size:.95rem; letter-spacing:.02em; color:#1b4571; }
#prerender h1 { font-size:1.45rem; line-height:1.3; margin:0 0 .3rem; }
#prerender .sub { color:#555; margin:0 0 1.6rem; font-size:.92rem; }
#prerender .verse { padding:.9rem 0; border-bottom:1px solid #efe9dd; }
#prerender .num { font-size:.75rem; color:#8a8a8a; letter-spacing:.04em; }
#prerender .ar {
  font-size:1.5rem; line-height:2.15; direction:rtl; text-align:right;
  margin:.5rem 0; font-family:"Traditional Arabic","Scheherazade New",serif;
}
#prerender .en { margin:.5rem 0; }
#prerender .ml { margin:.5rem 0; color:#333; }
#prerender .more { display:block; margin:1.8rem 0 0; font-size:.92rem; }
#prerender .loading {
  position:sticky; bottom:0; padding:.6rem 0;
  background:linear-gradient(to top,#fffdf7 65%,transparent);
  color:#777; font-size:.82rem; text-align:center;
}
@media (prefers-color-scheme: dark) {
  #prerender { background:#12181f; color:#e8e8e8; }
  #prerender .top { border-bottom-color:#2a323b; }
  #prerender .top b { color:#7fb2e5; }
  #prerender .verse { border-bottom-color:#222a33; }
  #prerender .sub, #prerender .num, #prerender .loading { color:#9aa4ae; }
  #prerender .ml { color:#ccc; }
  #prerender .loading { background:linear-gradient(to top,#12181f 65%,transparent); }
}
@media (prefers-reduced-motion: reduce) { #prerender { transition:none; } }
"""

# Removing the layer is tied to Flutter's own first-frame event, with a timeout
# so a failed boot cannot leave the reader stuck behind a static page forever.
HANDOFF = """
(function () {
  var el = document.getElementById('prerender');
  if (!el) return;
  var gone = false;
  function dismiss() {
    if (gone) return;
    gone = true;
    el.classList.add('is-done');
    setTimeout(function () {
      if (el.parentNode) el.parentNode.removeChild(el);
    }, 240);
  }
  window.addEventListener('flutter-first-frame', dismiss);
  setTimeout(dismiss, 20000);
})();
"""


def verse_blocks(number, arabic, english, malayalam, limit):
    rows = []
    for verse in range(1, limit + 1):
        ar = arabic.get(verse, '')
        en = clean_en(english.get(verse, ''))
        ml = clean_ml(malayalam.get(verse, ''))
        if not (ar or en or ml):
            continue
        block = ['<div class="verse">',
                 '<div class="num">%d:%d</div>' % (number, verse)]
        if ar:
            block.append('<p class="ar" lang="ar" dir="rtl">%s</p>' % esc(ar))
        if en:
            block.append('<p class="en">%s</p>' % en)
        if ml:
            block.append('<p class="ml" lang="ml">%s</p>' % ml)
        block.append('</div>')
        rows.append('\n'.join(block))
    return rows


def surah_page(meta, ml_meta, arabic, english, malayalam):
    number = meta['number']
    name = meta['name']
    translation = meta.get('translation') or ''
    ayahs = meta.get('ayath_count') or 0
    slug = '%d-%s' % (number, slugify(name))
    ml_name = (ml_meta.get('malayalam_name') or '').split('(')[0].strip()

    shown = min(PRERENDER_VERSES, ayahs)
    rows = verse_blocks(number, arabic, english, malayalam, shown)
    more = ''
    if ayahs > shown:
        more = ('<a class="more" href="%s/quran/%s/">'
                'Continue reading all %d verses →</a>'
                % (SITE, slug, ayahs))

    title = ("Surah %s (%s) — Muhammad Asad translation with Malayalam"
             % (name, translation))
    description = ("Surah %s, %s — %d verses with Muhammad Asad's English "
                   "translation from The Message of the Qur'an, the Malayalam "
                   "translation by K.C. Saleem and the Arabic text."
                   % (name, translation, ayahs))

    body = """<div class="wrap">
<div class="top"><b>THE MESSAGE OF THE QURAN</b></div>
<h1>Surah %s — %s</h1>
<p class="sub">%s · Surah %d of 114 · %d verses · %s</p>
%s
%s
<div class="loading">Loading the reader…</div>
</div>""" % (esc(name), esc(translation), esc(ml_name), number, ayahs,
             esc(meta.get('period') or ''), '\n'.join(rows), more)

    # The /quran/ page carries the complete surah, so it stays the canonical
    # copy: this one is the same text truncated, and should not compete with it.
    return """<!DOCTYPE html>
<html lang="en">
<head>
<base href="/">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>%s</title>
<meta name="description" content="%s">
<link rel="canonical" href="%s/quran/%s/">
<meta name="theme-color" content="#1B4571">
<link rel="icon" type="image/png" href="favicon.png"/>
<link rel="manifest" href="manifest.json">
<link rel="preload" as="script" href="main.dart.js">
<style>%s</style>
</head>
<body>
<div id="prerender">%s</div>
<script>%s</script>
<script src="flutter_bootstrap.js" async></script>
</body>
</html>
""" % (attr(title), attr(description), SITE, slug, STYLE, body, HANDOFF)


def home_markup():
    """The app's splash screen, as plain HTML.

    Mirrors SplashScreenLayout: the painted background, the ornament and
    author names at the top, the gold emblem over the wordmark, and the
    "Powered By D4DX" ellipse rising from the bottom. The artwork comes from
    web/splash (see tool/make_splash_assets.py).
    """
    return """<img class="bg" src="splash/bg.webp" alt="" fetchpriority="high" decoding="async">
<div class="shade"></div>
<img class="orn" src="splash/ornament.webp" alt="" decoding="async">
<div class="who"><b>MUHAMMAD ASAD</b><span>Leopold Weiss</span></div>
<div class="brand">
<img class="emblem" src="splash/emblem.webp" alt="" fetchpriority="high" decoding="async">
<img class="mark" src="splash/wordmark.webp" alt="The Message of the Quran" decoding="async">
</div>
<div class="foot"><div class="foot-in"><span>Powered By</span><img class="d4" src="splash/d4.webp" alt="D4DX" decoding="async"></div></div>"""


# The splash is always dark, whatever the colour scheme, exactly as in the
# app. Sizes follow the phone layout's proportions but are driven by viewport
# height so a desktop window gets the same composition rather than a phone
# layout stretched to 1920px. Poppins is the app's own English face; the files
# are the ones the Flutter bundle fetches anyway, so they cost nothing extra
# and swap in as soon as they arrive.
SPLASH_STYLE = """
@font-face { font-family:"Poppins"; font-weight:700; font-display:swap;
  src:url("assets/assets/google_fonts/Poppins-Bold.ttf") format("truetype"); }
@font-face { font-family:"Poppins"; font-weight:500; font-display:swap;
  src:url("assets/assets/google_fonts/Poppins-Medium.ttf") format("truetype"); }
@font-face { font-family:"Poppins"; font-weight:400; font-display:swap;
  src:url("assets/assets/google_fonts/Poppins-Regular.ttf") format("truetype"); }
html, body { margin:0; padding:0; height:100%; background:#194874; }
#prerender {
  position:fixed; inset:0; overflow:hidden; z-index:1000;
  background:#194874; color:#fff;
  font-family:"Poppins",-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;
  transition:opacity 220ms ease-out; will-change:opacity;
  -webkit-user-select:none; user-select:none;
}
#prerender.is-done { opacity:0; pointer-events:none; }
#prerender img { display:block; -webkit-user-drag:none; }
#prerender .bg {
  position:absolute; inset:0; width:100%; height:100%;
  object-fit:cover; object-position:center;
}
#prerender .shade {
  position:absolute; inset:0;
  background:linear-gradient(to bottom, rgba(0,0,0,.07) 0%, rgba(0,0,0,0) 42%, rgba(0,0,0,.48) 100%);
}
#prerender .orn {
  position:absolute; left:50%; top:0; transform:translate(-50%,-46%);
  width:clamp(86px, 24vw, 116px); opacity:.52;
}
#prerender .who {
  position:absolute; left:0; right:0; top:clamp(44px, 6.4vh, 60px);
  text-align:center; line-height:1.25;
}
#prerender .who b { display:block; font-weight:700; font-size:clamp(16px, 1.9vh, 19px); letter-spacing:.7px; }
#prerender .who span { display:block; font-weight:400; font-size:clamp(14px, 1.7vh, 17px); color:#D6D9E2; margin-top:.2em; letter-spacing:.15px; }
#prerender .brand {
  position:absolute; left:0; right:0; top:clamp(104px, 15vh, 150px); bottom:25vh;
  display:flex; flex-direction:column; align-items:center; justify-content:center;
}
#prerender .emblem { width:clamp(230px, min(84vw, 42vh), 400px); height:auto; }
#prerender .mark { width:clamp(200px, min(72vw, 36vh), 345px); height:auto; margin-top:calc(-1 * clamp(10px, 2.4vh, 22px)); }
#prerender .foot {
  position:absolute; left:50%; bottom:-24vh; transform:translateX(-50%);
  width:max(122vw, 620px); height:48vh; border-radius:50% 50% 0 0 / 100% 100% 0 0;
  background:linear-gradient(to bottom, rgba(14,31,73,.47), rgba(14,31,73,.63));
}
#prerender .foot-in {
  position:absolute; left:0; right:0; top:15%; text-align:center;
}
#prerender .foot-in span { display:block; font-weight:500; font-size:clamp(10px, 1.3vh, 12px); color:#E0E5F5; letter-spacing:.2px; }
#prerender .d4 {
  width:clamp(72px, 9vh, 86px); height:auto; margin:.35em auto 0;
  filter:brightness(0) invert(1) drop-shadow(0 0 9px rgba(255,255,255,.55));
}
@media (max-height: 560px) {
  #prerender .brand { top:96px; bottom:22vh; }
  #prerender .foot { height:44vh; bottom:-22vh; }
}
@media (prefers-reduced-motion: reduce) { #prerender { transition:none; } }
"""


def write_home():
    """Put the splash into the Flutter template's body."""
    s = io.open(INDEX, encoding='utf-8', newline='').read()
    marker_open = '<!-- prerender:start -->'
    marker_close = '<!-- prerender:end -->'
    block = ('%s\n<link rel="preload" as="image" href="splash/bg.webp">\n'
             '<link rel="preload" as="image" href="splash/emblem.webp">\n'
             '<style>%s</style>\n'
             '<div id="prerender" role="img" aria-label="The Message of the Quran is loading">%s</div>\n'
             '<script>%s</script>\n%s'
             % (marker_open, SPLASH_STYLE, home_markup(), HANDOFF,
                marker_close))

    if marker_open in s:
        start = s.index(marker_open)
        end = s.index(marker_close) + len(marker_close)
        s = s[:start] + block + s[end:]
    else:
        anchor = '  <script src="flutter_bootstrap.js" async></script>'
        if anchor not in s:
            raise SystemExit('index.html: bootstrap script tag not found')
        s = s.replace(anchor, block + '\n' + anchor, 1)
    io.open(INDEX, 'w', encoding='utf-8', newline='').write(s)
    print('splash written into %s' % INDEX)


def main():
    print('fetching surah list...')
    surahs = get('/surahs', {'malayalam': 'false'})
    ml_list = get('/surahs', {'malayalam': 'true'})
    ml_by_number = {m.get('chapter_number'): m for m in ml_list}
    if len(surahs) != 114:
        raise SystemExit('expected 114 surahs, got %d' % len(surahs))

    if os.path.isdir(OUT_ROOT):
        shutil.rmtree(OUT_ROOT)
    os.makedirs(OUT_ROOT)

    for meta in surahs:
        number = meta['number']
        arabic = {r['ayaid']: r.get('AyaHText', '')
                  for r in get('/surahs/%d/arabic' % number)}
        english = {r['verse_number']: r.get('text', '')
                   for r in get('/surahs/%d/verses' % number,
                                {'malayalam': 'false'})}
        malayalam = {r['verse_number']: r.get('malayalam_translation', '')
                     for r in get('/surahs/%d/verses' % number,
                                  {'malayalam': 'true'})}
        io.open(os.path.join(OUT_ROOT, '%d.html' % number), 'w',
                encoding='utf-8', newline='\n').write(
            surah_page(meta, ml_by_number.get(number, {}), arabic, english,
                       malayalam))
        sys.stdout.write('\r  %d/114' % number)
        sys.stdout.flush()
    print('\nwrote 114 surah pages into %s' % OUT_ROOT)

    write_home()


if __name__ == '__main__':
    main()
