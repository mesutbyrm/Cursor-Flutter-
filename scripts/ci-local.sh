#!/usr/bin/env bash
# Yerel CI — GitHub Actions ile aynı kontroller (faturalandırma olmadan).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== API (TypeScript) ==="
(
  cd api
  export DATABASE_URL="${DATABASE_URL:-postgresql://ci:ci@localhost:5432/ci?schema=public}"
  npm ci
  npx prisma generate
  npm run build
)

echo "=== Flutter (dart analyze lib — yalnızca ERROR engeller) ==="
chmod +x scripts/dart-analyze-gate.sh
bash scripts/dart-analyze-gate.sh

echo ""
echo "Yerel CI tamam. GitHub'da kırmızı X için: docs/GITHUB_ACTIONS_CI.md"
