#!/usr/bin/env python3
"""Flutter ↔ Abacus FLUTTER_READY entegrasyon audit matrisi (okuma-only)."""
from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REF = ROOT / "backend-reference/canlifal_flutter_paketi"
MOBILE = ROOT / "mobile/lib"
OUT = ROOT / "docs/ABACUS_FLUTTER_INTEGRATION_AUDIT.md"


def norm_path(p: str) -> str:
    p = re.sub(r"\[([^\]]+)\]", r"{\1}", p)
    return p


def path_in_lib(path: str, lib: str, ep: str) -> bool:
    bare = path.replace("[", "{").replace("]", "}")
    if bare in lib or path in lib or bare in ep or path in ep:
        return True
    # fortune slug pattern
    if path.startswith("/api/fortunes/") and "fortuneReading" in lib:
        slug = path.split("/")[-1]
        if slug in lib:
            return True
    return False


def datasource_hint(path: str, lib_files: list[tuple[str, str]]) -> str:
    seg = path.split("/")[2] if path.count("/") >= 2 else ""
    hits = []
    for name, text in lib_files:
        if path in text or norm_path(path) in text:
            hits.append(name)
        elif f"/api/{seg}/" in path and f"/api/{seg}/" in text and "RemoteDataSource" in name:
            if path.split("/")[-1] in text or "{" in path:
                hits.append(name)
    return ", ".join(sorted(set(hits))[:3]) or "—"


