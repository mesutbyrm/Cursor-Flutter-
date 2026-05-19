#!/usr/bin/env bash
# Cursor Cloud Agent — idempotent ortam güncelleme betiği.
# Başarısız opsiyonel adımlar uyarı verir; Flutter bağımlılıkları zorunludur.
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

log "Flutter bağımlılıkları"
flutter pub get

if [ -f "$ROOT/api/package.json" ] && command -v npm >/dev/null 2>&1; then
  log "Node API bağımlılıkları"
  (
    cd "$ROOT/api"
    if [ -f package-lock.json ]; then
      npm ci --no-audit --no-fund
    else
      npm install --no-audit --no-fund
    fi

    log "Prisma client üretimi"
    npx prisma generate

    if [ -f .env ] && grep -q '^DATABASE_URL=' .env 2>/dev/null; then
      log "Prisma migrate (DATABASE_URL mevcut)"
      npx prisma migrate deploy || warn "Prisma migrate başarısız — PostgreSQL çalışıyor mu?"
    else
      log "Prisma migrate atlandı (.env veya DATABASE_URL yok)"
    fi
  )
else
  log "Node API atlandı (npm veya api/package.json yok)"
fi

log "Ortam güncellemesi tamamlandı"
