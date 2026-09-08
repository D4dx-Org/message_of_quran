"""
make_splash_assets.py

Builds web/splash/*.webp, the artwork behind the loading screen that
tool/generate_app_pages.py writes into web/index.html.

The Flutter bundle's own copies of these images are sized for the phone
splash (the emblem is 165px wide) and look soft on a desktop display, so the
web splash takes them from the app repo's full-resolution sources instead:

    python tool/make_splash_assets.py ../message_of_quran/assets/images

The ornament is tinted here rather than at render time because the app tints
it with a blend mode that plain <img> cannot reproduce.
"""
import os
import sys

from PIL import Image

OUT = os.path.join('web', 'splash')
ORNAMENT_TINT = (0x2D, 0x6E, 0x98)  # SplashLayoutMetrics.ornamentTint


def save(im, name, quality, max_width=None):
    if max_width and im.width > max_width:
        im = im.resize((max_width, round(im.height * max_width / im.width)),
                       Image.LANCZOS)
    path = os.path.join(OUT, name)
    im.save(path, 'WEBP', quality=quality, method=6)
    print('%-14s %5dx%-5d %7d bytes' % (name, im.width, im.height,
                                        os.path.getsize(path)))


def tinted(im, rgb):
    alpha = im.convert('RGBA').getchannel('A')
    flat = Image.new('RGBA', im.size, rgb + (255,))
    flat.putalpha(alpha)
    return flat


def main(src):
    os.makedirs(OUT, exist_ok=True)
    # Emblem and wordmark keep their full 1254px so a 2x desktop stays crisp.
    save(Image.open(os.path.join(src, 'splash_logo.png')).convert('RGBA'),
         'emblem.webp', 92)
    save(Image.open(os.path.join(src, 'splash_text_logo.png')).convert('RGBA'),
         'wordmark.webp', 92)
    save(Image.open(os.path.join(src, 'splash_bg.png')).convert('RGB'),
         'bg.webp', 82)
    save(Image.open(os.path.join(src, 'd4_logo.png')).convert('RGBA'),
         'd4.webp', 90, max_width=400)
    save(tinted(Image.open(os.path.join('assets', 'images',
                                        'home_side_image.webp')),
                ORNAMENT_TINT),
         'ornament.webp', 90)


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    main(sys.argv[1])