def main() -> None:
    classification = json.loads((REF / "endpoint_classification.json").read_text())
    flutter_ready = [e for e in classification if e.get("class") == "FLUTTER_READY"]
    ep = (ROOT / "mobile/lib/core/network/api_endpoints.dart").read_text()
    lib_files: list[tuple[str, str]] = []
    all_lib = ""
    for f in MOBILE.rglob("*.dart"):
        t = f.read_text(encoding="utf-8", errors="replace")
        rel = str(f.relative_to(ROOT / "mobile/lib"))
        lib_files.append((rel, t))
        all_lib += t

    test_dir = ROOT / "mobile/test"
    all_tests = ""
    for f in test_dir.rglob("*.dart"):
        all_tests += f.read_text(encoding="utf-8", errors="replace")

    rows = []
    for e in sorted(flutter_ready, key=lambda x: x["path"]):
        p = e["path"]
        methods = ", ".join(e["methods"])
        in_code = path_in_lib(p, all_lib, ep)
        ds = datasource_hint(p, [(n, t) for n, t in lib_files if "datasource" in n.lower() or "repository" in n.lower()])
        has_contract = p in all_tests or norm_path(p) in all_tests
        if in_code and ds != "—":
            status = "DATASOURCE"
        elif in_code:
            status = "ENDPOINT_TRACE"
        else:
            status = "MISSING"
        rows.append((p, methods, status, ds, "contract" if has_contract else "—"))

    by_status = defaultdict(int)
    for *_, st, _, ct in rows:
        by_status[st] += 1

    lines = [
        "# Abacus ↔ Flutter entegrasyon audit (FAZ 1)",
        "",
        "> **Üretim:** `scripts/generate_abacus_integration_audit.py` · Kaynak: `endpoint_classification.json`",
        "",
        "## Özet",
        "",
        f"| Metrik | Değer |",
        f"|--------|------:|",
        f"| `FLUTTER_READY` path | {len(rows)} |",
        f"| `DATASOURCE` (path + datasource/repository izi) | {by_status['DATASOURCE']} |",
        f"| `ENDPOINT_TRACE` (yalnızca const/grep izi) | {by_status['ENDPOINT_TRACE']} |",
        f"| `MISSING` | {by_status['MISSING']} |",
        "",
        "## Çelişki / BLOCKED (öncelik listesine göre çözülmeden tahmin yasak)",
        "",
        "| # | Konu | Kaynak A | Kaynak B | Etki |",
        "|---|------|----------|----------|------|",
        "| 1 | **BÖLÜM 22 kimlik** | `BOLUM22_MULTIGUEST_PK_GIFTBOX.md` §1: Cookie; Bearer **çalışmaz** | `AUTHENTICATION.md`, `docs/FLUTTER_ENTegrasyon_KILAVUZU.md`: mobil **JWT Bearer** | Multi-guest, gift-box, B22 PK uçları — üretimde hangi auth geçerli doğrulanmalı |",
        "| 2 | **SSE kanal sayısı** | Kılavuz §5: **5** SSE endpoint | `REALTIME.md`: PK `GET /api/pk/{matchId}/stream` + fal POST-SSE | PK SSE kılavuzda yok; mobil `pk_match_sse_service` Abacus REALTIME ile hizalı |",
        "| 3 | **E-posta doğrulama yolu** | Abacus: `POST /api/auth/email/send-verification` | Repoda ayrıca: `/api/auth/mobile-send-verification` (parity dokümanları) | İki path; Abacus FLUTTER_READY yalnız ilki — hangisi üretimde canonical netleştirilmeli |",
        "",
        "**Kural:** Yukarıdaki #1 çözülmeden BÖLÜM 22 davranışı için yeni auth varsayımı yapılmaz.",
        "",
        "## Yeni Abacus katmanları (henüz UI/repository bağlı değil)",
        "",
        "| Sınıf | Durum |",
        "|-------|--------|",
        "| `AbacusAuthRemoteDataSource` | Provider var; `AuthRemoteDataSource` / ekranlara **bağlı değil** |",
        "| `MeEntitlementsRemoteDataSource` | Yalnız `meMembershipPackageProvider` |",
        "| `UserAbacusRemoteDataSource` | Provider **yok**; kullanım **yok** |",
        "| `DreamsAbacusRemoteDataSource` | Provider **yok**; kullanım **yok** |",
        "| `SocialDiscoveryRemoteDataSource` (genişletme) | Tanış Kaynaş UI; hashtag/takım/share **UI yok** |",
        "| `GiftBoxRemoteDataSource` | Datasource var; tam UI **kısmi** |",
        "",
        "## Contract test envanteri",
        "",
        "| Alan | Dosya |",
        "|------|--------|",
        "| Auth/VIP/Dreams/Social path | `test/core/abacus/abacus_zip_contract_test.dart` |",
        "| Tanış Kaynaş | `test/features/social/social_discovery_contract_test.dart` |",
        "| Gift box | `test/features/gift_box/gift_box_contract_test.dart` |",
        "| Endpoint canonical | `test/core/network/api_endpoint_canonical_contract_test.dart` |",
        "| Live / Voice / PK / Guest / Wallet / Payment / Messaging / Games / CMS | **Dedicated contract test yok** (genel unit/widget testler var) |",
        "",
        "## Entegrasyon matrisi (örnek — tam liste aşağıda)",
        "",
        "| FEATURE | BACKEND ENDPOINT | HTTP | AUTH | FLUTTER | DURUM | TEST |",
        "|---------|------------------|------|------|---------|-------|------|",
        "| Login | `/api/auth/mobile-login` | POST | Bearer | `auth_remote_datasource.dart` | WIRED | implicit |",
        "| Refresh | `/api/auth/mobile-refresh` | POST | — | `dio_provider` + auth | WIRED | implicit |",
        "| Sessions | `/api/auth/sessions` | GET/DELETE | Bearer | `auth_remote_datasource.dart` | WIRED | partial |",
        "| Email verify (Abacus) | `/api/auth/email/send-verification` | POST | JWT | `abacus_auth_remote_datasource.dart` | **DATASOURCE ONLY** | path const |",
        "| Phone OTP | `/api/auth/phone/send-otp` | POST | — | `abacus_auth_remote_datasource.dart` | **DATASOURCE ONLY** | path const |",
        "| Verification KYC | `/api/verification` | GET/POST | — | `abacus_auth_remote_datasource.dart` | **DATASOURCE ONLY** | path const |",
        "| Membership | `/api/me/membership` | GET | Bearer | `me_entitlements_remote_datasource.dart` | **DATASOURCE ONLY** | path const |",
        "| Live guest list | `/api/live/guest/list` | GET | **BLOCKED #1** | `live_api_remote_datasource.dart` | WIRED (Bearer) | — |",
        "| Live guest actions | `/api/live/guest` | POST | **BLOCKED #1** | `live_stream_extras_datasource.dart` (grep) | PARTIAL | — |",
        "| Chat room SSE | `/api/chat/rooms/{id}/stream` | GET SSE | Bearer | `chat_room_sse_service.dart` | WIRED | sse tests |",
        "| Video stream SSE | `/api/video-streams/{id}/stream` | GET SSE | Bearer | live stream SSE | WIRED | partial |",
        "| PK match SSE | `/api/pk/{id}/stream` | GET SSE | Bearer | `pk_match_sse_service.dart` | WIRED | — |",
        "| Gift box | `/api/gift-box` | GET/POST | **BLOCKED #1** | `gift_box_remote_datasource.dart` | DATASOURCE | contract |",
        "",
        "## Tam path matrisi",
        "",
        "| Path | Methods | Durum | Datasource/Repo izi | Contract test |",
        "|------|---------|-------|----------------------|---------------|",
    ]
    for p, methods, status, ds, ct in rows:
        lines.append(f"| `{p}` | {methods} | {status} | {ds} | {ct} |")
    lines.append("")
    lines.append("## FAZ planı (bu audit sonrası)")
    lines.append("")
    lines.append("| FAZ | Kapsam | Audit sonucu |")
    lines.append("|-----|--------|--------------|")
    lines.append("| 1 | Audit | **TAMAMLANDI** (bu dosya) |")
    lines.append("| 2 | S1 Auth | EKSİK — repository/UI bağlantısı + OTP body OpenAPI MISSING |")
    lines.append("| 3 | S2 Profile/VIP | EKSİK — entitlement UI |")
    lines.append("| 4 | S4 Dreams | EKSİK — provider/UI |")
    lines.append("| 5 | S11 Social | Kısmi — Tanış var; teams/hashtag UI yok |")
    lines.append("| 6 | S3 Fortune | WIRED — `fortune_remote_datasource` + slug paths |")
    lines.append("| 7 | S6–S7 Live/Voice/PK | **BLOCKED #1** auth çelişkisi + contract test eksik |")
    lines.append("| 8–12 | S8–S18 + test/APK | Sırayla; contract önce |")
    lines.append("")

    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT} ({len(rows)} rows)")


if __name__ == "__main__":
    main()
