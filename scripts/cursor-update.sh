#!/usr/bin/env bash
# Cursor Cloud Agent — idempotent ortam güncelleme betiği.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export PATH="/opt/flutter/bin:${HOME}/.nvm/versions/node/current/bin:${PATH:-}"

log() { printf '==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }

log "Canlifal ortam güncellemesi başlıyor"

if ! command -v flutter >/dev/null 2>&1; then
  warn "Flutter bulunamadı (/opt/flutter/bin PATH'e eklenmeli)"
  exit 1
fi

if [ -f "$ROOT/mobile/pubspec.yaml" ]; then
  log "Flutter bağımlılıkları (mobile/)"
  (cd "$ROOT/mobile" && flutter pub get)
elif [ -f "$ROOT/pubspec.yaml" ]; then
  log "Flutter bağımlılıkları (kök — legacy)"
  flutter pub get
else
  warn "pubspec.yaml bulunamadı"
  exit 1
fi

if [ -f "$ROOT/api/package.json" ] && command -v npm >/dev/null 2>&1; then
  log "Node API bağımlılıkları"
  (
    cd "$ROOT/api"
    if [ -f package-lock.json ]; then
      npm ci --no-audit --no-fund
    else
      npm install --no-audit --no-fund
    fi
    npx prisma generate
    if [ -f .env ] && grep -q '^DATABASE_URL=' .env 2>/dev/null; then
      npx prisma migrate deploy || warn "Prisma migrate başarısız"
    else
      log "Prisma migrate atlandı (.env veya DATABASE_URL yok)"
    fi
  )
fi

log "Ortam güncellemesi tamamlandı"
