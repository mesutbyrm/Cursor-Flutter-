"""Fal vitrin illüstrasyonları (assets/fortune/*.webp) — kodla çizilir.

Kullanım: python3 tool/gen_fortune_art.py  (Pillow + numpy gerekir)
Üretilen: aura-analizi, dogum-haritasi, gunluk-fal, kursundokme, istihare
"""
import math, random, os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1536, 1024
SS = 1  # çizim doğrudan hedef boyutta; parlama için blur kullanılır
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'fortune')
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'


def rng(seed):
    r = random.Random(seed)
    return r


def base(top, bottom, seed, stars=420):
    """Dikey degrade + yıldız tozu."""
    t = np.linspace(0, 1, H)[:, None, None]
    top = np.array(top, float)[None, None, :]
    bottom = np.array(bottom, float)[None, None, :]
    arr = (top * (1 - t) + bottom * t) * np.ones((H, W, 3))
    im = Image.fromarray(arr.astype('uint8'), 'RGB')
    d = ImageDraw.Draw(im, 'RGBA')
    r = rng(seed)
    for _ in range(stars):
        x, y = r.randrange(W), r.randrange(H)
        s = r.choice([1, 1, 1, 2, 2, 3])
        a = r.randrange(70, 230)
        d.ellipse((x - s, y - s, x + s, y + s), fill=(255, 255, 255, a))
    return im


def screen(a, b):
    """Ekran (screen) harmanı — parlama katmanları için."""
    A = np.asarray(a, float) / 255
    B = np.asarray(b, float) / 255
    return Image.fromarray((255 * (1 - (1 - A) * (1 - B))).astype('uint8'), 'RGB')


def glow_layer(draw_fn, blur, strength=1.0):
    layer = Image.new('RGB', (W, H), (0, 0, 0))
    d = ImageDraw.Draw(layer)
    draw_fn(d)
    g = layer.filter(ImageFilter.GaussianBlur(blur))
    if strength != 1.0:
        g = Image.fromarray(np.clip(np.asarray(g, float) * strength, 0, 255).astype('uint8'))
    return g


def radial(cx, cy, r, color, power=2.0):
    yy, xx = np.mgrid[0:H, 0:W]
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / r
    k = np.clip(1 - d, 0, 1) ** power
    arr = k[:, :, None] * np.array(color, float)[None, None, :]
    return Image.fromarray(np.clip(arr, 0, 255).astype('uint8'), 'RGB')


def vignette(im, amount=0.55):
    yy, xx = np.mgrid[0:H, 0:W]
    d = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - H / 2) / (H / 2)) ** 2)
    k = 1 - amount * np.clip(d - 0.35, 0, 1) ** 1.6
    arr = np.asarray(im, float) * k[:, :, None]
    return Image.fromarray(np.clip(arr, 0, 255).astype('uint8'), 'RGB')


def save(im, name):
    im = vignette(im)
    path = os.path.join(OUT, name)
    im.save(path, 'WEBP', quality=86, method=6)
    print(name, os.path.getsize(path) // 1024, 'KB')


def ring(d, cx, cy, r, color, width=2):
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=color, width=width)


GOLD = (255, 205, 110)
# ───────────────────────── Doğum haritası ─────────────────────────

