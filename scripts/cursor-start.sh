#!/usr/bin/env bash
# Ortam başlangıcı — hata verse bile agent çalışmaya devam etsin.
set +e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -d "$ROOT/api" ]; then
  cd "$ROOT/api" || exit 0
  if [ ! -f .env ] && [ -f .env.example ]; then
    cp -n .env.example .env 2>/dev/null || cp .env.example .env 2>/dev/null || true
  fi
fi

exit 0
