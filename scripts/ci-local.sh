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

echo "=== Flutter (dart analyze lib) ==="
if command -v flutter >/dev/null 2>&1; then
  FLUTTER=flutter
elif [[ -x /tmp/flutter/bin/flutter ]]; then
  FLUTTER=/tmp/flutter/bin/flutter
else
  echo "Flutter bulunamadı. PATH'e ekleyin veya: git clone -b stable https://github.com/flutter/flutter.git /tmp/flutter"
  exit 1
fi

(
  cd mobile
  "$FLUTTER" pub get
  set +e
  "$FLUTTER" analyze lib
  ec=$?
  set -e
  if [[ "$ec" -eq 3 ]]; then
    echo "dart analyze: ERROR seviyesinde sorun var (exit $ec)"
    exit 1
  fi
  echo "dart analyze tamam (exit $ec — yalnızca uyarı/info olabilir)"
)

echo ""
echo "Yerel CI tamam. GitHub'da kırmızı X için: docs/GITHUB_ACTIONS_CI.md"
