#!/usr/bin/env python3
"""Safe migration: brand → AppThemeColors; semantic → context.* only under lib/core."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib"

SKIP = {"app_colors.dart", "app_theme.dart"}

BRAND = [
    ("AppColors.accentPink", "AppThemeColors.accentPink"),
    ("AppColors.accentPurple", "AppThemeColors.accentPurple"),
    ("AppColors.accentCyan", "AppThemeColors.accentCyan"),
    ("AppColors.liveRed", "AppThemeColors.liveRed"),
    ("AppColors.onlineGreen", "AppThemeColors.onlineGreen"),
    ("AppColors.diamondBlue", "AppThemeColors.diamondBlue"),
    ("AppColors.coinGold", "AppThemeColors.coinGold"),
    ("AppColors.warning", "AppThemeColors.warning"),
    ("AppColors.glowShadow", "AppThemeColors.glowShadow"),
]

CONTEXT = [
    ("AppColors.textPrimary", "context.colors.onSurface"),
    ("AppColors.textSecondary", "context.colors.onSurfaceVariant"),
    ("AppColors.textMuted", "context.colors.onSurfaceMuted"),
    ("AppColors.background", "context.scaffoldBg"),
    ("AppColors.backgroundElevated", "context.colors.surfaceElevated"),
    ("AppColors.surface", "context.colors.surface"),
    ("AppColors.surfaceElevated", "context.colors.surfaceElevated"),
    ("AppColors.surfaceGlass", "context.colors.glassFill"),
    ("AppColors.bgPurpleGlow", "context.colors.surfaceContainer"),
    ("AppColors.bgBlueGlow", "context.colors.surfaceContainer"),
    ("AppColors.brandGradient", "context.colors.brandGradient"),
    ("AppColors.fabGradient", "context.colors.brandGradient"),
    ("AppColors.coinCapsuleGradient", "context.colors.brandGradient"),
]

CONTEXT_BRAND = [
    ("AppColors.accentPink", "context.accentPink"),
    ("AppColors.accentPurple", "context.accentPurple"),
    ("AppColors.accentCyan", "context.accentCyan"),
    ("AppColors.liveRed", "context.liveRed"),
    ("AppColors.onlineGreen", "context.onlineGreen"),
    ("AppColors.coinGold", "context.coinGold"),
]


def theme_import(path: Path, file: str) -> str:
    rel = path.relative_to(ROOT)
    depth = len(rel.parts) - 1
    return f"{'../' * depth}{file}"


def ensure_import(text: str, path: Path, file: str) -> str:
    imp = theme_import(path, file)
    if imp in text:
        return text
    anchor = "import 'package:flutter/material.dart';\n"
    if anchor in text:
        return text.replace(anchor, anchor + f"import '{imp}';\n", 1)
    return text


def strip_const(text: str) -> str:
    lines = []
    for line in text.splitlines(keepends=True):
        if "context." in line:
            line = re.sub(r"\bconst\s+", "", line)
        lines.append(line)
    return "".join(lines)


def apply_brand(text: str) -> str:
    for old, new in BRAND:
        text = text.replace(old, new)
    return text


def apply_context(text: str, include_brand: bool) -> str:
    mapping = list(CONTEXT)
    if include_brand:
        mapping = CONTEXT_BRAND + mapping
    for old, new in sorted(mapping, key=lambda x: -len(x[0])):
        text = text.replace(old, new)
    return strip_const(text)


def migrate_file(path: Path, mode: str) -> bool:
    if path.name in SKIP:
        return False
    text = path.read_text(encoding="utf-8")
    if "AppColors." not in text:
        return False
    orig = text
    if mode == "brand":
        text = apply_brand(text)
    elif mode == "core":
        if not re.search(r"Widget\s+build\s*\(\s*BuildContext\s+context", text):
            return False
        text = apply_brand(text)
        text = apply_context(text, include_brand=True)
        text = ensure_import(text, path, "theme/app_theme_extensions.dart")
    if "AppThemeColors." in text:
        text = ensure_import(text, path, "theme/app_theme_colors.dart")
    if "AppColors." not in text:
        text = re.sub(r"import '[^']*app_colors\.dart';\n", "", text)
    if text == orig:
        return False
    path.write_text(text, encoding="utf-8")
    return True


def main() -> None:
    mode = sys.argv[1] if len(sys.argv) > 1 else "all"
    changed = 0
    for path in sorted(ROOT.rglob("*.dart")):
        if mode == "brand":
            if "features" not in str(path) and "core" not in str(path):
                continue
            if migrate_file(path, "brand"):
                changed += 1
        elif mode == "core":
            if "/core/" not in str(path):
                continue
            if migrate_file(path, "core"):
                changed += 1
        else:
            # all = brand everywhere + core context
            m = "core" if "/core/" in str(path) else "brand"
            if migrate_file(path, m):
                changed += 1
    print(f"Updated {changed} files (mode={mode})")


if __name__ == "__main__":
    main()