def natal():
    im = base((10, 8, 38), (24, 14, 62), 7)
    cx, cy = W // 2, H // 2
    im = screen(im, radial(cx, cy, 560, (60, 40, 130), 1.6))
    sym = '♈♉♊♋♌♍♎♏♐♑♒♓'
    colors = [(255, 120, 90), (130, 210, 120), (240, 220, 120), (130, 180, 255)] * 3
    font = ImageFont.truetype(FONT, 46)

    def lines(d):
        R0, R1, R2 = 430, 360, 270
        for r in (R0, R1, R2, 150):
            ring(d, cx, cy, r, GOLD + (255,), 3)
        for i in range(12):
            a = math.radians(i * 30)
            d.line((cx + 270 * math.cos(a), cy + 270 * math.sin(a),
                    cx + 430 * math.cos(a), cy + 430 * math.sin(a)), fill=GOLD, width=3)
        for i in range(72):
            a = math.radians(i * 5)
            L = 18 if i % 6 else 30
            d.line((cx + (430 - L) * math.cos(a), cy + (430 - L) * math.sin(a),
                    cx + 430 * math.cos(a), cy + 430 * math.sin(a)), fill=GOLD, width=2)

    im = screen(im, glow_layer(lines, 10, 0.9))
    layer = Image.new('RGB', (W, H), (0, 0, 0))
    d = ImageDraw.Draw(layer)
    lines(d)
    # burç sembolleri
    for i, ch in enumerate(sym):
        a = math.radians(i * 30 + 15 - 90)
        x, y = cx + 395 * math.cos(a), cy + 395 * math.sin(a)
        d.text((x, y), ch, font=font, fill=colors[i], anchor='mm')
    # ev numaraları
    f2 = ImageFont.truetype(FONT, 26)
    for i in range(12):
        a = math.radians(i * 30 + 15 - 90)
        d.text((cx + 215 * math.cos(a), cy + 215 * math.sin(a)), str(i + 1), font=f2,
               fill=(190, 170, 255), anchor='mm')
    # açılar
    r = rng(3)
    pts = []
    for _ in range(9):
        a = math.radians(r.uniform(0, 360))
        pts.append((cx + 150 * math.cos(a), cy + 150 * math.sin(a), a))
    pal = [(255, 110, 150), (110, 200, 255), (255, 220, 120)]
    for i in range(len(pts)):
        for j in range(i + 1, len(pts)):
            if r.random() < 0.55:
                d.line(pts[i][:2] + pts[j][:2], fill=pal[(i + j) % 3], width=2)
    im = screen(im, layer)
    im = screen(im, glow_layer(lambda dd: [dd.line((0, 0, 0, 0))], 1))
    # gezegen noktaları (parlak)
    pl = Image.new('RGB', (W, H), (0, 0, 0))
    pd = ImageDraw.Draw(pl)
    for k, (x, y, _) in enumerate(pts):
        c = pal[k % 3]
        pd.ellipse((x - 13, y - 13, x + 13, y + 13), fill=c)
    im = screen(im, pl.filter(ImageFilter.GaussianBlur(8)))
    im = screen(im, pl)
    save(im, 'dogum-haritasi.webp')


# ───────────────────────── Aura analizi ─────────────────────────

def aura():
    im = base((6, 4, 26), (22, 10, 52), 11, 360)
    cx, cy = W // 2, 540
    cols = [(255, 60, 90), (255, 140, 40), (255, 225, 80), (60, 220, 130),
            (60, 180, 255), (120, 90, 255), (200, 90, 255)]
    # katmanlı hale (dıştan içe)
    for i, c in enumerate(cols):
        r = 500 - i * 58
        lay = Image.new('RGB', (W, H), (0, 0, 0))
        d = ImageDraw.Draw(lay)
        d.ellipse((cx - r * 0.78, cy - r * 1.02, cx + r * 0.78, cy + r * 1.0), fill=c)
        q = r - 62
        d.ellipse((cx - q * 0.78, cy - q * 1.02, cx + q * 0.78, cy + q * 1.0), fill=(0, 0, 0))
        lay = lay.filter(ImageFilter.GaussianBlur(34))
        lay = Image.fromarray((np.asarray(lay, float) * 0.62).astype('uint8'))
        im = screen(im, lay)
    # siluet
    sil = Image.new('L', (W, H), 0)
    d = ImageDraw.Draw(sil)
    d.ellipse((cx - 70, cy - 250, cx + 70, cy - 105), fill=255)  # kafa
    d.rounded_rectangle((cx - 30, cy - 120, cx + 30, cy - 70), 20, fill=255)  # boyun
    d.pieslice((cx - 200, cy - 90, cx + 200, cy + 380), 180, 360, fill=255)  # omuz
    d.rectangle((cx - 200, cy + 100, cx + 200, H), fill=255)
    sil = sil.filter(ImageFilter.GaussianBlur(2))
    dark = Image.new('RGB', (W, H), (8, 4, 24))
    im = Image.composite(dark, im, sil)
    # çakra noktaları
    ch = Image.new('RGB', (W, H), (0, 0, 0))
    cd = ImageDraw.Draw(ch)
    ys = [cy + 90, cy + 20, cy - 40, cy - 100, cy - 150, cy - 195, cy - 285]
    for y, c in zip(ys, reversed(cols)):
        cd.ellipse((cx - 16, y - 16, cx + 16, y + 16), fill=c)
    im = screen(im, ch.filter(ImageFilter.GaussianBlur(14)))
    im = screen(im, ch)
    # yükselen parçacıklar
    r = rng(5)
    pt = Image.new('RGB', (W, H), (0, 0, 0))
    pd = ImageDraw.Draw(pt)
    for _ in range(140):
        x = r.gauss(cx, 330)
        y = r.uniform(60, H - 60)
        s = r.choice([2, 2, 3, 4])
        c = r.choice(cols)
        pd.ellipse((x - s, y - s, x + s, y + s), fill=c)
    im = screen(im, pt.filter(ImageFilter.GaussianBlur(2)))
    save(im, 'aura-analizi.webp')


