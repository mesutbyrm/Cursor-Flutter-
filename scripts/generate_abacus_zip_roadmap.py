#!/usr/bin/env python3
"""Zip paketi envanteri + Flutter FLUTTER_READY kapsam matrisi (backend-reference değiştirilmez)."""
from __future__ import annotations

import json
import re
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REF = ROOT / "backend-reference/canlifal_flutter_paketi"
OUT_INDEX = ROOT / "docs/ABACUS_ZIP_PACKAGE_INDEX.md"
OUT_ROADMAP = ROOT / "docs/ABACUS_ZIP_FLUTTER_ROADMAP.md"
OUT_CATALOG = ROOT / "mobile/lib/core/abacus/abacus_flutter_ready_catalog.dart"

SECTION_BY_PREFIX = {
    "auth": 1,
    "devices": 1,
    "mobile": 1,
    "signup": 1,
    "verification": 1,
    "me": 2,
    "user": 2,
    "users": 2,
    "presence": 2,
    "settings": 2,
    "upload": 2,
    "activities": 2,
    "translations": 2,
    "fortune": 3,
    "fortunes": 3,
    "fortune-tellers": 3,
    "fortune-access": 3,
    "dreams": 4,
    "dream-contest": 4,
    "horoscope": 5,
    "astrology-panel": 5,
    "video-streams": 6,
    "live": 6,
    "trtc": 6,
    "agora": 6,
    "chat": 7,
    "room": 7,
    "gifts": 8,
    "gift-box": 8,
    "gift-engine": 8,
    "wallet": 8,
    "jeton": 8,
    "cfc": 8,
    "payments": 9,
    "billing": 9,
    "refunds": 9,
    "memberships": 10,
    "membership": 10,
    "vip": 10,
    "social": 11,
    "hashtags": 11,
    "search": 11,
    "share-card": 11,
    "teams": 11,
    "messages": 12,
    "notifications": 12,
    "popups": 12,
    "support": 12,
    "homepage-ticker": 12,
    "announcements": 12,
    "gifts": 13,
    "games": 13,
    "missions": 13,
    "ranking": 14,
    "agency": 15,
    "cosmetics": 16,
    "bana-ozel": 16,
    "site-pages": 17,
    "blog": 17,
    "banners": 17,
    "short-videos": 17,
    "bootstrap": 18,
    "health": 18,
    "public-stats": 18,
}


def norm_path(p: str) -> str:
    p = re.sub(r"\[([^\]]+)\]", r"{\1}", p)
    p = re.sub(r"\{[^}]+\}", "*", p)
    return p.split("?")[0]


def mobile_has_path(path: str, ep_dart: str, lib: str) -> bool:
    n = norm_path(path)
    bare = path.replace("[", "{").replace("]", "}")
    if bare in ep_dart or path in ep_dart:
        return True
    # template in dart: '/api/foo/$id'
    dartish = re.sub(r"\{[^}]+\}", r"$*", bare)
    if dartish.replace("$*", "") in ep_dart:
        return True
    seg = path.split("/")[2] if path.count("/") >= 2 else path
    if f"/api/{seg}/" in lib and norm_path(path).count("*") <= 1:
        if path in lib or bare in lib:
            return True
    for line in ep_dart.splitlines():
        if "/api/" not in line:
            continue
        m = re.search(r"'(/api/[^']+)'", line)
        if m and norm_path(m.group(1)) == n:
            return True
    return path in lib or bare in lib


def section_for(path: str) -> int:
    parts = path.strip("/").split("/")
    if len(parts) < 2:
        return 18
    key = parts[1]
    return SECTION_BY_PREFIX.get(key, 18)


