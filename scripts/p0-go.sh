#!/usr/bin/env bash
# Psychic P0 — GO ekranı: canlı durum + hesaplar + başlat komutları.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

bash "$ROOT/scripts/print-p0-live-status.sh"

cat <<'EOF'

╔══════════════════════════════════════════════════════════════════╗
║  P0 GO — 2 telefon hazır mı?                                      ║
╚══════════════════════════════════════════════════════════════════╝

Hesaplar (aynı şifre):
  Danışan → cursor.test.1786235468@mailinator.com
  Falcı   → cursor.host.1786235468@mailinator.com
  Şifre   → CursorTest!1786235468

Kritik: T+5 saniyede video/ses DONMAMALI.

Doğrulama (isteğe bağlı):
  bash scripts/p0-ready.sh

Başlat:
  bash scripts/user-test-start.sh p0      # checklist yazdır
  bash scripts/psychic-p0-all.sh          # önkoşul + checklist

Sonuç:
  PASS → bash scripts/on-p0-pass.sh
  FAIL → bash scripts/on-p0-fail.sh "hangi adım"

EOF
