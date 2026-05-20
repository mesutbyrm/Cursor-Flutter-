#!/usr/bin/env bash
# Cursor Cloud Agent — idempotent ortam güncelleme betiği.
# ÖNEMLİ: Bu betik her zaman 0 ile çıkmalı; aksi halde Cursor "Update script failed" gösterir.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FAILED=0

log() { printf '==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }

run_step() {
  local name="$1"
  shift
  if "$@"; then
    log "OK: $name"
    return 0
  fi
  warn "$name başarısız (devam ediliyor)"
  FAILED=$((FAILED + 1))
  return 0
}

ensure_tool_paths() {
  local d
  for d in \
    /opt/flutter/bin \
    "${HOME}/flutter/bin" \
    "${HOME}/development/flutter/bin" \
    "${HOME}/.nvm/versions/node/current/bin" \
    /usr/local/bin; do
    if [ -d "$d" ]; then
      PATH="$d:${PATH:-}"
    fi
  done
  export PATH
}

ensure_tool_paths

log "Canlifal ortam güncellemesi başlıyor"

if [ -f "$ROOT/mobile/pubspec.yaml" ]; then
  if command -v flutter >/dev/null 2>&1; then
    run_step "Flutter pub get" bash -c "cd '$ROOT/mobile' && flutter pub get"
  else
    warn "Flutter yok — mobile bağımlılıkları atlandı (APK derlemesi için Flutter gerekir)"
    FAILED=$((FAILED + 1))
  fi
else
  warn "mobile/pubspec.yaml bulunamadı"
  FAILED=$((FAILED + 1))
fi

if [ -f "$ROOT/api/package.json" ] && command -v npm >/dev/null 2>&1; then
  run_step "npm install (api)" bash -c "
    set -u
    cd '$ROOT/api'
    if [ -f package-lock.json ]; then
      npm ci --no-audit --no-fund
    else
      npm install --no-audit --no-fund
    fi
  "
  if command -v npx >/dev/null 2>&1; then
    run_step "prisma generate" bash -c "cd '$ROOT/api' && npx prisma generate"
    if [ -f "$ROOT/api/.env" ] && grep -q '^DATABASE_URL=' "$ROOT/api/.env" 2>/dev/null; then
      run_step "prisma migrate deploy" bash -c "cd '$ROOT/api' && npx prisma migrate deploy"
    else
      log "Prisma migrate atlandı (api/.env veya DATABASE_URL yok)"
    fi
  fi
elif [ -f "$ROOT/api/package.json" ]; then
  warn "npm yok — api/ bağımlılıkları atlandı"
  FAILED=$((FAILED + 1))
fi

if [ "$FAILED" -eq 0 ]; then
  log "Ortam güncellemesi tamamlandı"
else
  log "Ortam güncellemesi tamamlandı ($FAILED isteğe bağlı adım atlandı veya başarısız)"
fi

exit 0
