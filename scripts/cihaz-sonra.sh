#!/usr/bin/env bash
# Cihaz testleri sonraya bırakıldı — ne zaman hazır olursanız bu akış.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APK_URL="https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk"

VERSION="?"
if [[ -f "${ROOT}/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "${ROOT}/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

cat <<EOF
╔══════════════════════════════════════════════════════════════════╗
║  Cihaz testleri — SONRA (${VERSION})                              ║
╚══════════════════════════════════════════════════════════════════╝

Sonuç kaydı şimdi değil — test bitince aşağıdaki komutlar.

APK: ${APK_URL}

Hesaplar:
  Danışan → cursor.test.1786235468@mailinator.com
  Falcı   → cursor.host.1786235468@mailinator.com
  Şifre   → CursorTest!1786235468

── Sıra ──
  1) bash scripts/basla.sh
  2) bash scripts/user-test-start.sh p0     # Psychic P0 (T+5s donma yok)
  3) bash scripts/on-p0-pass.sh             # veya on-p0-fail.sh
  4) bash scripts/p1-go.sh                  # platform 2-cihaz
  5) bash scripts/on-p1-pass.sh
  6) bash scripts/on-release-ready-candidate.sh

Agent paralel (şimdi): bash scripts/kalan-isler-agent.sh
P2 prep GO:            bash scripts/p2-prep-go.sh

Kayıt: docs/USER_DEVICE_TEST_LOG.md
EOF

bash "$ROOT/scripts/print-p0-live-status.sh" 2>/dev/null | grep -E 'APK|jeton|Falcı listesinde|Falcı probe' || true
