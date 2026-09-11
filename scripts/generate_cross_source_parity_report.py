#!/usr/bin/env python3
"""Generate docs/CROSS_SOURCE_API_PARITY_REPORT.md — see CURRENT_BACKEND_SOURCE_SET."""
from __future__ import annotations

import json
import re
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/CROSS_SOURCE_API_PARITY_REPORT.md"


def read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace") if p.exists() else ""


def load_json(p: Path) -> dict:
    return json.loads(read(p)) if p.exists() else {}


def norm(p: str) -> str:
    p = re.sub(r"\$\{[^}]+\}", "*", p)
    p = re.sub(r"\{[^}]+\}", "*", p)
    return p.split("?")[0]


def main() -> None:
    openapi_path = ROOT / "backend-docs/openapi.json"
    openapi_abacus = ROOT / "backend-docs/abacus-current/priority1/openapi.json"
    idx_path = ROOT / "backend-docs/endpoints_index.json"

    openapi = load_json(openapi_path)
    paths_o = set(openapi.get("paths", {}))
    paths_a = set(load_json(openapi_abacus).get("paths", {}))

    idx = load_json(idx_path)
    idx_pairs = {(e["path"], e["method"].upper()) for e in idx} if idx else set()
    o_pairs: set[tuple[str, str]] = set()
    for path, methods in openapi.get("paths", {}).items():
        for m in methods:
            if m.upper() in ("GET", "POST", "PUT", "PATCH", "DELETE"):
                o_pairs.add((path, m.upper()))

    api_norm = {norm(p): p for p in paths_o}

    lib_paths: set[str] = set()
    for f in (ROOT / "mobile/lib").rglob("*.dart"):
        lib_paths.update(re.findall(r"['\"](/api/[^'\"$]+)['\"]", read(f)))

    ep_literals = set(
        re.findall(r"['\"](/api/[^'\"$]+)['\"]", read(ROOT / "mobile/lib/core/network/api_endpoints.dart"))
    )

    matched, flutter_only = [], []
    for p in sorted(lib_paths):
        if norm(p) in api_norm:
            matched.append(p)
        else:
            flutter_only.append(p)

    guide = read(ROOT / "docs/FLUTTER_ENTegrasyon_KILAVUZU.md")
    guide_api_refs = set(re.findall(r"`(/api/[^`]+)`", guide))

    md_sources = [
        ("CURRENT_BACKEND_SOURCE_SET", ROOT / "_zip_analysis/CURRENT_BACKEND_SOURCE_SET.md"),
        ("FLUTTER_ENTegrasyon_KILAVUZU", ROOT / "docs/FLUTTER_ENTegrasyon_KILAVUZU.md"),
        ("abacus 00_BASLA", ROOT / "backend-docs/abacus-current/00_BASLA_BURADAN.md"),
        ("B1_12 (legacy audit)", ROOT / "backend-docs/B1_12_API_MCP_FLUTTER_PARITY.md"),
        ("MCP_REGISTRY", ROOT / "backend-docs/MCP_REGISTRY.md"),
        ("MCP_INTEGRATION_MATRIX", ROOT / "docs/MCP_INTEGRATION_MATRIX.md"),
        ("zip MCP_VE_ENTEGRASYONLAR", ROOT / "_zip_analysis/MCP_VE_ENTEGRASYONLAR.md"),
        (
            "HEDIYE dok (abacus p2)",
            ROOT / "backend-docs/abacus-current/priority2/CANLIFAL_HEDIYE_SISTEMI_DOKUMANTASYONU.md",
        ),
    ]

    by_prefix: dict[str, list[str]] = defaultdict(list)
    for p in flutter_only:
        parts = p.strip("/").split("/")
        key = "/".join(parts[:3]) if len(parts) >= 3 else p
        by_prefix[key].append(p)

    flutter_norm = {norm(p) for p in lib_paths}
    openapi_not_referenced = len(paths_o) - len(flutter_norm & set(api_norm))

    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    lines: list[str] = [
        "# Cross-source API / MCP / Flutter parity report",
        "",
        f"> **Generated:** {ts} (`scripts/generate_cross_source_parity_report.py`)",
        "",
        "## 1. Kaynak önceliği (CURRENT)",
        "",
        "1. Üretim davranışı (`https://canlifal.com`)",
        "2. `_zip_analysis/` Sep 10 envanter (~852 satır)",
        "3. `backend-docs/openapi.json` + `endpoints_index.json`",
        "4. `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` (mobil sözleşme)",
        "5. `backend-docs/abacus-current/**` (Abacus devir paketi)",
        "",
        "**MCP:** `mcp-server/` yalnızca geliştirici aracı; Flutter runtime REST+SSE kullanır.",
        "",
        "## 2. Şema / indeks uyumu",
        "",
        "| Kaynak | Ölçüm |",
        "|--------|------:|",
        f"| `backend-docs/openapi.json` paths | **{len(paths_o)}** |",
        f"| `abacus-current/priority1/openapi.json` paths | **{len(paths_a)}** |",
        f"| OpenAPI ↔ Abacus path farkı | **{len(paths_o ^ paths_a)}** |",
        f"| `endpoints_index.json` handler | **{len(idx_pairs)}** |",
        f"| OpenAPI method×path çifti | **{len(o_pairs)}** |",
        f"| Index ↔ OpenAPI fark | **{len(idx_pairs ^ o_pairs)}** |",
        "",
        "## 3. Flutter (`mobile/lib`) ↔ OpenAPI",
        "",
        "| Ölçüm | Adet |",
        "|-------|-----:|",
        f"| `api_endpoints.dart` sabitleri | {len(ep_literals)} |",
        f"| Tüm `lib/` `/api/` literal | **{len(lib_paths)}** |",
        f"| OpenAPI ile normalize eşleşme | **{len(matched)}** |",
        f"| Flutter-only (OpenAPI’de yok / farklı şablon) | **{len(flutter_only)}** |",
        f"| OpenAPI path Flutter’da hiç geçmiyor (yaklaşık) | **{openapi_not_referenced}** |",
        f"| Kılavuzda geçen `/api/...` backtick | **{len(guide_api_refs)}** |",
        "",
        "### 3.1 Flutter-only gruplar (ilk 15)",
        "",
    ]
    for k, v in sorted(by_prefix.items(), key=lambda x: -len(x[1]))[:15]:
        lines.append(f"- `{k}` — **{len(v)}** uç")
    lines += [
        "",
        "### 3.2 Flutter-only örnek (ilk 25)",
        "",
        "```",
        *flutter_only[:25],
        "```",
        "",
        "## 4. MCP dokümantasyonu",
        "",
        "| Dosya | Var |",
        "|-------|-----|",
    ]
    for name, p in md_sources[4:7]:
        lines.append(f"| `{name}` | {'✅' if p.exists() else '❌'} |")
    lines += [
        "",
        "MCP araçları `endpoints_index.json` / OpenAPI ile aynı envanteri okur; **üretim API hızını etkilemez**.",
        "",
        "## 5. Abacus / MD dosya envanteri",
        "",
        "| Dosya | Boyut (KB) |",
        "|-------|----------:|",
    ]
    for _name, p in md_sources:
        if p.exists():
            kb = p.stat().st_size / 1024
            lines.append(f"| `{p.relative_to(ROOT)}` | {kb:.1f} |")
    abacus_md = list((ROOT / "backend-docs/abacus-current").rglob("*.md"))
    lines += [
        "",
        f"**`backend-docs/abacus-current/` toplam `.md`:** {len(abacus_md)}",
        "",
        "## 6. Bilinen çelişkiler / güncellik",
        "",
        "| Konu | Durum | Not |",
        "|------|-------|-----|",
        "| `B1_12` gifts insights WRONG_HOST | Muhtemelen güncel değil | 2026-09-11: `/api/gifts/insights/feed` canlifal.com → 200 |",
        "| `admin/payment-requests` vs `cfc-payment-requests` | Mobil yedek | OpenAPI kanonik: `cfc-payment-requests` |",
        "| `financeMode` (staff/real jeton) | OpenAPI yok | Mobil 1.0.473+ gönderir; şema/üretim doğrulanmalı |",
        "| 852 vs 780 vs 502 sayım | Beklenen | Farklı ölçüm birimleri (route/handler/path) |",
        "",
        "## 7. Hız / runtime (backend ile aynı davranış)",
        "",
        "- **Doğru host:** `ApiBackendRouter` — sesli oda `.../pk*` → games API; geri kalan → `canlifal.com`.",
        "- **Gereksiz 404:** Hediye insights ana backend’de; eski B1_12 games yönlendirme riski güncel değil.",
        "- **Önbellek / retry:** `api_cache_interceptor`, `api_retry_interceptor` (kılavuz §7).",
        "- **SSE:** 5 kanonik endpoint, backoff (kılavuz §5–6).",
        "",
        "## 8. Komutlar",
        "",
        "```bash",
        "bash scripts/abacus-openapi-parity.sh",
        "python3 scripts/generate_cross_source_parity_report.py",
        "cd mobile && flutter test test/core/network/api_endpoint_canonical_contract_test.dart",
        "```",
        "",
    ]
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT} ({len(lines)} lines)")


if __name__ == "__main__":
    main()