def main() -> None:
    classification = json.loads((REF / "endpoint_classification.json").read_text())
    flutter_ready = [e for e in classification if e.get("class") == "FLUTTER_READY"]

    ep_dart = (ROOT / "mobile/lib/core/network/api_endpoints.dart").read_text()
    lib = ""
    for f in (ROOT / "mobile/lib").rglob("*.dart"):
        lib += f.read_text(encoding="utf-8", errors="replace")

    by_section: dict[int, list] = defaultdict(list)
    for e in flutter_ready:
        p = e["path"]
        sec = section_for(p)
        covered = mobile_has_path(p, ep_dart, lib)
        by_section[sec].append((p, e["methods"], covered))

    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    # --- Package index ---
    files = sorted(REF.rglob("*"))
    md_files = [f for f in files if f.suffix in {".md", ".yaml", ".json", ".sql"} and f.is_file()]
    kaynak_ts = list((REF / "kaynak").rglob("*.ts")) if (REF / "kaynak").exists() else []

    index_lines = [
        "# Abacus ZIP paketi — dosya envanteri",
        "",
        f"> **Üretim:** {ts} · `scripts/generate_abacus_zip_roadmap.py`",
        f"> **Kaynak:** `backend-reference/canlifal_flutter_paketi/` (değiştirilmez)",
        "",
        "## Özet",
        "",
        f"| Ölçüm | Değer |",
        f"|-------|------:|",
        f"| Paket dosyası (toplam) | {len([f for f in files if f.is_file()])} |",
        f"| Doküman / sözleşme | {len(md_files)} |",
        f"| `kaynak/lib/*.ts` referans | {len(kaynak_ts)} |",
        f"| OpenAPI `FLUTTER_READY` path | {len(flutter_ready)} |",
        "",
        "## Ana dosyalar (okuma sırası)",
        "",
        "1. `00_OKU_BENI.md` — giriş",
        "2. `TUM_OZELLIKLER_HARITASI.md` — 19 özellik alanı (§1–§19)",
        "3. `ENDPOINTS.md` / `endpoints_index.json` — 953 uç",
        "4. `endpoint_classification.json` — FLUTTER_READY / PUBLIC / ADMIN",
        "5. `openapi.yaml` — OpenAPI 3.0.3",
        "6. `authentication.md` · `REALTIME.md` · `websocket_events.md`",
        "7. `BOLUM22_MULTIGUEST_PK_GIFTBOX.md`",
        "8. `live_stream_api.md` · `voice_room_api.md` · `gifts_coins_wallet_api.md`",
        "9. `flutter_integration_checklist.md`",
        "10. `kaynak/` — prisma + kritik lib TS",
        "",
        "## Tam dosya listesi (zip)",
        "",
    ]
    for f in sorted([p for p in files if p.is_file()], key=lambda p: str(p.relative_to(REF))):
        rel = f.relative_to(REF)
        index_lines.append(f"- `{rel}`")
    index_lines.extend([
        "",
        "## Flutter eşleme stratejisi",
        "",
        "- **Sıra:** `TUM_OZELLIKLER_HARITASI.md` §1 → §18 (admin §19 web-only).",
        "- **Katman:** `api_endpoints.dart` → feature `*RemoteDataSource` → Riverpod → mevcut UI.",
        "- **Şema MISSING:** ham `Map` / `pick()` — alan uydurulmaz.",
        "- **Katalog:** `mobile/lib/core/abacus/abacus_flutter_ready_catalog.dart` (otomatik).",
        "",
    ])
    OUT_INDEX.write_text("\n".join(index_lines), encoding="utf-8")

    # --- Roadmap ---
    section_titles = {
        1: "Kimlik & Oturum",
        2: "Kullanıcı Profili & Ayarlar",
        3: "Fal & Falcılar",
        4: "Rüya Dünyası",
        5: "Astroloji & Uyum",
        6: "Canlı Yayın",
        7: "Sesli Oda",
        8: "Hediye, Jeton & Cüzdan",
        9: "Ödeme & Faturalama",
        10: "Üyelik & VIP",
        11: "Sosyal & Keşif",
        12: "Mesajlaşma & Bildirim",
        13: "Görev, Ödül & Oyun",
        14: "Sıralama & Turnuva",
        15: "Ajans",
        16: "Kozmetik & Bana Özel",
        17: "İçerik & CMS",
        18: "Altyapı & Sistem",
    }

    total = len(flutter_ready)
    covered_n = sum(1 for e in flutter_ready if mobile_has_path(e["path"], ep_dart, lib))

    road = [
        "# Abacus ZIP → Flutter yol haritası",
        "",
        f"> **Üretim:** {ts}",
        "",
        "## Durum özeti",
        "",
        f"| Metrik | Değer |",
        f"|--------|------:|",
        f"| `FLUTTER_READY` path (unique) | {total} |",
        f"| Mobil tarafta iz (endpoint const veya kullanım) | ~{covered_n} |",
        f"| Eksik / kısmi (tahmini) | ~{total - covered_n} |",
        "",
        "Aşağıdaki tablolar **otomatik taramadır**; `PARTIAL` = path var ama datasource/UI eksik olabilir.",
        "",
    ]

    for sec in sorted(by_section.keys()):
        rows = by_section[sec]
        done = sum(1 for _, _, c in rows if c)
        title = section_titles.get(sec, f"Bölüm {sec}")
        road.append(f"## §{sec} — {title}")
        road.append("")
        road.append(f"**{done}/{len(rows)}** path izi mobil `lib/` içinde bulundu.")
        road.append("")
        road.append("| Path | Metotlar | Mobil iz |")
        road.append("|------|----------|----------|")
        for p, methods, cov in sorted(rows, key=lambda x: x[0]):
            flag = "✅" if cov else "⬜"
            ms = ", ".join(methods)
            road.append(f"| `{p}` | {ms} | {flag} |")
        road.append("")

    road.append("## Sonraki agent işleri (öncelik)")
    road.append("")
    road.append("1. §11 Sosyal — `social_abacus_remote_datasource` (discovery, actions, profile, share-card, teams, hashtags)")
    road.append("2. §2 — `/api/me/membership*` VIP yetenek paketi")
    road.append("3. §6–§7 — video-streams/chat eksik sync/guest uçları (BÖLÜM 22)")
    road.append("4. §13 — games/missions eksikleri")
    road.append("5. Her bölüm bitiminde: `flutter test` + contract test")
    road.append("")

    OUT_ROADMAP.write_text("\n".join(road), encoding="utf-8")

    # --- Dart catalog ---
    dart_lines = [
        "// GENERATED — do not edit. Run: python3 scripts/generate_abacus_zip_roadmap.py",
        "abstract final class AbacusFlutterReadyCatalog {",
        f"  static const generatedAt = '{ts}';",
        f"  static const pathCount = {total};",
        "",
        "  /// TUM_OZELLIKLER_HARITASI § sırasına yakın gruplar.",
        "  static const pathsBySection = <int, List<String>>{",
    ]
    for sec in sorted(by_section.keys()):
        paths = sorted({p for p, _, _ in by_section[sec]})
        dart_lines.append(f"    {sec}: [")
        for p in paths:
            dart_lines.append(f"      '{p}',")
        dart_lines.append("    ],")
    dart_lines.extend(["  };", "}", ""])
    OUT_CATALOG.parent.mkdir(parents=True, exist_ok=True)
    OUT_CATALOG.write_text("\n".join(dart_lines), encoding="utf-8")

    print(f"Wrote {OUT_INDEX}")
    print(f"Wrote {OUT_ROADMAP}")
    print(f"Wrote {OUT_CATALOG}")


if __name__ == "__main__":
    main()
