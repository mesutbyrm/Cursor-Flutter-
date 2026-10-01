"""Üyelik kademesi illüstrasyonları (assets/membership/<tier>.webp).

Kullanım: python3 tool/gen_membership_art.py  (Pillow + numpy)
"""
import math, os, random
import numpy as np
from PIL import Image
import gen_game_art as g
from gen_game_art import Cv, W, H, K

OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'membership')
os.makedirs(OUT, exist_ok=True)
g.OUT = OUT


def shade(col, t):
    return tuple(max(0, min(255, int(v * t))) for v in col)


def crown(c, cx, cy, w, h, col, jewel=(255, 70, 110)):
    hw = w / 2
    base_y = cy + h / 2
    pts = [(cx - hw, base_y), (cx - hw, cy - h * .05), (cx - hw * .55, cy + h * .2), (cx - hw * .3, cy - h * .35),
           (cx, cy + h * .15), (cx + hw * .3, cy - h * .35), (cx + hw * .55, cy + h * .2), (cx + hw, cy - h * .05), (cx + hw, base_y)]
    c.poly(pts, fill=col + (255,), outline=shade(col, 1.25) + (255,))
    c.poly([(cx - hw, base_y), (cx + hw, base_y), (cx + hw * .96, base_y - h * .14), (cx - hw * .96, base_y - h * .14)], fill=shade(col, .78) + (255,))
    for px, py in ((cx - hw, cy - h * .05), (cx - hw * .3, cy - h * .35), (cx + hw * .3, cy - h * .35), (cx + hw, cy - h * .05), (cx, cy + h * .15)):
        c.ell([px - 9, py - 9, px + 9, py + 9], fill=(255, 255, 255, 255))
    for k, px in enumerate((cx - hw * .6, cx, cx + hw * .6)):
        py = base_y - h * .07
        c.poly([(px, py - 11), (px + 10, py), (px, py + 11), (px - 10, py)], fill=jewel + (255,))


def rays(c, cx, cy, n, r1, r2, col, alpha=70):
    for i in range(n):
        a = math.radians(i * 360 / n)
        w = math.radians(360 / n / 3)
        c.poly([(cx + r1 * math.cos(a - w), cy + r1 * math.sin(a - w)), (cx + r2 * math.cos(a), cy + r2 * math.sin(a)),
                (cx + r1 * math.cos(a + w), cy + r1 * math.sin(a + w))], fill=col + (alpha,))


def sparkle(c, x, y, s, col=(255, 255, 255)):
    c.poly([(x, y - s), (x + s * .22, y - s * .22), (x + s, y), (x + s * .22, y + s * .22), (x, y + s), (x - s * .22, y + s * .22), (x - s, y), (x - s * .22, y - s * .22)], fill=col + (255,))


def sparkles(c, seed, n=16, col=(255, 255, 255)):
    r = random.Random(seed)
    for _ in range(n):
        sparkle(c, r.randrange(40, W - 40), r.randrange(30, H - 30), r.choice([5, 7, 9, 12]), col)


def shield(c, cx, cy, w, h, col):
    pts = [(cx - w / 2, cy - h / 2), (cx + w / 2, cy - h / 2), (cx + w / 2, cy + h * .1), (cx, cy + h / 2), (cx - w / 2, cy + h * .1)]
    c.poly(pts, fill=col + (255,), outline=shade(col, 1.3) + (255,))
    pts2 = [(cx - w * .4, cy - h * .4), (cx + w * .4, cy - h * .4), (cx + w * .4, cy + h * .08), (cx, cy + h * .4), (cx - w * .4, cy + h * .08)]
    c.poly(pts2, fill=shade(col, .7) + (255,))


def star(c, cx, cy, r1, r2, col, n=5):
    pts = []
    for k in range(n * 2):
        a = math.pi / n * k - math.pi / 2
        rr = r1 if k % 2 == 0 else r2
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    c.poly(pts, fill=col + (255,))


