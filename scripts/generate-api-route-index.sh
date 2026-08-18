#!/usr/bin/env bash
# backend-docs/endpoints_index.json → docs/BACKEND_API_ROUTE_INDEX.md
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" << 'PY'
import json, collections, sys
from pathlib import Path
root = Path(sys.argv[1])
idx = json.loads((root / "backend-docs/endpoints_index.json").read_text())
by_tag = collections.defaultdict(list)
for e in idx:
    tag = e.get("tag") or "untagged"
    by_tag[tag].append(f"{e['method']:6} {e['path']}")
out = root / "docs/BACKEND_API_ROUTE_INDEX.md"
lines = [
    "# Backend API route index (OpenAPI / endpoints_index)",
    "",
    "**Kaynak:** `backend-docs/endpoints_index.json`",
    "**Üretim:** `bash scripts/generate-api-route-index.sh`",
    "**Not:** `nextjs_space/app/api/**/route.ts` repoda yok; A6 yedeği.",
    "",
    f"**Toplam:** {len(idx)} method-endpoint, {len(by_tag)} tag",
    "",
]
for tag in sorted(by_tag.keys(), key=str.lower):
    routes = sorted(by_tag[tag])
    lines.append(f"## `{tag}` ({len(routes)})")
    lines.append("")
    for r in routes[:80]:
        lines.append(f"- `{r}`")
    if len(routes) > 80:
        lines.append(f"- … +{len(routes) - 80} daha")
    lines.append("")
out.write_text("\n".join(lines))
print(f"Wrote {out} ({len(idx)} entries, {len(by_tag)} tags)")
PY
