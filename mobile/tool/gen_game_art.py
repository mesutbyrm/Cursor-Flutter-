"""Oyun kataloğu illüstrasyonları (assets/games/<id>.webp) — kodla çizilir.

Kullanım: python3 tool/gen_game_art.py  (Pillow + numpy)
Dosya adı katalog `GameCatalogItem.id` ile aynıdır (tire'li).
"""
import math, os, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H, K = 640, 400, 2
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'games')
BOLD = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
SYM = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
os.makedirs(OUT, exist_ok=True)


def mix(a, b, t):
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3))


class Cv:
    def __init__(self, top, bottom, accent, seed=1):
        t = np.linspace(0, 1, H * K)[:, None, None]
        arr = (np.array(top, float) * (1 - t) + np.array(bottom, float) * t) * np.ones((H * K, W * K, 3))
        self.im = Image.fromarray(arr.astype('uint8'), 'RGB')
        self.accent = accent
        yy, xx = np.mgrid[0:H * K, 0:W * K]
        d = np.sqrt((xx - W * K / 2) ** 2 + (yy - H * K * 0.46) ** 2) / (W * K * 0.5)
        k = np.clip(1 - d, 0, 1) ** 1.8
        glow = k[:, :, None] * np.array(accent, float)[None, None, :] * 0.5
        self.im = Image.fromarray(np.clip(np.asarray(self.im, float) + glow, 0, 255).astype('uint8'), 'RGB')
        self.d = ImageDraw.Draw(self.im, 'RGBA')
        r = random.Random(seed)
        for _ in range(60):
            x, y, s = r.randrange(W), r.randrange(H), r.choice([1, 1, 2])
            self.d.ellipse(((x - s / 2) * K, (y - s / 2) * K, (x + s / 2) * K, (y + s / 2) * K), fill=(255, 255, 255, r.randrange(40, 130)))

    def _p(self, v):
        return [c * K for c in v]

    def rr(self, box, r, fill=None, outline=None, width=2):
        self.d.rounded_rectangle(self._p(box), r * K, fill=fill, outline=outline, width=width * K)

    def ell(self, box, fill=None, outline=None, width=2):
        self.d.ellipse(self._p(box), fill=fill, outline=outline, width=width * K)

    def line(self, pts, fill, width=2):
        self.d.line(self._p(pts), fill=fill, width=width * K)

    def poly(self, pts, fill=None, outline=None):
        self.d.polygon([(x * K, y * K) for x, y in pts], fill=fill, outline=outline)

    def text(self, xy, s, size, fill=(255, 255, 255), font=BOLD, anchor='mm'):
        self.d.text((xy[0] * K, xy[1] * K), s, font=ImageFont.truetype(font, int(size * K)), fill=fill, anchor=anchor)

    def glow(self, strength=0.55, blur=10):
        g = self.im.filter(ImageFilter.GaussianBlur(blur * K))
        a = np.asarray(self.im, float) / 255
        b = np.asarray(g, float) / 255 * strength
        self.im = Image.fromarray((255 * (1 - (1 - a) * (1 - b))).astype('uint8'), 'RGB')
        self.d = ImageDraw.Draw(self.im, 'RGBA')

    def save(self, name):
        im = self.im.resize((W, H), Image.LANCZOS)
        yy, xx = np.mgrid[0:H, 0:W]
        d = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - H / 2) / (H / 2)) ** 2)
        k = 1 - 0.5 * np.clip(d - 0.5, 0, 1) ** 1.5
        im = Image.fromarray(np.clip(np.asarray(im, float) * k[:, :, None], 0, 255).astype('uint8'))
        p = os.path.join(OUT, name + '.webp')
        im.save(p, 'WEBP', quality=82, method=6)
        print(name, os.path.getsize(p) // 1024, 'KB')


PINK, CYAN, GOLD, GREEN, RED, BLUE, VIOLET, ORANGE = (255, 80, 150), (60, 220, 255), (255, 205, 90), (70, 220, 130), (255, 80, 80), (80, 140, 255), (160, 110, 255), (255, 150, 60)
WHITE = (245, 245, 255)


def grid(c, x0, y0, n, cell, col=(255, 255, 255, 90), w=2, m=None):
    m = m or n
    for i in range(n + 1):
        c.line([x0, y0 + i * cell, x0 + m * cell, y0 + i * cell], col, w)
    for j in range(m + 1):
        c.line([x0 + j * cell, y0, x0 + j * cell, y0 + n * cell], col, w)


def xmark(c, cx, cy, r, col, w=9):
    c.line([cx - r, cy - r, cx + r, cy + r], col, w)
    c.line([cx - r, cy + r, cx + r, cy - r], col, w)


def tile(c, x, y, w, h, label, col, bg=(250, 244, 230), size=34):
    c.rr([x + 3, y + 5, x + w + 3, y + h + 5], 8, fill=(0, 0, 0, 90))
    c.rr([x, y, x + w, y + h], 8, fill=bg + (255,), outline=(190, 170, 130), width=2)
    c.text((x + w / 2, y + h / 2), label, size, fill=col)


def die(c, x, y, s, n, rot=0):
    c.rr([x + 4, y + 6, x + s + 4, y + s + 6], 14, fill=(0, 0, 0, 100))
    c.rr([x, y, x + s, y + s], 14, fill=(250, 250, 255, 255), outline=(180, 180, 210), width=2)
    pos = {1: [(.5, .5)], 2: [(.28, .28), (.72, .72)], 3: [(.28, .28), (.5, .5), (.72, .72)],
           4: [(.28, .28), (.72, .28), (.28, .72), (.72, .72)],
           5: [(.28, .28), (.72, .28), (.5, .5), (.28, .72), (.72, .72)],
           6: [(.28, .25), (.72, .25), (.28, .5), (.72, .5), (.28, .75), (.72, .75)]}[n]
    for px, py in pos:
        r = s * 0.075
        c.ell([x + px * s - r, y + py * s - r, x + px * s + r, y + py * s + r], fill=(30, 20, 50, 255))


def card(c, x, y, w, h, rank, suit, col, ang=0):
    layer = Image.new('RGBA', (int(w * K) + 40, int(h * K) + 40), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    ld.rounded_rectangle((20, 20, 20 + w * K, 20 + h * K), 14 * K // 2, fill=(252, 252, 255, 255), outline=(170, 170, 200), width=3)
    f = ImageFont.truetype(BOLD, int(26 * K)); g = ImageFont.truetype(SYM, int(52 * K))
    ld.text((20 + 14 * K, 20 + 10 * K), rank, font=f, fill=col)
    ld.text((20 + w * K / 2, 20 + h * K / 2 + 6 * K), suit, font=g, fill=col, anchor='mm')
    layer = layer.rotate(ang, expand=True, resample=Image.BICUBIC)
    c.im.paste(layer, (int(x * K - layer.width / 2), int(y * K - layer.height / 2)), layer)
    c.d = ImageDraw.Draw(c.im, 'RGBA')


def stone(c, cx, cy, r, col, hl=True):
    c.ell([cx - r + 2, cy - r + 4, cx + r + 2, cy + r + 4], fill=(0, 0, 0, 90))
    c.ell([cx - r, cy - r, cx + r, cy + r], fill=col + (255,))
    if hl:
        c.ell([cx - r * .55, cy - r * .6, cx - r * .05, cy - r * .1], fill=(255, 255, 255, 70))


# ───────────── çok oyunculu ─────────────
def g_xox():
    c = Cv((20, 12, 52), (40, 16, 80), VIOLET, 1)
    grid(c, 220, 70, 3, 66, (180, 150, 255, 255), 4)
    xmark(c, 253, 103, 18, PINK + (255,)); xmark(c, 385, 169, 18, PINK + (255,)); xmark(c, 253, 235, 18, PINK + (255,))
    for cx, cy in ((319, 103), (319, 169), (385, 235)):
        c.ell([cx - 20, cy - 20, cx + 20, cy + 20], outline=CYAN + (255,), width=8)
    c.glow(); c.save('xox')

def g_sos():
    c = Cv((8, 28, 52), (14, 50, 84), CYAN, 2)
    grid(c, 210, 60, 4, 55, (120, 210, 255, 200), 3)
    letters = 'SOSOSSOSOSOSSOSO'
    for i, ch in enumerate(letters):
        c.text((210 + (i % 4) * 55 + 27, 60 + (i // 4) * 55 + 27), ch, 30, PINK if ch == 'S' else GOLD)
    c.line([237, 87, 237, 252], (255, 255, 255, 255), 5)
    c.glow(); c.save('sos')

def g_tombala():
    c = Cv((60, 12, 40), (96, 20, 60), PINK, 3)
    c.rr([140, 90, 500, 290], 16, fill=(255, 245, 235, 255), outline=GOLD + (255,), width=4)
    nums = [(5, 0), (22, 2), (41, 4), (63, 6), (88, 8), (13, 1), (36, 3), (57, 5), (74, 7), (90, 9), (8, 0), (29, 2), (48, 4), (66, 6), (81, 8)]
    for i, (n, _) in enumerate(nums):
        x, y = 150 + (i % 5) * 70, 100 + (i // 5) * 62
        hit = i in (1, 4, 7, 8, 12)
        c.rr([x + 4, y + 4, x + 62, y + 54], 8, fill=(PINK + (255,)) if hit else (255, 232, 214, 255))
        c.text((x + 33, y + 29), str(n), 26, WHITE if hit else (110, 40, 70))
    for (bx, by, n, col) in ((90, 330, 17, BLUE), (160, 345, 54, GREEN), (480, 335, 32, ORANGE), (550, 320, 71, VIOLET)):
        stone(c, bx, by, 26, col); c.text((bx, by), str(n), 20)
    c.glow(0.4); c.save('tombala')

def g_tavla():
    c = Cv((38, 20, 10), (70, 38, 18), ORANGE, 4)
    c.rr([70, 50, 570, 350], 14, fill=(96, 58, 30, 255), outline=(190, 130, 70), width=4)
    for i in range(12):
        x = 86 + i * 39
        col = (235, 205, 150, 255) if i % 2 == 0 else (150, 60, 40, 255)
        c.poly([(x, 62), (x + 36, 62), (x + 18, 180)], fill=col)
        c.poly([(x, 338), (x + 36, 338), (x + 18, 220)], fill=col if i % 2 else (235, 205, 150, 255))
    for i in range(4):
        stone(c, 104 + 0, 90 + i * 30, 15, (250, 245, 235)); stone(c, 470 - 39 * 0, 310 - i * 30, 15, (40, 30, 30))
    die(c, 250, 160, 46, 5); die(c, 320, 170, 46, 3)
    c.glow(0.35); c.save('tavla')

def g_pisti():
    c = Cv((8, 40, 60), (10, 70, 96), CYAN, 5)
    card(c, 250, 205, 110, 160, 'A', '♠', (30, 30, 50), -18)
    card(c, 320, 195, 110, 160, 'K', '♥', RED, 0)
    card(c, 390, 205, 110, 160, 'Q', '♦', RED, 18)
    c.glow(0.35); c.save('pisti')

def g_sayi_tahmin():
    c = Cv((16, 18, 60), (30, 24, 100), BLUE, 6)
    for i, (ch, col) in enumerate((('7', GOLD), ('3', CYAN), ('?', PINK))):
        x = 150 + i * 120
        c.rr([x, 110, x + 100, 250], 18, fill=(255, 255, 255, 30), outline=col + (255,), width=4)
        c.text((x + 50, 180), ch, 84, col)
    c.text((320, 310), '↑  ↓', 36, (200, 200, 255), font=SYM)
    c.glow(); c.save('sayi-tahmin')

def g_zar():
    c = Cv((50, 10, 20), (90, 16, 34), RED, 7)
    die(c, 190, 120, 130, 6); die(c, 340, 150, 130, 4)
    c.glow(0.4); c.save('zar')

def _tiles(c, label=None):
    cols = [RED, BLUE, (30, 30, 40), (230, 150, 20)]
    xs = 70
    for i in range(8):
        tile(c, xs + i * 60, 200, 52, 76, str((i * 3) % 13 + 1), cols[i % 4])
    tile(c, 150, 110, 52, 76, '5', RED); tile(c, 210, 110, 52, 76, '6', RED); tile(c, 270, 110, 52, 76, '7', RED)
    if label:
        c.text((460, 140), label, 70, GOLD)

def g_okey():
    c = Cv((8, 52, 36), (10, 84, 56), GREEN, 8)
    _tiles(c); c.glow(0.3); c.save('okey')

def g_okey101():
    c = Cv((8, 40, 44), (10, 70, 76), GREEN, 9)
    _tiles(c, '101'); c.glow(0.3); c.save('okey101')

def g_connect4():
    c = Cv((14, 20, 70), (20, 36, 120), BLUE, 10)
    c.rr([150, 50, 490, 350], 18, fill=(40, 80, 220, 255), outline=(120, 160, 255), width=3)
    pat = ['.......', '.......', '...R...', '..YR...', '..YYR..', '.RRYYR.']
    for r in range(6):
        for q in range(7):
            x, y = 178 + q * 47, 82 + r * 46
            ch = pat[r][q]
            col = {'R': (240, 60, 70), 'Y': (255, 215, 60), '.': (14, 20, 60)}[ch]
            c.ell([x - 18, y - 18, x + 18, y + 18], fill=col + (255,))
    c.glow(0.3); c.save('connect4')

def g_reversi():
    c = Cv((6, 40, 30), (8, 70, 50), GREEN, 11)
    c.rr([160, 50, 480, 350], 10, fill=(20, 120, 70, 255), outline=(120, 220, 160), width=3)
    grid(c, 176, 66, 6, 48, (10, 70, 40, 255), 2)
    cells = {(2, 2): 'w', (2, 3): 'b', (3, 2): 'b', (3, 3): 'w', (1, 3): 'w', (4, 3): 'b', (3, 4): 'w', (2, 4): 'b'}
    for (r, q), v in cells.items():
        stone(c, 176 + q * 48 + 24, 66 + r * 48 + 24, 19, (245, 245, 250) if v == 'w' else (25, 25, 32))
    c.glow(0.25); c.save('reversi')

def g_dama():
    c = Cv((40, 24, 14), (70, 40, 20), ORANGE, 12)
    for r in range(8):
        for q in range(8):
            col = (232, 200, 150, 255) if (r + q) % 2 == 0 else (130, 76, 40, 255)
            c.rr([180 + q * 35, 60 + r * 35, 215 + q * 35, 95 + r * 35], 0, fill=col)
    for i, (r, q, light) in enumerate(((1, 1, 1), (1, 3, 1), (2, 2, 1), (5, 4, 0), (6, 2, 0), (6, 6, 0), (4, 5, 1), (3, 4, 0))):
        stone(c, 180 + q * 35 + 17, 60 + r * 35 + 17, 13, (250, 240, 220) if light else (50, 30, 24))
    c.glow(0.25); c.save('dama')

def g_mangala():
    c = Cv((50, 28, 12), (86, 50, 22), GOLD, 13)
    c.rr([50, 120, 590, 290], 70, fill=(130, 80, 36, 255), outline=(220, 170, 90), width=4)
    r = random.Random(3)
    for row in (160, 250):
        for i in range(6):
            x = 130 + i * 74
            c.ell([x - 28, row - 28, x + 28, row + 28], fill=(70, 40, 18, 255))
            for _ in range(r.randrange(2, 5)):
                stone(c, x + r.randrange(-12, 12), row + r.randrange(-12, 12), 6, r.choice([PINK, CYAN, GOLD, GREEN]), False)
    for x in (80, 560):
        c.ell([x - 26, 160, x + 26, 260], fill=(70, 40, 18, 255))
    c.glow(0.35); c.save('mangala')

def g_gomoku():
    c = Cv((52, 36, 14), (92, 66, 26), GOLD, 14)
    c.rr([170, 40, 470, 360], 8, fill=(222, 178, 100, 255), outline=(150, 100, 40), width=3)
    grid(c, 190, 60, 8, 34, (110, 70, 30, 255), 2)
    pts = [(2, 2, 0), (3, 3, 1), (3, 4, 0), (4, 4, 1), (4, 5, 0), (5, 5, 1), (2, 5, 0), (6, 6, 1), (5, 2, 0), (1, 1, 1)]
    for r, q, b in pts:
        stone(c, 190 + q * 34, 60 + r * 34, 13, (30, 30, 36) if b else (250, 250, 252))
    c.line([190 + 3 * 34, 60 + 3 * 34, 190 + 6 * 34, 60 + 6 * 34], RED + (255,), 4)
    c.glow(0.2); c.save('gomoku')

def g_amiral():
    c = Cv((4, 30, 60), (8, 60, 110), CYAN, 15)
    grid(c, 130, 50, 8, 40, (120, 210, 255, 90), 2, 10)
    c.poly([(170, 130), (330, 130), (350, 150), (330, 170), (170, 170)], fill=(120, 150, 170, 255), outline=(220, 240, 255, 255))
    c.poly([(210, 250), (330, 250), (350, 270), (330, 290), (210, 290)], fill=(120, 150, 170, 255), outline=(220, 240, 255, 255))
    for r in (40, 80, 120):
        c.ell([470 - r, 150 - r, 470 + r, 150 + r], outline=CYAN + (180,), width=2)
    c.ell([462, 142, 478, 158], fill=GREEN + (255,)); c.line([470, 150, 560, 100], GREEN + (255,), 3)
    c.ell([240, 200, 262, 222], fill=RED + (255,)); xmark(c, 380, 220, 12, RED + (255,), 5)
    c.glow(0.4); c.save('amiral-batti')

def g_kelime():
    c = Cv((50, 16, 70), (90, 24, 120), VIOLET, 16)
    for i, ch in enumerate('KELİME'):
        tile(c, 110 + i * 70, 110, 62, 80, ch, (70, 30, 120))
    c.text((320, 260), 'VS', 54, GOLD)
    for i, ch in enumerate('ABC'):
        tile(c, 250 + i * 50, 300, 42, 54, ch, (120, 60, 170), size=26)
    c.glow(0.35); c.save('kelime-duellosu')

def _qmark(c, vs=False):
    c.ell([230, 40, 410, 220], fill=(255, 255, 255, 25), outline=GOLD + (255,), width=5)
    c.text((320, 135), '?', 150, GOLD)
    if vs:
        for x, col in ((150, PINK), (490, CYAN)):
            c.ell([x - 46, 270, x + 46, 362], fill=col + (255,)); c.text((x, 316), '👤' if False else 'P', 46)
        c.text((320, 316), 'VS', 46)

def g_quiz1v1():
    c = Cv((30, 14, 80), (60, 20, 130), VIOLET, 17); _qmark(c, True); c.glow(0.4); c.save('quiz-1v1')

def g_quiz():
    c = Cv((20, 20, 80), (40, 30, 130), BLUE, 18); _qmark(c); 
    for i, col in enumerate((PINK, CYAN, GOLD, GREEN)):
        c.rr([130 + i * 95, 290, 215 + i * 95, 340], 14, fill=col + (255,)); c.text((172 + i * 95, 315), 'ABCD'[i], 30)
    c.glow(0.4); c.save('quiz')

def g_memory_pvp():
    c = Cv((14, 30, 70), (22, 50, 110), CYAN, 19)
    for i in range(6):
        x, y = 150 + (i % 3) * 120, 80 + (i // 3) * 140
        up = i in (1, 4)
        c.rr([x, y, x + 100, y + 120], 14, fill=(250, 250, 255, 255) if up else (60, 50, 150, 255), outline=GOLD + (255,), width=3)
        c.text((x + 50, y + 60), '★' if up else '?', 54, PINK if up else GOLD, font=SYM if up else BOLD)
    c.glow(0.35); c.save('kart-eslestirme-pvp'); c.save('memory-match')

def g_tkm():
    c = Cv((40, 16, 56), (76, 24, 90), PINK, 20)
    stone(c, 170, 200, 62, (150, 150, 165))
    c.rr([270, 130, 370, 270], 10, fill=(250, 250, 255, 255), outline=(180, 180, 210), width=3)
    for i in range(3):
        c.line([285, 160 + i * 30, 355, 160 + i * 30], (160, 160, 200, 255), 3)
    c.line([470, 270, 520, 150], RED + (255,), 12); c.line([570, 270, 520, 150], RED + (255,), 12)
    c.ell([450, 270, 490, 310], outline=RED + (255,), width=7); c.ell([550, 270, 590, 310], outline=RED + (255,), width=7)
    c.glow(0.35); c.save('tas-kagit-makas')

# ───────────── mini ─────────────
def g_2048():
    c = Cv((60, 40, 20), (100, 70, 30), ORANGE, 21)
    c.rr([150, 40, 490, 360], 18, fill=(150, 130, 110, 255))
    vals = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4, 2, 8, 2, 4]
    pal = {2: (238, 228, 218), 4: (237, 224, 200), 8: (242, 177, 121), 16: (245, 149, 99), 32: (246, 124, 95), 64: (246, 94, 59), 128: (237, 207, 114), 256: (237, 204, 97), 512: (237, 200, 80), 1024: (237, 197, 63), 2048: (255, 215, 0)}
    for i, v in enumerate(vals):
        x, y = 162 + (i % 4) * 82, 52 + (i // 4) * 76
        c.rr([x, y, x + 74, y + 68], 8, fill=pal[v] + (255,))
        c.text((x + 37, y + 34), str(v), 26 if v < 100 else 20, (110, 100, 90) if v < 8 else WHITE)
    c.glow(0.25); c.save('2048')

def g_anagram():
    c = Cv((30, 20, 80), (54, 30, 120), VIOLET, 22)
    for i, ch in enumerate('GRMANA'):
        tile(c, 100 + i * 72, 140 + (i % 2) * 30, 62, 80, ch, (70, 30, 140))
    c.text((320, 320), '→  ANAGRAM', 36, GOLD)
    c.glow(0.3); c.save('anagram')

def g_wheel():
    c = Cv((50, 10, 60), (90, 14, 110), PINK, 23)
    cx, cy, R = 320, 205, 150
    cols = [PINK, GOLD, CYAN, GREEN, VIOLET, ORANGE, BLUE, RED]
    for i in range(8):
        a0, a1 = i * 45 - 90, (i + 1) * 45 - 90
        c.d.pieslice(((cx - R) * K, (cy - R) * K, (cx + R) * K, (cy + R) * K), a0, a1, fill=cols[i] + (255,), outline=(255, 255, 255, 255), width=3)
    c.ell([cx - 30, cy - 30, cx + 30, cy + 30], fill=(255, 255, 255, 255), outline=GOLD + (255,), width=5)
    c.poly([(cx - 16, 36), (cx + 16, 36), (cx, 76)], fill=(255, 255, 255, 255))
    c.glow(0.4); c.save('carkifelek')

def g_color_sort():
    c = Cv((20, 24, 70), (30, 40, 110), CYAN, 24)
    cols = [PINK, CYAN, GOLD, GREEN, VIOLET]
    for t in range(5):
        x = 120 + t * 92
        c.rr([x, 70, x + 56, 330], 26, fill=(255, 255, 255, 30), outline=(255, 255, 255, 190), width=3)
        for l in range(4 if t < 4 else 2):
            c.rr([x + 5, 300 - l * 56 - 46 + 46, x + 51, 300 - l * 56 + 46 - 46 + 0], 14, fill=cols[(t + l * 2) % 5] + (255,)) if False else c.rr([x + 5, 280 - l * 52, x + 51, 328 - l * 52 + 0], 12, fill=cols[(t + l * 2) % 5] + (255,))
    c.glow(0.3); c.save('color-sort')

def g_hangman():
    c = Cv((18, 24, 50), (30, 40, 80), BLUE, 25)
    for l in ([180, 330, 320, 330], [220, 330, 220, 60], [220, 60, 330, 60], [330, 60, 330, 90]):
        c.line(l, (210, 180, 130, 255), 8)
    c.ell([310, 90, 350, 130], outline=WHITE + (255,), width=5)
    c.line([330, 130, 330, 210], WHITE + (255,), 5); c.line([330, 150, 300, 185], WHITE + (255,), 5); c.line([330, 150, 360, 185], WHITE + (255,), 5)
    for i in range(6):
        c.line([400 + i * 38, 250, 428 + i * 38, 250], GOLD + (255,), 5)
    c.text((419, 232), 'A', 36, WHITE); c.text((533, 232), 'M', 36, WHITE)
    c.glow(0.3); c.save('hangman')

def g_logo():
    c = Cv((40, 16, 70), (70, 24, 110), PINK, 26)
    for i, col in enumerate((PINK, CYAN, GOLD)):
        x = 150 + i * 140
        c.ell([x, 110, x + 110, 220], fill=col + (255,)); c.text((x + 55, 165), '?', 64)
    c.rr([160, 270, 480, 330], 20, fill=(255, 255, 255, 40), outline=GOLD + (255,), width=3); c.text((320, 300), 'LOGO QUIZ', 34, GOLD)
    c.glow(0.35); c.save('logo-quiz')

def g_mastermind():
    c = Cv((26, 22, 60), (44, 34, 100), VIOLET, 27)
    cols = [RED, BLUE, GREEN, GOLD, PINK, CYAN]
    r = random.Random(5)
    for row in range(5):
        for q in range(4):
            stone(c, 180 + q * 56, 80 + row * 58, 20, r.choice(cols))
        for q in range(4):
            c.ell([430 + (q % 2) * 22, 70 + row * 58 + (q // 2) * 22, 444 + (q % 2) * 22, 84 + row * 58 + (q // 2) * 22], fill=(WHITE if (q + row) % 3 else RED) + (255,))
    c.glow(0.3); c.save('mastermind')

def g_minesweeper():
    c = Cv((24, 30, 48), (40, 48, 76), CYAN, 28)
    numc = {1: BLUE, 2: GREEN, 3: RED}
    lay = ['11 1B', '1B21 ', '12B1 ', ' 1111']
    for r in range(4):
        for q in range(5):
            x, y = 150 + q * 70, 70 + r * 70
            ch = lay[r][q] if q < len(lay[r]) else ' '
            c.rr([x, y, x + 64, y + 64], 8, fill=(190, 200, 215, 255) if ch != 'B' else (200, 90, 90, 255))
            if ch.isdigit():
                c.text((x + 32, y + 32), ch, 36, numc[int(ch)])
            if ch == 'B':
                c.ell([x + 18, y + 18, x + 46, y + 46], fill=(20, 20, 30, 255))
    c.glow(0.2); c.save('minesweeper')

def g_scratch():
    c = Cv((50, 38, 8), (96, 70, 14), GOLD, 29)
    c.rr([140, 70, 500, 330], 22, fill=(230, 190, 70, 255), outline=(255, 235, 150), width=4)
    c.rr([170, 130, 470, 290], 14, fill=(170, 170, 180, 255))
    c.rr([170, 130, 330, 200], 14, fill=(255, 245, 190, 255))
    c.text((250, 165), '★ 500', 38, (170, 90, 10)); c.text((320, 100), 'KAZI KAZAN', 30, (120, 70, 10))
    c.line([340, 250, 420, 190], (210, 210, 220, 255), 14)
    c.glow(0.4); c.save('scratch')

def g_slot():
    c = Cv((60, 10, 30), (110, 16, 50), RED, 30)
    c.rr([110, 80, 530, 320], 24, fill=(30, 20, 40, 255), outline=GOLD + (255,), width=6)
    for i, ch in enumerate(('7', '7', '7')):
        x = 130 + i * 134
        c.rr([x, 110, x + 118, 290], 14, fill=(255, 250, 240, 255)); c.text((x + 59, 200), ch, 120, RED)
    c.glow(0.45); c.save('slot')

def g_sudoku():
    c = Cv((14, 28, 60), (24, 48, 100), BLUE, 31)
    c.rr([190, 40, 450, 360], 10, fill=(250, 250, 255, 255))
    for i in range(10):
        w = 4 if i % 3 == 0 else 1
        c.line([200, 50 + i * 34.4, 440, 50 + i * 34.4], (40, 50, 100, 255), w)
        c.line([200 + i * 26.6, 50, 200 + i * 26.6, 360 - 0], (40, 50, 100, 255), w)
    r = random.Random(2)
    for _ in range(22):
        q, rr_ = r.randrange(9), r.randrange(9)
        c.text((200 + q * 26.6 + 13, 50 + rr_ * 34.4 + 17), str(r.randrange(1, 10)), 18, (30, 60, 160))
    c.glow(0.2); c.save('sudoku')

def g_wordhunt():
    c = Cv((8, 44, 50), (12, 76, 84), CYAN, 32)
    letters = 'KELIMEAVIOKUTARNSLBAYIZMODAL'
    r = random.Random(7)
    for rr_ in range(5):
        for q in range(8):
            ch = r.choice('AEIKLMNORSTUYZ')
            hit = rr_ == 2 and 1 <= q <= 6
            if hit:
                ch = 'KELIME'[q - 1]
            x, y = 130 + q * 49, 60 + rr_ * 62
            if hit:
                c.rr([x, y, x + 44, y + 52], 10, fill=GOLD + (255,))
            c.text((x + 22, y + 26), ch, 32, (60, 30, 0) if hit else (190, 240, 245))
    c.glow(0.3); c.save('word-hunt')

def g_wordpuzzle():
    c = Cv((30, 18, 70), (54, 30, 110), VIOLET, 33)
    words = [(0, 1, 'KELIME'), (2, 0, 'OYUN'), (4, 2, 'FAL'), (1, 4, 'AŞK')]
    cell = 46
    for r, q, w in words:
        for i, ch in enumerate(w):
            x, y = 110 + (q + i) * cell, 70 + r * 56 if False else 70 + r * 52
            c.rr([x, y, x + cell - 4, y + 46], 8, fill=(255, 250, 235, 255)); c.text((x + 21, y + 23), ch, 26, (70, 30, 140))
    c.glow(0.3); c.save('word-puzzle')


ALL = [g_xox, g_sos, g_tombala, g_tavla, g_pisti, g_sayi_tahmin, g_zar, g_okey, g_okey101, g_connect4, g_reversi, g_dama,
       g_mangala, g_gomoku, g_amiral, g_kelime, g_quiz1v1, g_quiz, g_memory_pvp, g_tkm, g_2048, g_anagram, g_wheel,
       g_color_sort, g_hangman, g_logo, g_mastermind, g_minesweeper, g_scratch, g_slot, g_sudoku, g_wordhunt, g_wordpuzzle]

if __name__ == '__main__':
    for f in ALL:
        f()