def laurel(c, cx, cy, r, col):
    for side in (-1, 1):
        for i in range(9):
            a = math.radians(100 + i * 17) if side < 0 else math.radians(80 - i * 17)
            x, y = cx + r * math.cos(a), cy + r * math.sin(a)
            c.ell([x - 12, y - 6, x + 12, y + 6], fill=col + (230,))


def basic():
    c = Cv((14, 22, 40), (26, 44, 76), (120, 170, 230), 1)
    rays(c, 320, 200, 18, 110, 210, (150, 190, 255), 38)
    shield(c, 320, 200, 150, 180, (150, 170, 200))
    star(c, 320, 195, 46, 20, (235, 242, 255))
    sparkles(c, 1, 12, (200, 225, 255)); c.glow(0.35); c.save('basic')


def gold():
    c = Cv((50, 28, 6), (96, 58, 8), (255, 190, 60), 2)
    rays(c, 320, 210, 24, 120, 260, (255, 210, 90), 60)
    crown(c, 320, 205, 230, 150, (250, 190, 50))
    sparkles(c, 2, 20, (255, 235, 170)); c.glow(0.5); c.save('gold')


def premium():
    c = Cv((36, 10, 62), (80, 16, 110), (210, 90, 255), 3)
    rays(c, 320, 205, 20, 100, 230, (230, 130, 255), 50)
    # kanatlar
    for side in (-1, 1):
        for i in range(6):
            x0 = 320 + side * (70 + i * 5)
            ang = i * 7
            c.poly([(x0, 190 + i * 7), (x0 + side * (150 - i * 12), 130 + i * 14 + ang), (x0 + side * (120 - i * 10), 190 + i * 14 + ang)], fill=(235, 200, 255, 200 - i * 14))
    c.ell([250, 130, 390, 270], fill=(150, 40, 220, 255), outline=(240, 180, 255, 255), width=4)
    crown(c, 320, 200, 120, 80, (255, 215, 120), (120, 220, 255))
    sparkles(c, 3, 18, (245, 205, 255)); c.glow(0.5); c.save('premium')


def diamond():
    c = Cv((4, 26, 44), (8, 62, 92), (90, 230, 255), 4)
    rays(c, 320, 205, 22, 100, 240, (150, 240, 255), 48)
    cx, cy = 320, 210
    top = [(cx - 110, cy - 40), (cx - 60, cy - 100), (cx + 60, cy - 100), (cx + 110, cy - 40)]
    bottom = (cx, cy + 120)
    c.poly(top + [bottom], fill=(120, 220, 245, 255), outline=(230, 252, 255, 255))
    c.poly([top[0], top[1], (cx - 20, cy - 40)], fill=(190, 245, 255, 255))
    c.poly([top[1], top[2], (cx + 20, cy - 40), (cx - 20, cy - 40)], fill=(230, 252, 255, 255))
    c.poly([top[2], top[3], (cx + 20, cy - 40)], fill=(100, 200, 235, 255))
    c.poly([top[0], (cx - 20, cy - 40), bottom], fill=(80, 180, 220, 255))
    c.poly([(cx - 20, cy - 40), (cx + 20, cy - 40), bottom], fill=(160, 235, 250, 255))
    c.poly([(cx + 20, cy - 40), top[3], bottom], fill=(60, 150, 200, 255))
    sparkles(c, 4, 24, (220, 250, 255)); sparkle(c, cx - 50, cy - 70, 26); c.glow(0.55); c.save('diamond')


def svip():
    c = Cv((26, 4, 10), (70, 10, 24), (255, 80, 60), 5)
    rays(c, 320, 205, 28, 120, 270, (255, 190, 80), 56)
    laurel(c, 320, 215, 130, (210, 160, 60))
    crown(c, 320, 195, 200, 130, (255, 205, 80), (255, 70, 90))
    for x in (230, 320, 410):
        star(c, x, 330, 14, 6, (255, 215, 110))
    c.text((320, 355), 'SVIP', 30, (255, 215, 110))
    sparkles(c, 5, 22, (255, 225, 160)); c.glow(0.55); c.save('svip')


if __name__ == '__main__':
    for f in (basic, gold, premium, diamond, svip):
        f()
