#!/usr/bin/env bash
# Play Store Console — yükleme öncesi kontrol listesi (agent, cihaz sonucu sonra).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOBILE="$ROOT/mobile"
VERSION="?"
if [[ -f "$MOBILE/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "$MOBILE/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  Play Store Console checklist (${VERSION})                        ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Cihaz P0/P1 sonucu: SONRA · Bu liste yükleme günü için hazırlık."
echo ""

bash "$ROOT/scripts/play-aab-readiness.sh" 2>&1 | sed 's/^/  /'
echo ""

cat <<'EOF'
── Play Console adımları ──

  [ ] Google Play Console → uygulama seç / oluştur
  [ ] App access: test hesapları ekle
        cursor.test.1786235468@mailinator.com
        cursor.host.1786235468@mailinator.com
        Şifre: CursorTest!1786235468
  [ ] Data safety formu
        bash scripts/print-play-data-safety-summary.sh
        docs/PLAY_STORE_PRODUCTION_ACCESS.md
  [ ] Foreground service declaration
        bash scripts/print-play-foreground-service-declaration.sh
        docs/PLAY_FOREGROUND_SERVICE_DECLARATION.md
  [ ] Content rating anketi
        bash scripts/print-play-content-rating-summary.sh
  [ ] Store listing (açıklama + grafikler)
        bash scripts/print-play-store-listing.sh
  [ ] Release-signed AAB yükle (Closed test track)
        bash scripts/print-ci-aab-steps.sh
  [ ] Internal/Closed testers davet et
  [ ] Production access başvurusu (14 gün closed test sonrası)

── AAB üretimi ──
  CI: GitHub Actions → Build release AAB (ANDROID_KEYSTORE_* secrets)
        bash scripts/print-ci-aab-steps.sh
  Yerel: bash scripts/build-play-aab.sh
  App access metni: bash scripts/print-play-console-app-access.sh

── CI secret (GitHub) ──
  ANDROID_KEYSTORE_BASE64
  ANDROID_KEYSTORE_PASSWORD
  ANDROID_KEY_ALIAS
  ANDROID_KEY_PASSWORD

Rehber: docs/P2_PLAY_STORE_START.md · docs/PLAY_STORE_PRODUCTION_ACCESS.md
EOF
