#!/usr/bin/env bash
# ApiEndpoints envanter — kullanım sayısı (lib + test). Endpoint silme kararı için ön rapor.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EP="$ROOT/mobile/lib/core/network/api_endpoints.dart"
OUT="$ROOT/docs/API_ENDPOINT_INVENTORY.json"
LIB="$ROOT/mobile/lib"
TEST="$ROOT/mobile/test"

export ROOT
python3 <<'PY'
import json, re, subprocess, os
root = os.environ["ROOT"]
ep_file = os.path.join(root, "mobile/lib/core/network/api_endpoints.dart")
text = open(ep_file, encoding="utf-8").read()
# static const name = '...'
consts = re.findall(r"static const (\w+) = '([^']+)'", text)
# static String name( or static const with function — skip for brevity
funcs = re.findall(r"static String (\w+)\(", text)
entries = [{"name": n, "path": p, "kind": "const"} for n, p in consts]
entries += [{"name": n, "path": None, "kind": "function"} for n in funcs]

def rg_count(pattern):
    try:
        r = subprocess.run(
            ["rg", "-l", pattern, "mobile/lib", "mobile/test"],
            cwd=root, capture_output=True, text=True, timeout=120,
        )
        files = [f for f in r.stdout.strip().split("\n") if f]
        return len(files)
    except Exception:
        return -1

for e in entries:
    name = e["name"]
    e["usage_files"] = rg_count(f"ApiEndpoints.{name}")
    if e["path"]:
        path = e["path"].split("(")[0]
        e["string_ref_files"] = rg_count(path)
    else:
        e["string_ref_files"] = 0

out = {
    "generated": "phase2",
    "total_const": len(consts),
    "total_function": len(funcs),
    "zero_usage_const": [e for e in entries if e["kind"] == "const" and e["usage_files"] == 0],
    "entries_sample": entries[:50],
}
out_path = os.path.join(root, "docs/API_ENDPOINT_INVENTORY.json")
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2, ensure_ascii=False)
print(f"Wrote {out_path} ({len(consts)} const, {len(funcs)} fn)")
print(f"Zero ApiEndpoints.* usage: {len(out['zero_usage_const'])} (manual review required)")
PY
