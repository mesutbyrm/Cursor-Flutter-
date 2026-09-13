#!/usr/bin/env python3
"""
extra_main.json (Flutter-only main backend paths) vs nextjs_space/app/api/**/route.ts

Usage (fortune_telling_platform kökünden):
  python3 scripts/check-extra-main-api-routes.py
  NEXTJS_SPACE=/path/to/nextjs_space python3 scripts/check-extra-main-api-routes.py

Exit 0 when EKSİK == 0, else 1.
"""
from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_FL_REF = ROOT / "fl_ref"
DEFAULT_EXTRA = DEFAULT_FL_REF / "extra_main.json"
DEFAULT_NEXT = Path(os.environ.get("NEXTJS_SPACE", ROOT / "nextjs_space"))
API_DIR = DEFAULT_NEXT / "app" / "api"
SKIP_ROUTE_PARTS = ("[...unmatched]",)


def load_paths(extra_file: Path) -> list[str]:
    data = json.loads(extra_file.read_text(encoding="utf-8"))
    if isinstance(data, list):
        return data
    for key in ("paths", "flutter_only_main", "missing"):
        if key in data and isinstance(data[key], list):
            return data[key]
    raise SystemExit(f"extra_main.json: paths list not found in {extra_file}")


def flutter_to_pattern(api_path: str) -> str:
    p = api_path.strip()
    if not p.startswith("/api/"):
        raise ValueError(api_path)
    rel = p[len("/api/") :].strip("/")
    parts: list[str] = []
    for seg in rel.split("/"):
        if seg in ("{}", "*") or (seg.startswith("{") and seg.endswith("}")):
            parts.append("*")
        else:
            parts.append(seg)
    return "/".join(parts)


def route_dir_to_pattern(route_dir: Path, api_dir: Path) -> str:
    rel = route_dir.relative_to(api_dir)
    if any(part in SKIP_ROUTE_PARTS for part in rel.parts):
        return ""
    parts: list[str] = []
    for seg in rel.parts:
        if seg.startswith("[") and seg.endswith("]"):
            parts.append("*")
        else:
            parts.append(seg)
    return "/".join(parts)


def collect_patterns_from_filesystem(api_dir: Path) -> set[str]:
    if not api_dir.is_dir():
        return set()
    patterns: set[str] = set()
    for route_ts in api_dir.rglob("route.ts"):
        parent = route_ts.parent
        pat = route_dir_to_pattern(parent, api_dir)
        if pat:
            patterns.add(pat)
    return patterns


def openapi_path_to_pattern(api_path: str) -> str:
    if not api_path.startswith("/api/"):
        return ""
    if "[...unmatched]" in api_path:
        return ""
    rel = api_path[len("/api/") :].strip("/")
    parts: list[str] = []
    for seg in rel.split("/"):
        if seg.startswith("{") and seg.endswith("}"):
            parts.append("*")
        elif seg.startswith("[") and seg.endswith("]"):
            parts.append("*")
        else:
            parts.append(seg)
    return "/".join(parts)


def collect_patterns_from_endpoints_index(index_path: Path) -> set[str]:
    if not index_path.is_file():
        return set()
    entries = json.loads(index_path.read_text(encoding="utf-8"))
    patterns: set[str] = set()
    for e in entries:
        api_path = e.get("path") or ""
        pat = openapi_path_to_pattern(api_path)
        if pat:
            patterns.add(pat)

        file_rel = e.get("file") or ""
        if not file_rel.startswith("app/api/") or not file_rel.endswith("/route.ts"):
            continue
        dir_rel = file_rel[len("app/api/") : -len("/route.ts")]
        if any(s in dir_rel for s in SKIP_ROUTE_PARTS):
            continue
        parts = []
        for seg in dir_rel.split("/"):
            if seg.startswith("[") and seg.endswith("]"):
                parts.append("*")
            else:
                parts.append(seg)
        patterns.add("/".join(parts))
    return patterns


def main() -> int:
    extra_file = Path(os.environ.get("EXTRA_MAIN_JSON", DEFAULT_EXTRA))
    if not extra_file.is_file():
        print(f"EKSİK girdi: {extra_file}", file=sys.stderr)
        return 2

    wanted = load_paths(extra_file)
    parity_dir = Path(os.environ.get("PARITY_DIR", ROOT / "backend-parity" / "nextjs_space"))
    parity_api = parity_dir / "app" / "api"
    fs_patterns = collect_patterns_from_filesystem(API_DIR)
    if parity_api.is_dir():
        fs_patterns |= collect_patterns_from_filesystem(parity_api)
    source = "route.ts filesystem"
    if not fs_patterns and parity_api.is_dir():
        fs_patterns = collect_patterns_from_filesystem(parity_api)
        source = f"backend-parity ({parity_api})"
    if not fs_patterns:
        index_candidates: list[Path] = []
        env_index = os.environ.get("ENDPOINTS_INDEX")
        if env_index:
            index_candidates.append(Path(env_index))
        index_candidates.extend(
            [
                ROOT / "backend-reference" / "canlifal_flutter_paketi" / "endpoints_index.json",
                ROOT / "backend-docs" / "endpoints_index.json",
            ]
        )
        index = next((p for p in index_candidates if p.is_file()), index_candidates[-1])
        fs_patterns = collect_patterns_from_endpoints_index(index)
        source = f"endpoints_index fallback ({index})"
        if not API_DIR.is_dir():
            print(f"UYARI: {API_DIR} yok — kontrol {source} ile yapıldı.\n")

    missing: list[str] = []
    ok: list[str] = []
    for p in wanted:
        pat = flutter_to_pattern(p)
        if pat in fs_patterns:
            ok.append(p)
        else:
            missing.append(p)

    print("═" * 60)
    print("extra_main API route kontrolü")
    print(f"  extra_main: {extra_file}")
    print(f"  nextjs_space: {DEFAULT_NEXT}")
    print(f"  kaynak: {source}")
    print(f"  backend pattern sayısı: {len(fs_patterns)}")
    print(f"  kontrol edilen yol: {len(wanted)}")
    print(f"  VAR: {len(ok)}  EKSİK: {len(missing)}")
    print("═" * 60)

    if missing:
        from collections import defaultdict

        groups: defaultdict[str, list[str]] = defaultdict(list)
        for p in missing:
            parts = p.split("/")
            key = "/".join(parts[:3]) if len(parts) >= 3 else p
            groups[key].append(p)
        print("\nEKSİK yollar (gruplu):\n")
        for key in sorted(groups, key=lambda k: (-len(groups[k]), k)):
            print(f"  [{len(groups[key])}] {key}")
            for item in sorted(groups[key]):
                print(f"      {item}")
        return 1

    print("\nTüm extra_main yolları için route.ts eşleşmesi bulundu.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
