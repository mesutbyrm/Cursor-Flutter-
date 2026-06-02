#!/usr/bin/env python3
"""Migrate remaining AppColors semantic in features/ (build-context widgets only)."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib" / "features"

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

EXT = "import 'package:canlifal_social/core/theme/app_theme_extensions.dart';\n"
THEME_COLORS = "import 'package:canlifal_social/core/theme/app_theme_colors.dart';\n"


def has_build(text: str) -> bool:
    return bool(re.search(r"Widget\s+build\s*\(\s*BuildContext\s+context", text))


def strip_const(text: str) -> str:
    out = []
    for line in text.splitlines(keepends=True):
        if "context." in line:
            line = re.sub(r"\bconst\s+", "", line)
        out.append(line)
    return "".join(out)


def migrate(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    if "AppColors." not in text or not has_build(text):
        return False
    orig = text
    for old, new in sorted(CONTEXT, key=lambda x: -len(x[0])):
        text = text.replace(old, new)
    text = strip_const(text)
    if "context." in text and EXT.strip() not in text:
        anchor = "import 'package:flutter/material.dart';\n"
        if anchor in text:
            text = text.replace(anchor, anchor + EXT, 1)
    if "AppThemeColors." in text and THEME_COLORS.strip() not in text:
        anchor = "import 'package:flutter/material.dart';\n"
        if anchor in text:
            text = text.replace(anchor, anchor + THEME_COLORS, 1)
    if "AppColors." not in text:
        text = re.sub(r"import '[^']*app_colors\.dart';\n", "", text)
    if text == orig:
        return False
    path.write_text(text, encoding="utf-8")
    return True


def main() -> None:
    n = 0
    for path in sorted(ROOT.rglob("*.dart")):
        if migrate(path):
            print(path.relative_to(ROOT.parent.parent))
            n += 1
    print(f"Updated {n} feature files")


if __name__ == "__main__":
    main()
