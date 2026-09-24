#!/usr/bin/env bash
# Cursor Cloud Agent — ortam güncelleme (her koşulda exit 0).
set +e
set +u
set +o pipefail 2>/dev/null || true

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 0

FAILED=0

log() { printf '==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }

run_step() {
  local name="$1"
  local timeout_sec="${2:-120}"
  shift 2
  if command -v timeout >/dev/null 2>&1; then
    if timeout "$timeout_sec" "$@"; then
      log "OK: $name"
      return 0
    fi
  elif "$@"; then
    log "OK: $name"
    return 0
  fi
  warn "$name atlandı veya zaman aşımı ($timeout_sec sn)"
  FAILED=$((FAILED + 1))
  return 0
}

for d in /opt/flutter/bin "${HOME}/flutter/bin" "${HOME}/.nvm/versions/node/current/bin" /usr/local/bin; do
  [ -d "$d" ] && PATH="$d:${PATH:-}"
done
export PATH

log "Canlifal ortam güncellemesi (Cursor)"

# Flutter SDK kurulu değilse kontrol et ve yükle
if ! command -v flutter >/dev/null 2>&1; then
  log "Flutter SDK yükleniyor..."
  if [ -x "$(command -v git)" ] && [ -x "$(command -v curl)" ]; then
    FLUTTER_VERSION="$(cat "$ROOT/mobile/.flutter-version" 2>/dev/null || echo 'stable')"
    FLUTTER_DIR="${HOME}/flutter"

    # Eğer Flutter repo varsa, sadece upgrade et
    if [ -d "$FLUTTER_DIR/.git" ]; then
      run_step "Flutter upgrade" 300 bash -c "cd '$FLUTTER_DIR' && git fetch && git checkout $FLUTTER_VERSION"
    else
      # Yoksa clone et
      run_step "Flutter clone" 300 bash -c "git clone -b $FLUTTER_VERSION --depth 1 https://github.com/flutter/flutter.git '$FLUTTER_DIR' 2>/dev/null || true"
    fi

    # PATH'e ekle
    export PATH="$FLUTTER_DIR/bin:$PATH"
  else
    warn "Flutter SDK kurulumu için git ve curl gerekli — atlandı"
    FAILED=$((FAILED + 1))
  fi
fi

if [ -f "$ROOT/mobile/pubspec.yaml" ] && command -v flutter >/dev/null 2>&1; then
  run_step "Flutter pub get" 90 bash -c "cd '$ROOT/mobile' && flutter pub get"
else
  warn "Flutter yok veya mobile/ yok — atlandı"
  FAILED=$((FAILED + 1))
fi

if [ -f "$ROOT/api/package.json" ] && command -v npm >/dev/null 2>&1; then
  run_step "npm install (api)" 60 bash -c "cd '$ROOT/api' && (npm ci --no-audit --no-fund 2>/dev/null || npm install --no-audit --no-fund) || true"
  if command -v npx >/dev/null 2>&1; then
    run_step "prisma generate" 45 bash -c "cd '$ROOT/api' && npx prisma generate || true"
  fi
else
  log "api/ npm atlandı (isteğe bağlı)"
fi

log "Ortam hazır (uyarı sayısı: $FAILED)"
exit 0
