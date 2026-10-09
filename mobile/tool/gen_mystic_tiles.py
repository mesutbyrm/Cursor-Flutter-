#!/usr/bin/env python3
"""Ana sayfa + «Tüm Özellikler» kutuları için isme uygun mistik amblem görselleri.

Her kutunun kendi Material ikonu (ör. Jeton Al → coin) altın parıltılı amblem
olarak kozmik zemin + kutsal geometri halkaları üzerine çizilir. Çıktı:
assets/tiles/<slug>.webp. Kullanım: python3 tool/gen_mystic_tiles.py
"""
import hashlib, math, os, random, re, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FLUTTER = next(p for p in ['/opt/flutter-sdk', '/opt/flutter', os.environ.get('FLUTTER_ROOT', '')] if p and os.path.isdir(p))
FONT = f'{FLUTTER}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'
ICONS_DART = f'{FLUTTER}/packages/flutter/lib/src/material/icons.dart'
OUT = os.path.join(ROOT, 'assets', 'tiles')
SIZE = 360
COIN = '__coin__'

# İsme daha uygun amblem (kutunun uygulama içi ikonundan farklıysa).
OVERRIDES = {
    'feature-canli-falcilar': 'visibility_rounded',
    'feature-falci-paneli': 'style_rounded',
    'feature-odul-kazan': 'celebration_rounded',
}

_cp_cache = {}
def codepoint(name):
    if not _cp_cache:
        for m in re.finditer(r'static const IconData (\w+) = IconData\(\s*0x([0-9a-f]+)', open(ICONS_DART).read()):
            _cp_cache[m.group(1)] = int(m.group(2), 16)
    return _cp_cache[name]

TR = str.maketrans('çğıöşüÇĞİÖŞÜ', 'cgiosuCGIOSU')
def slugify(label):
    s = label.translate(TR).lower()
    return re.sub(r'[^a-z0-9]+', '-', s).strip('-')

def hexcol(v):
    v = int(v, 16)
    return ((v >> 16) & 255, (v >> 8) & 255, v & 255)

def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