# ───────────────────────── Günlük fal ─────────────────────────

def daily():
    im = base((14, 8, 48), (58, 22, 84), 21, 380)
    cx, cy = W // 2, 470
    im = screen(im, radial(cx, cy + 30, 640, (200, 90, 120), 2.0))
    im = screen(im, radial(cx, H, 700, (120, 50, 140), 1.5))
    # güneş ışınları
    def rays(d):
        for i in range(36):
            a = math.radians(i * 10)
            r1, r2 = 190, 330 if i % 2 else 280
            w = math.radians(2.2)
            d.polygon([(cx + r1 * math.cos(a - w), cy + r1 * math.sin(a - w)),
                       (cx + r2 * math.cos(a), cy + r2 * math.sin(a)),
                       (cx + r1 * math.cos(a + w), cy + r1 * math.sin(a + w))],
                      fill=GOLD)
    im = screen(im, glow_layer(rays, 12, 0.9))
    lay = Image.new('RGB', (W, H), (0, 0, 0))
    rays(ImageDraw.Draw(lay))
    im = screen(im, Image.fromarray((np.asarray(lay, float) * 0.55).astype('uint8')))
    # güneş diski
    disc = glow_layer(lambda d: d.ellipse((cx - 150, cy - 150, cx + 150, cy + 150), fill=(255, 190, 80)), 40, 1.0)
    im = screen(im, disc)
    sun = radial(cx, cy, 175, (255, 248, 205), 0.28)
    mask = Image.new('L', (W, H), 0)
    ImageDraw.Draw(mask).ellipse((cx - 150, cy - 150, cx + 150, cy + 150), fill=255)
    im = Image.composite(sun, im, mask.filter(ImageFilter.GaussianBlur(1.5)))
    # hilal (güneşin önünde, sağ üst)
    cres = Image.new('L', (W, H), 0)
    d = ImageDraw.Draw(cres)
    mx, my, mr = cx + 190, cy - 170, 80
    d.ellipse((mx - mr, my - mr, mx + mr, my + mr), fill=255)
    d.ellipse((mx - mr + 38, my - mr - 10, mx + mr + 38, my + mr - 10), fill=0)
    im = screen(im, glow_layer(lambda dd: None, 1))
    moon = Image.new('RGB', (W, H), (235, 235, 255))
    im = Image.composite(moon, im, cres.filter(ImageFilter.GaussianBlur(1)))
    im = screen(im, Image.composite(Image.new('RGB', (W, H), (110, 110, 200)),
                                    Image.new('RGB', (W, H), (0, 0, 0)),
                                    cres.filter(ImageFilter.GaussianBlur(24))))
    # yörünge halkası + küçük yıldızlar
    def orb(d):
        ring(d, cx, cy, 400, (200, 170, 255), 2)
        ring(d, cx, cy, 470, (200, 170, 255), 1)
        for i in range(8):
            a = math.radians(i * 45 + 20)
            x, y = cx + 400 * math.cos(a), cy + 400 * math.sin(a)
            d.ellipse((x - 8, y - 8, x + 8, y + 8), fill=GOLD)
    im = screen(im, glow_layer(orb, 6, 0.9))
    lay = Image.new('RGB', (W, H), (0, 0, 0))
    orb(ImageDraw.Draw(lay))
    im = screen(im, Image.fromarray((np.asarray(lay, float) * 0.6).astype('uint8')))
    # alt: üç fal kartı yelpazesi
    cards = Image.new('RGB', (W, H), (0, 0, 0))
    for k, ang in enumerate((-16, 0, 16)):
        card = Image.new('RGBA', (180, 270), (0, 0, 0, 0))
        cd = ImageDraw.Draw(card)
        cd.rounded_rectangle((0, 0, 179, 269), 18, fill=(36, 18, 78, 255), outline=GOLD + (255,), width=4)
        cd.rounded_rectangle((16, 16, 163, 253), 10, outline=(255, 205, 110, 160), width=2)
        ccx, ccy = 90, 135
        for j in range(8):
            a = math.radians(j * 45)
            cd.line((ccx, ccy, ccx + 52 * math.cos(a), ccy + 52 * math.sin(a)), fill=GOLD + (255,), width=3)
        cd.ellipse((ccx - 22, ccy - 22, ccx + 22, ccy + 22), fill=(255, 205, 110, 255))
        card = card.rotate(ang, expand=True, resample=Image.BICUBIC)
        cards.paste(card, (cx - card.width // 2 + ang * 9, 800 - card.height // 2 + abs(ang) * 2), card)
    im = Image.composite(cards, im, Image.fromarray(((np.asarray(cards).sum(2) > 0) * 255).astype('uint8')))
    save(im, 'gunluk-fal.webp')


# ───────────────────────── Kurşun dökme ─────────────────────────

def lead():
    im = base((22, 12, 8), (52, 26, 14), 31, 90)
    cx = W // 2
    im = screen(im, radial(cx, 760, 640, (190, 80, 20), 1.7))
    im = screen(im, radial(cx, 120, 420, (200, 120, 50), 2.2))
    # su kasesi
    bowl = Image.new('RGB', (W, H), (0, 0, 0))
    d = ImageDraw.Draw(bowl)
    d.ellipse((cx - 470, 640, cx + 470, 900), fill=(70, 46, 28))
    d.ellipse((cx - 440, 650, cx + 440, 880), fill=(18, 40, 62))
    # su yansıması degradesi
    wat = radial(cx, 760, 440, (60, 120, 160), 1.2)
    mask = Image.new('L', (W, H), 0)
    ImageDraw.Draw(mask).ellipse((cx - 440, 650, cx + 440, 880), fill=255)
    bowl = Image.composite(screen(bowl, wat), bowl, mask)
    im = Image.composite(bowl, im, Image.fromarray(((np.asarray(bowl).sum(2) > 0) * 255).astype('uint8')).filter(ImageFilter.GaussianBlur(1)))
    # dalgalar
    def ripples(dd):
        for i, r in enumerate((60, 120, 190, 270, 360)):
            dd.ellipse((cx - r, 765 - r * 0.28, cx + r, 765 + r * 0.28),
                       outline=(150, 200, 235), width=3)
    im = screen(im, glow_layer(ripples, 5, 0.9))
    lay = Image.new('RGB', (W, H), (0, 0, 0))
    ripples(ImageDraw.Draw(lay))
    im = screen(im, Image.fromarray((np.asarray(lay, float) * 0.5).astype('uint8')))
    # kaşık + erimiş kurşun akışı
    sp = Image.new('RGB', (W, H), (0, 0, 0))
    d = ImageDraw.Draw(sp)
    d.polygon([(cx + 130, 40), (cx + 600, -40), (cx + 620, 20), (cx + 170, 110)], fill=(90, 90, 100))
    d.ellipse((cx - 150, 60, cx + 190, 200), fill=(120, 120, 130))
    d.ellipse((cx - 120, 78, cx + 160, 180), fill=(255, 190, 90))
    im = Image.composite(sp, im, Image.fromarray(((np.asarray(sp).sum(2) > 0) * 255).astype('uint8')))
    def metal(dd):
        dd.polygon([(cx - 14, 150), (cx + 14, 150), (cx + 9, 690), (cx - 9, 690)], fill=(255, 210, 140))
        dd.ellipse((cx - 22, 640, cx + 22, 700), fill=(255, 230, 180))
    im = screen(im, glow_layer(metal, 18, 1.0))
    lay = Image.new('RGB', (W, H), (0, 0, 0))
    metal(ImageDraw.Draw(lay))
    im = screen(im, lay)
    # sıçrayan metal parçaları (kurşun şekilleri)
    r = rng(9)
    sh = Image.new('RGB', (W, H), (0, 0, 0))
    sd = ImageDraw.Draw(sh)
    for _ in range(26):
        x = cx + r.gauss(0, 180)
        y = r.uniform(560, 740)
        n = r.randrange(5, 8)
        rad = r.uniform(8, 24)
        pts = [(x + rad * (0.6 + 0.6 * r.random()) * math.cos(2 * math.pi * k / n),
                y + rad * (0.6 + 0.6 * r.random()) * math.sin(2 * math.pi * k / n)) for k in range(n)]
        sd.polygon(pts, fill=(205, 210, 225))
    im = screen(im, sh.filter(ImageFilter.GaussianBlur(5)))
    im = screen(im, Image.fromarray((np.asarray(sh, float) * 0.85).astype('uint8')))
    # kıvılcımlar
    pt = Image.new('RGB', (W, H), (0, 0, 0))
    pd = ImageDraw.Draw(pt)
    for _ in range(90):
        x, y = cx + r.gauss(0, 260), r.uniform(100, 700)
        s = r.choice([2, 3, 3, 4])
        pd.ellipse((x - s, y - s, x + s, y + s), fill=(255, r.randrange(140, 220), 60))
    im = screen(im, pt.filter(ImageFilter.GaussianBlur(2)))
    save(im, 'kursundokme.webp')


# ───────────────────────── İstihare ─────────────────────────

def istihare():
    im = base((4, 18, 30), (10, 52, 62), 41, 460)
    cx, cy = W // 2, 400
    im = screen(im, radial(cx, cy, 520, (20, 120, 120), 1.8))
    # hilal
    cres = Image.new('L', (W, H), 0)
    d = ImageDraw.Draw(cres)
    R = 190
    d.ellipse((cx - R, cy - R, cx + R, cy + R), fill=255)
    d.ellipse((cx - R + 80, cy - R - 20, cx + R + 80, cy + R - 20), fill=0)
    glow = Image.composite(Image.new('RGB', (W, H), (90, 230, 220)), Image.new('RGB', (W, H), (0, 0, 0)),
                           cres.filter(ImageFilter.GaussianBlur(40)))
    im = screen(im, glow)
    im = Image.composite(Image.new('RGB', (W, H), (255, 244, 214)), im, cres.filter(ImageFilter.GaussianBlur(1.2)))
    # yıldız
    def star(dd, x, y, r1, r2, n=5):
        pts = []
        for k in range(n * 2):
            a = math.pi / n * k - math.pi / 2
            rr = r1 if k % 2 == 0 else r2
            pts.append((x + rr * math.cos(a), y + rr * math.sin(a)))
        dd.polygon(pts, fill=(255, 244, 214))
    st = Image.new('RGB', (W, H), (0, 0, 0))
    star(ImageDraw.Draw(st), cx + 70, cy - 20, 42, 17)
    im = screen(im, st.filter(ImageFilter.GaussianBlur(14)))
    im = screen(im, st)
    # tesbih: yay üzerinde parlayan taneler
    beads = Image.new('RGB', (W, H), (0, 0, 0))
    bd = ImageDraw.Draw(beads)
    n = 33
    for i in range(n):
        t = i / (n - 1)
        a = math.radians(200 + 140 * t)
        x = cx + 520 * math.cos(a)
        y = 1010 + 420 * math.sin(a)
        r = 22 if i % 11 != 10 else 30
        bd.ellipse((x - r, y - r, x + r, y + r), fill=(120, 235, 205) if i % 11 != 10 else (255, 215, 120))
    im = screen(im, beads.filter(ImageFilter.GaussianBlur(16)))
    hl = Image.fromarray((np.asarray(beads, float) * 0.9).astype('uint8'))
    im = screen(im, hl)
    # alt ufuk ışığı
    im = screen(im, radial(cx, H + 80, 700, (30, 140, 150), 1.4))
    save(im, 'istihare.webp')


if __name__ == '__main__':
    natal(); aura(); daily(); lead(); istihare()
