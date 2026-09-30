#!/usr/bin/env python3
"""Backend (canlifal-backend snapshot) vs Flutter /api/ literals — envanter özeti."""
from __future__ import annotations

import re
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BE = ROOT / "canlifal-backend/nextjs_space/app/api"
MOB = ROOT / "mobile/lib"
OUT = ROOT / "docs/BACKEND_FRONTEND_UYUMLULUK_ENVANTER.md"


def be_path(f: Path) -> str:
    rel = f.relative_to(BE).as_posix().replace("/route.ts", "")
    parts = []
    for p in rel.split("/"):
        parts.append("*" if p.startswith("[") and p.endswith("]") else p)
    return "/api/" + "/".join(parts)


def norm_flutter(p: str) -> str:
    p = p.split("?")[0]
    return re.sub(r"\$\{[^}]+\}", "*", p)


def main() -> None:
    be_routes: list[tuple[str, list[str]]] = []
    for f in sorted(BE.rglob("route.ts")):
        text = f.read_text(encoding="utf-8", errors="replace")
        methods = [
            m
            for m in ("GET", "POST", "PUT", "PATCH", "DELETE")
            if re.search(rf"export\s+async\s+function\s+{m}\b", text)
        ]
        if methods:
            be_routes.append((be_path(f), methods))

    fl_paths: set[str] = set()
    for f in MOB.rglob("*.dart"):
        t = f.read_text(encoding="utf-8", errors="replace")
        for p in re.findall(r"['\"](/api/[^'\"$]+)['\"]", t):
            fl_paths.add(norm_flutter(p))

    be_set = {p for p, _ in be_routes}

    def might_exist(fp: str) -> bool:
        fp_parts = fp.strip("/").split("/")
        for bp in be_set:
            bp_parts = bp.strip("/").split("/")
            if len(fp_parts) != len(bp_parts):
                continue
            if all(b == "*" or a == b for a, b in zip(fp_parts, bp_parts)):
                return True
        return False

    no_match = sorted(p for p in fl_paths if not might_exist(p))
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    lines = [
        "# Backend ↔ Flutter envanter (otomatik özet)",
        "",
        f"> Üretim: `{ts}` · Backend snapshot: `canlifal-backend/nextjs_space`",
        "",
        f"- **Backend route dosyası:** {len(be_routes)}",
        f"- **Flutter `/api/` literal:** {len(fl_paths)}",
        f"- **Ana sitede eşleşmeyen Flutter path (kaba):** {len(no_match)}",
        "",
        "## Ana sitede route dosyası bulunmayan Flutter path'ler",
        "",
        "*(Games backend, gateway veya henüz eklenmemiş uç olabilir.)*",
        "",
    ]
    for p in no_match:
        lines.append(f"- `{p}`")
    lines.append("")
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
