"""Burç kartı arka planları (assets/zodiac/<burc>.webp) — element renkli takımyıldız.

Kullanım: python3 tool/gen_zodiac_art.py  (Pillow + numpy)
"""
import math, os, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 192
K = 3
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'zodiac')
os.makedirs(OUT, exist_ok=True)

ELEMENTS = {
    'fire': ((60, 14, 8), (150, 50, 20), (255, 150, 70)),
    'earth': ((8, 36, 22), (24, 90, 52), (140, 230, 150)),
    'air': ((8, 28, 64), (30, 90, 150), (150, 225, 255)),
    'water': ((14, 12, 70), (50, 40, 150), (170, 150, 255)),
}
SIGNS = {'koc': 'fire', 'boga': 'earth', 'ikizler': 'air', 'yengec': 'water', 'aslan': 'fire', 'basak': 'earth',
         'terazi': 'air', 'akrep': 'water', 'yay': 'fire', 'oglak': 'earth', 'kova': 'air', 'balik': 'water'}


def make(name, el, seed):
    top, bottom, accent = ELEMENTS[el]
    n = S * K
    yy, xx = np.mgrid[0:n, 0:n]
    t = (yy / n)[:, :, None]
    base = np.array(top, float) * (1 - t) + np.array(bottom, float) * t
    d = np.sqrt((xx - n * .5) ** 2 + (yy - n * .45) ** 2) / (n * .6)
    glow = (np.clip(1 - d, 0, 1) ** 2)[:, :, None] * np.array(accent, float) * 0.35
    im = Image.fromarray(np.clip(base + glow, 0, 255).astype('uint8'))
    r = random.Random(seed)
    layer = Image.new('RGB', (n, n), (0, 0, 0))
    ld = ImageDraw.Draw(layer)
    pts = [(r.uniform(.18, .82) * n, r.uniform(.2, .8) * n) for _ in range(r.randrange(5, 8))]
    for a, b in zip(pts, pts[1:]):
        ld.line([a, b], fill=accent, width=3)
    for x, y in pts:
        rad = r.choice([5, 7, 9]) * K / 2
        ld.ellipse((x - rad, y - rad, x + rad, y + rad), fill=(255, 255, 255))
    glowl = layer.filter(ImageFilter.GaussianBlur(6 * K / 2))
    a = np.asarray(im, float) / 255
    for L, k in ((glowl, 1.0), (layer, 0.9)):
        b = np.asarray(L, float) / 255 * k
        a = 1 - (1 - a) * (1 - b)
    im = Image.fromarray((a * 255).astype('uint8'))
    d = ImageDraw.Draw(im)
    for _ in range(26):
        x, y = r.randrange(n), r.randrange(n)
        d.ellipse((x - 1, y - 1, x + 1, y + 1), fill=(255, 255, 255))
    im = im.resize((S, S), Image.LANCZOS)
    p = os.path.join(OUT, name + '.webp')
    im.save(p, 'WEBP', quality=84, method=6)
    print(name, os.path.getsize(p) // 1024, 'KB')


if __name__ == '__main__':
    for i, (name, el) in enumerate(SIGNS.items()):
        make(name, el, 100 + i)
