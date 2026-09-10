#!/usr/bin/env bash
# Flutter api_endpoints.dart ↔ backend-docs/openapi.json parity özeti.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OPENAPI="$ROOT/backend-docs/openapi.json"
ENDPOINTS_DART="$ROOT/mobile/lib/core/network/api_endpoints.dart"
if [[ ! -f "$OPENAPI" ]]; then
  echo "MISSING: $OPENAPI"
  exit 1
fi
python3 << PY
import json, re
from pathlib import Path

root = Path("$ROOT")
dart = (root / "mobile/lib/core/network/api_endpoints.dart").read_text()
openapi = json.loads((root / "backend-docs/openapi.json").read_text())
api_paths = set(openapi.get("paths", {}).keys())

# Static /api/... strings from Dart
raw = set(re.findall(r"['\"](/api/[^'\"$]+)['\"]", dart))
# Builders: '/api/chat/rooms/\$roomId/...' -> pattern
for m in re.findall(r"return\s+['\"](/api/[^'\"]+)['\"]", dart):
    raw.add(m.split("\$")[0].rstrip("/") + "/*")

def norm(p):
    p = re.sub(r"\$\{[^}]+\}", "*", p)
    p = re.sub(r"\{[^}]+\}", "*", p)
    return p

api_norm = {norm(p): p for p in api_paths}
dart_norm = {norm(p): p for p in raw}

matched = [dart_norm[k] for k in dart_norm if k in api_norm]
flutter_only = [dart_norm[k] for k in dart_norm if k not in api_norm]

print("=== Abacus OpenAPI ↔ Flutter parity ===")
print(f"OpenAPI paths: {len(api_paths)}")
print(f"Flutter literal paths (approx): {len(raw)}")
print(f"Normalized matches: {len(matched)}")
print(f"Flutter-only (verify manually): {len(flutter_only)}")
if flutter_only:
    print("\nSample flutter-only (first 15):")
    for p in sorted(flutter_only)[:15]:
        print(f"  {p}")
PY
