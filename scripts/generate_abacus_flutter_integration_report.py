#!/usr/bin/env python3
"""Compare mobile/lib HTTP usage vs backend-reference/canlifal_flutter_paketi/openapi.yaml."""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REF = ROOT / "backend-reference/canlifal_flutter_paketi"
OUT = ROOT / "docs/ABACUS_FLUTTER_INTEGRATION_REPORT.md"


def norm(p: str) -> str:
    p = re.sub(r"\$\{[^}]+\}", "*", p)
    p = re.sub(r"\{[^}]+\}", "*", p)
    return p.split("?")[0]


def main() -> None:
    import yaml

    openapi = yaml.safe_load((REF / "openapi.yaml").read_text(encoding="utf-8"))
    paths = openapi.get("paths", {})
    method_map = {
        norm(p): {m.upper() for m in ms if m.upper() in ("GET", "POST", "PUT", "PATCH", "DELETE")}
        for p, ms in paths.items()
    }

    ep_text = (ROOT / "mobile/lib/core/network/api_endpoints.dart").read_text(encoding="utf-8")
    const_map = dict(re.findall(r"static const (\w+) = '(/api/[^']+)'", ep_text))

    issues: list[tuple] = []
    lib = ROOT / "mobile/lib"
    for f in lib.rglob("*.dart"):
        text = f.read_text(encoding="utf-8", errors="replace")
        for m in re.finditer(r"safe(Get|Post|Put|Patch|Delete)<[^>]*>\(\s*([^,\)]+)", text):
            method = m.group(1).upper()
            arg = m.group(2).strip()
            path = None
            if arg.startswith(("'", '"')):
                path = arg.strip("'\"")
            elif arg.startswith("ApiEndpoints."):
                key = arg.replace("ApiEndpoints.", "").split(".")[0]
                path = const_map.get(key)
            if not path or not path.startswith("/api/"):
                continue
            n = norm(path)
            allowed = method_map.get(n)
            rel = str(f.relative_to(ROOT / "mobile"))
            if allowed is None:
                issues.append(("NO_OPENAPI", method, path, rel))
            elif method not in allowed:
                issues.append(("METHOD", method, path, rel, sorted(allowed)))

    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    verified = [
        "POST /api/auth/mobile-login",
        "POST /api/auth/mobile-refresh",
        "GET /api/me",
        "GET /api/wallet",
        "POST /api/fortune-access/check",
        "GET /api/fortune-access/ip-status",
        "GET /api/referral",
        "GET /api/chat/rooms/{roomId}/stream",
        "GET /api/video-streams/{streamId}/stream",
        "GET /api/notifications/stream",
        "GET /api/pk/{matchId}/stream",
        "GET /api/room/{sessionId}/stream",
        "GET /api/fortune-tellers/sessions/stream",
        "POST /api/trtc/usersig",
        "POST /api/devices/fcm",
        "GET /api/mobile/config",
    ]
    lines = [
        "# Abacus backend ↔ Flutter entegrasyon raporu",
        "",
        f"> **Generated:** {ts} (`scripts/generate_abacus_flutter_integration_report.py`)",
        "",
        "**Kaynak önceliği:** `backend-reference/canlifal_flutter_paketi/` (Abacus paketi).",
        "`backend-reference/` dosyaları değiştirilmedi; ZIP yedek olarak duruyor.",
        "",
        "## Özet",
        "",
        f"| OpenAPI path | {len(paths)} |",
        f"| endpoints_index handler | {len(json.loads((REF/'endpoints_index.json').read_text()))} |",
        f"| Tarama: OpenAPI'de yok | {sum(1 for i in issues if i[0]=='NO_OPENAPI')} |",
        f"| Tarama: HTTP method uyumsuz | {sum(1 for i in issues if i[0]=='METHOD')} |",
        "",
        "## Doğrulanan kritik uçlar (OpenAPI)",
        "",
        *[f"- `{v}`" for v in verified],
        "",
        "## HTTP method uyumsuzlukları (kalan)",
        "",
    ]
    method_issues = [i for i in issues if i[0] == "METHOD"]
    if method_issues:
        lines.append("| Method (kod) | Path | Dosya | OpenAPI |")
        lines.append("|--------------|------|-------|---------|")
        for row in method_issues:
            lines.append(
                f"| {row[1]} | `{row[2]}` | `{row[3]}` | {', '.join(row[4])} |"
            )
    else:
        lines.append("_Kalan method uyumsuzluğu yok (safe* taraması)._")

    lines += [
        "",
        "## Komut",
        "",
        "```bash",
        "python3 scripts/generate_abacus_flutter_integration_report.py",
        "cd mobile && flutter analyze",
        "```",
        "",
    ]
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