def render(slug, icon, c1, c2):
    rnd = random.Random(int(hashlib.md5(slug.encode()).hexdigest()[:8], 16))
    W = SIZE
    deep = (11, 8, 32)
    # Kozmik zemin: radyal degrade
    bg = Image.new('RGB', (W, W), deep)
    px = bg.load()
    center_col = mix(mix(c1, deep, 0.45), c2, 0.15)
    for y in range(W):
        for x in range(W):
            d = math.hypot(x - W / 2, y - W * 0.46) / (W * 0.72)
            px[x, y] = mix(center_col, deep, min(1.0, d ** 0.9))
    # Nebula bulutları
    neb = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    nd = ImageDraw.Draw(neb)
    for _ in range(5):
        col = c1 if rnd.random() < 0.5 else c2
        r = rnd.randint(W // 6, W // 3)
        x, y = rnd.randint(0, W), rnd.randint(0, W)
        nd.ellipse([x - r, y - r, x + r, y + r], fill=col + (rnd.randint(40, 80),))
    neb = neb.filter(ImageFilter.GaussianBlur(W // 9))
    img = Image.alpha_composite(bg.convert('RGBA'), neb)
    d = ImageDraw.Draw(img)
    # Yıldızlar
    for _ in range(90):
        x, y = rnd.random() * W, rnd.random() * W
        a = rnd.randint(60, 220)
        s = rnd.choice([0.6, 0.8, 1.0, 1.4])
        d.ellipse([x - s, y - s, x + s, y + s], fill=(255, 250, 235, a))
    for _ in range(4):  # parıltı yıldızları
        x, y = rnd.random() * W, rnd.random() * W
        L = rnd.randint(5, 9)
        d.line([x - L, y, x + L, y], fill=(255, 240, 200, 200), width=1)
        d.line([x, y - L, x, y + L], fill=(255, 240, 200, 200), width=1)
    # Kutsal geometri halkaları
    gold = (232, 199, 122)
    cx, cy = W / 2, W * 0.46
    ring = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    rd = ImageDraw.Draw(ring)
    R1, R2 = W * 0.36, W * 0.29
    rd.ellipse([cx - R1, cy - R1, cx + R1, cy + R1], outline=gold + (150,), width=2)
    rd.ellipse([cx - R2, cy - R2, cx + R2, cy + R2], outline=gold + (90,), width=1)
    for i in range(12):
        t = i * math.pi / 6
        x, y = cx + R1 * math.cos(t), cy + R1 * math.sin(t)
        r = 3 if i % 3 == 0 else 1.8
        rd.ellipse([x - r, y - r, x + r, y + r], fill=gold + (220,))
        x2, y2 = cx + (R1 + 7) * math.cos(t), cy + (R1 + 7) * math.sin(t)
        x3, y3 = cx + (R1 + 13) * math.cos(t), cy + (R1 + 13) * math.sin(t)
        rd.line([x2, y2, x3, y3], fill=gold + (110,), width=1)
    # İç yıldız çokgeni (hexagram)
    pts = []
    for k in range(2):
        tri = [(cx + R2 * 0.98 * math.cos(math.pi / 2 + k * math.pi + j * 2 * math.pi / 3),
                cy - R2 * 0.98 * math.sin(math.pi / 2 + k * math.pi + j * 2 * math.pi / 3)) for j in range(3)]
        rd.polygon(tri, outline=gold + (55,))
    img = Image.alpha_composite(img, ring)
    # Amblem (ikon) — altın degrade + parıltı
    font = ImageFont.truetype(FONT, int(W * 0.40))
    mask = Image.new('L', (W, W), 0)
    md = ImageDraw.Draw(mask)
    coin = icon == COIN
    if coin:
        # Jeton: yıldız işlemeli altın sikke
        Rc = W * 0.19
        md.ellipse([cx - Rc, cy - Rc, cx + Rc, cy + Rc], fill=255)
        gw = gh = 2 * Rc
    else:
        ch = chr(codepoint(icon))
        bbox = md.textbbox((0, 0), ch, font=font)
        gw, gh = bbox[2] - bbox[0], bbox[3] - bbox[1]
        md.text((cx - gw / 2 - bbox[0], cy - gh / 2 - bbox[1]), ch, font=font, fill=255)
    for blur, col, alpha in [(W // 14, c2, 210), (W // 30, (255, 214, 120), 230)]:
        glow = Image.new('RGBA', (W, W), col + (0,))
        glow.putalpha(mask.filter(ImageFilter.GaussianBlur(blur)).point(lambda v: min(255, int(v * alpha / 255 * 1.6))))
        img = Image.alpha_composite(img, glow)
    grad = Image.new('RGBA', (W, W))
    gd = ImageDraw.Draw(grad)
    top, mid, bot = (255, 246, 214), (240, 196, 92), (176, 120, 40)
    for y in range(W):
        t = (y - (cy - gh / 2)) / max(1, gh)
        t = max(0.0, min(1.0, t))
        col = mix(top, mid, t * 2) if t < 0.5 else mix(mid, bot, (t - 0.5) * 2)
        gd.line([0, y, W, y], fill=col + (255,))
    grad.putalpha(mask)
    img = Image.alpha_composite(img, grad)
    if coin:
        ed = ImageDraw.Draw(img)
        engrave = (150, 98, 28, 255)
        Ri = W * 0.155
        ed.ellipse([cx - Ri, cy - Ri, cx + Ri, cy + Ri], outline=engrave, width=3)
        for i in range(36):  # kenar tırtılları
            t = i * math.pi / 18
            a, b = W * 0.172, W * 0.186
            ed.line([cx + a * math.cos(t), cy + a * math.sin(t), cx + b * math.cos(t), cy + b * math.sin(t)], fill=engrave, width=2)
        sf = ImageFont.truetype(FONT, int(W * 0.20))
        st = chr(codepoint('star_rounded'))
        sb = ed.textbbox((0, 0), st, font=sf)
        ed.text((cx - (sb[2] - sb[0]) / 2 - sb[0], cy - (sb[3] - sb[1]) / 2 - sb[1]), st, font=sf, fill=engrave)
    # Hafif vinyet
    vig = Image.new('L', (W, W), 0)
    ImageDraw.Draw(vig).ellipse([-W * 0.25, -W * 0.25, W * 1.25, W * 1.25], fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(W // 8))
    dark = Image.new('RGBA', (W, W), (5, 3, 15, 255))
    img = Image.composite(img, dark, vig)
    return img.convert('RGB')

def parse_entries(path):
    src = open(path).read()
    out = []
    for m in re.finditer(r"label:\s*'([^']+)'.*?icon:\s*Icons\.(\w+).*?colors:\s*(?:const\s*)?\[Color\(0xFF([0-9A-Fa-f]{6})\),\s*Color\(0xFF([0-9A-Fa-f]{6})\)\]", src, re.S):
        out.append((m.group(1), m.group(2), m.group(3), m.group(4)))
    return out

# Ana sayfa kutuları: rol duyarlı etiketlerde sabit slug; görsel ikonu isme göre seçilir.
HOME = [
    ('home-kesfet', 'explore_rounded', '8B5CF6', 'EC4899'),
    ('home-tanis-kaynas', 'favorite_rounded', 'A855F7', 'EC4899'),
    ('home-gold-uyelik', 'workspace_premium_rounded', 'FFD700', 'FF8A00'),
    ('home-canli-falcilar', 'visibility_rounded', 'EF4444', 'F97316'),
    ('home-tum-ozellikler', 'auto_awesome_mosaic_rounded', '475569', '8B5CF6'),
    ('home-falci', 'auto_awesome_rounded', '7C3AED', 'DB2777'),
    ('home-ajans', 'apartment_rounded', '10B981', '06B6D4'),
    ('home-yayinci', 'live_tv_rounded', 'FF2D7A', '8B5CF6'),
    ('home-jeton-al', COIN, 'F59E0B', 'EAB308'),
    ('home-hediye-yolla', 'card_giftcard_rounded', 'EC4899', 'F43F5E'),
]

def main():
    os.makedirs(OUT, exist_ok=True)
    jobs = [(s, i, a, b) for s, i, a, b in HOME]
    for label, icon, a, b in parse_entries(os.path.join(ROOT, 'lib/features/web_parity/domain/feature_catalog.dart')):
        slug = 'feature-' + slugify(label)
        jobs.append((slug, OVERRIDES.get(slug, icon), a, b))
    for slug, icon, a, b in jobs:
        img = render(slug, icon, hexcol(a), hexcol(b))
        img.save(os.path.join(OUT, slug + '.webp'), 'WEBP', quality=80, method=6)
        print(slug, icon)
    print(len(jobs), 'görsel')

if __name__ == '__main__':
    main()
