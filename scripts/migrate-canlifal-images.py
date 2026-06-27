#!/usr/bin/env python3
"""Migrate raw CachedNetworkImage / Image.network to Canlifal wrappers."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "mobile" / "lib"
IMPORT = "import 'package:canlifal_social/core/images/canlifal_network_image.dart';\n"
SKIP_DIRS = {"core/images"}

CACHE_PARAMS = (
    "memCacheWidth",
    "memCacheHeight",
    "maxWidthDiskCache",
    "maxHeightDiskCache",
    "cacheManager",
    "fadeInDuration",
    "cacheKey",
)


def should_process(path: Path) -> bool:
    parts = set(path.parts)
    return not (parts & SKIP_DIRS)


def strip_cache_params(text: str) -> str:
    for param in CACHE_PARAMS:
        text = re.sub(rf",?\s*{param}:\s*[^,\n)]+", "", text)
    return text


def fix_placeholder_builders(text: str) -> str:
    text = re.sub(r"placeholder:\s*\([^)]*\)\s*=>\s*", "placeholder: ", text)
    text = re.sub(r"errorWidget:\s*\([^)]*\)\s*=>\s*", "errorWidget: ", text)
    return text


def migrate_image_network(text: str) -> str:
    def repl_simple(m: re.Match[str]) -> str:
        url = m.group(1).strip()
        return f"CanlifalNetworkImage.full(url: {url}, fit: BoxFit.contain)"

    text = re.sub(
        r"Image\.network\(\s*([^,\n]+)\s*,\s*fit:\s*BoxFit\.contain\s*\)",
        repl_simple,
        text,
    )

    def repl_cover(m: re.Match[str]) -> str:
        url = m.group(1).strip()
        body = m.group(2)
        height = re.search(r"height:\s*([^,\n]+)", body)
        width = re.search(r"width:\s*([^,\n]+)", body)
        parts = [f"url: {url}", "fit: BoxFit.cover"]
        if height:
            parts.append(f"height: {height.group(1).strip()}")
        if width:
            parts.append(f"width: {width.group(1).strip()}")
        err = re.search(r"errorBuilder:\s*\([^)]*\)\s*=>\s*([^,]+),?", body)
        if err:
            parts.append(f"errorWidget: {err.group(1).strip()}")
        return f"CanlifalNetworkImage({', '.join(parts)})"

    text = re.sub(
        r"Image\.network\(\s*([^,\n]+)\s*,\s*((?:.|\n)*?)\s*\)",
        repl_cover,
        text,
        flags=re.MULTILINE,
    )
    return text


def ensure_import(text: str) -> str:
    if "canlifal_network_image.dart" in text:
        return text
    if not any(
        tok in text
        for tok in (
            "CanlifalNetworkImage",
            "canlifalImageProvider",
        )
    ):
        return text

    cni = "import 'package:cached_network_image/cached_network_image.dart';\n"
    text = text.replace(cni, "")

    pkg_imports = list(
        re.finditer(r"^import 'package:[^']+';\n", text, flags=re.MULTILINE)
    )
    if pkg_imports:
        pos = pkg_imports[-1].end()
        return text[:pos] + IMPORT + text[pos:]

    rel_imports = list(re.finditer(r"^import '[^']+';\n", text, flags=re.MULTILINE))
    if rel_imports:
        pos = rel_imports[-1].end()
        return text[:pos] + IMPORT + text[pos:]

    return IMPORT + text


def migrate_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    original = text

    if not any(
        s in text
        for s in (
            "CachedNetworkImage",
            "Image.network",
            "NetworkImage(",
        )
    ):
        return False

    text = text.replace("CachedNetworkImageProvider(", "canlifalImageProvider(")
    text = re.sub(
        r"(?<![\w])NetworkImage\(",
        "canlifalImageProvider(",
        text,
    )
    text = text.replace("CachedNetworkImage(", "CanlifalNetworkImage(")
    text = text.replace("imageUrl:", "url:")
    text = strip_cache_params(text)
    text = fix_placeholder_builders(text)
    text = migrate_image_network(text)
    text = ensure_import(text)

    if text != original:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def main() -> None:
    changed: list[str] = []
    for path in sorted(ROOT.rglob("*.dart")):
        if not should_process(path):
            continue
        if migrate_file(path):
            changed.append(str(path.relative_to(ROOT.parent.parent)))

    print(f"Migrated {len(changed)} files")
    for p in changed:
        print(f"  {p}")


if __name__ == "__main__":
    main()
