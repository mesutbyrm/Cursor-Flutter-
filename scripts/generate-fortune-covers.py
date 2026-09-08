#!/usr/bin/env python3
"""Mistik fal kapak görselleri — dogum-haritasi, kursundokme, aura-analizi."""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parents[1] / "mobile" / "assets" / "fortune"
SIZE = (1536, 1024)


def _lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def _radial_gradient(
    w: int, h: int, inner: tuple[int, int, int], outer: tuple[int, int, int]
) -> Image.Image:
    img = Image.new("RGB", (w, h))
    px = img.load()
    cx, cy = w * 0.45, h * 0.38
    max_d = math.hypot(w, h)
    for y in range(h):
        for x in range(w):
            d = math.hypot(x - cx, y - cy) / max_d
            t = min(1.0, d * 1.35)
            r = int(_lerp(inner[0], outer[0], t))
            g = int(_lerp(inner[1], outer[1], t))
            b = int(_lerp(inner[2], outer[2], t))
            px[x, y] = (r, g, b)
    return img


def _stars(draw: ImageDraw.ImageDraw, w: int, h: int, count: int, color: tuple[int, int, int, int]) -> None:
    rng = random.Random(42)
    for _ in range(count):
        x = rng.randint(0, w - 1)
        y = rng.randint(0, h - 1)
        r = rng.choice([1, 1, 2, 2, 3])
        draw.ellipse((x - r, y - r, x + r, y + r), fill=color)


def _glow_orb(
    base: Image.Image,
    center: tuple[float, float],
    radius: float,
    color: tuple[int, int, int],
    alpha: int = 90,
) -> None:
    w, h = base.size
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = center
    draw.ellipse(
        (cx - radius, cy - radius, cx + radius, cy + radius),
        fill=(*color, alpha),
    )
    layer = layer.filter(ImageFilter.GaussianBlur(radius=radius * 0.35))
    base.alpha_composite(layer)


def _zodiac_wheel(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float) -> None:
    for i in range(12):
        ang = math.radians(i * 30 - 90)
        x1 = cx + math.cos(ang) * (r * 0.72)
        y1 = cy + math.sin(ang) * (r * 0.72)
        x2 = cx + math.cos(ang) * r
        y2 = cy + math.sin(ang) * r
        draw.line((x1, y1, x2, y2), fill=(255, 215, 120, 140), width=3)
    draw.ellipse(
        (cx - r, cy - r, cx + r, cy + r),
        outline=(200, 180, 255, 180),
        width=4,
    )
    draw.ellipse(
        (cx - r * 0.55, cy - r * 0.55, cx + r * 0.55, cy + r * 0.55),
        outline=(120, 200, 255, 120),
        width=2,
    )


def _aura_rings(draw: ImageDraw.ImageDraw, cx: float, cy: float) -> None:
    colors = [
        (180, 100, 255, 70),
        (100, 200, 255, 55),
        (255, 120, 200, 45),
        (120, 255, 180, 35),
    ]
    for i, c in enumerate(colors):
        rr = 180 + i * 55
        draw.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), outline=c, width=6)


def _lead_melt(draw: ImageDraw.ImageDraw, cx: float, cy: float) -> None:
    rng = random.Random(7)
    for _ in range(28):
        ang = rng.uniform(0, math.tau)
        dist = rng.uniform(40, 200)
        x = cx + math.cos(ang) * dist
        y = cy + math.sin(ang) * dist * 0.7
        sz = rng.uniform(8, 28)
        draw.ellipse(
            (x - sz, y - sz * 0.6, x + sz, y + sz * 0.6),
            fill=(200, 195, 185, rng.randint(60, 130)),
        )


def build_dogum_haritasi() -> Image.Image:
    w, h = SIZE
    base = _radial_gradient(w, h, (45, 25, 95), (8, 4, 22)).convert("RGBA")
    _glow_orb(base, (w * 0.55, h * 0.42), 280, (90, 140, 255))
    _glow_orb(base, (w * 0.35, h * 0.55), 200, (180, 100, 255), 60)
    draw = ImageDraw.Draw(base)
    _stars(draw, w, h, 220, (255, 255, 255, 160))
    _zodiac_wheel(draw, w * 0.58, h * 0.46, 220)
    for i, (ox, oy) in enumerate([(0.25, 0.3), (0.72, 0.22), (0.82, 0.62), (0.18, 0.7)]):
        _glow_orb(base, (w * ox, h * oy), 35 + i * 8, (255, 220, 150), 100)
    return base.filter(ImageFilter.GaussianBlur(radius=0.6))


def build_kursundokme() -> Image.Image:
    w, h = SIZE
    base = _radial_gradient(w, h, (55, 35, 30), (12, 8, 18)).convert("RGBA")
    _glow_orb(base, (w * 0.5, h * 0.5), 320, (255, 160, 80), 55)
    draw = ImageDraw.Draw(base)
    _stars(draw, w, h, 80, (255, 200, 120, 100))
    # mum ışığı
    draw.polygon(
        [
            (w * 0.48, h * 0.72),
            (w * 0.52, h * 0.72),
            (w * 0.51, h * 0.35),
            (w * 0.49, h * 0.35),
        ],
        fill=(240, 220, 180, 200),
    )
    _glow_orb(base, (w * 0.5, h * 0.32), 90, (255, 220, 120), 140)
    _lead_melt(draw, w * 0.5, h * 0.58)
    return base


def build_aura_analizi() -> Image.Image:
    w, h = SIZE
    base = _radial_gradient(w, h, (60, 20, 100), (10, 5, 25)).convert("RGBA")
    draw = ImageDraw.Draw(base)
    _stars(draw, w, h, 160, (255, 255, 255, 120))
    _aura_rings(draw, w * 0.55, h * 0.48)
    _glow_orb(base, (w * 0.55, h * 0.48), 120, (200, 150, 255), 110)
    return base.filter(ImageFilter.GaussianBlur(radius=0.4))


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    targets = {
        "dogum-haritasi.webp": build_dogum_haritasi(),
        "kursundokme.webp": build_kursundokme(),
        "aura-analizi.webp": build_aura_analizi(),
    }
    for name, img in targets.items():
        path = OUT / name
        rgb = img.convert("RGB")
        rgb.save(path, "WEBP", quality=88, method=6)
        print(f"wrote {path} ({rgb.size[0]}x{rgb.size[1]})")


if __name__ == "__main__":
    main()
