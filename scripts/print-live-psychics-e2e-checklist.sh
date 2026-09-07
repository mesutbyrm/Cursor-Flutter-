#!/usr/bin/env bash
# Canlı Falcılar — tam E2E kontrol listesi (P0 freeze sonrası / P1).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APK_URL="https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk"
VERSION="?"
if [[ -f "${ROOT}/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "${ROOT}/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

cat <<EOF
=== Canlı Falcılar — Manuel E2E Checklist (${VERSION}) ===

ÖNCE: Psychic P0 (T+5s TRTC donma) — bash scripts/psychic-p0-checklist.sh
Bu liste: P0 PASS sonrası tam akış (P1)

İki cihaz veya danışan + falcı hesabı gerekir.
APK: ${APK_URL}

[ ] 0. TRTC freeze (P0 — zorunlu)
    T+5s donma yok · WiFi↔mobil · oturum A→B→A · arka plan
    → bash scripts/psychic-p0-checklist.sh

[ ] 1. Danışan happy path
    Liste → profil → randevu (10 dk) → bekleme → falcı kabul → reklam → TRTC → chat → uzat → bitir → yıldız/yorum

[ ] 2. Falcı happy path
    Dashboard çevrimiçi → gelen diyalog/SSE → kabul → timer → süre ekle → bitir → bahşiş

[ ] 3. Red / iptal / timeout
    Falcı red / danışan iptal / 180 sn timeout → jeton iade snackbar + cüzdan

[ ] 4. Push (arka plan)
    Bildirim Kabul → falcı session; danışan push → ad-transition

[ ] 5. SSE kopma
    Uçak modu 30 sn → oda banner «Yenile» → mesaj/timer senkronu

[ ] 6. TRTC arka plan/ön plan
    Görüşme sırasında uygulama arka plana → geri dön → ses/görüntü devam

[ ] 7. Staff muafiyeti
    Staff hesabı: jeton düşülmeden seans + uzatma

[ ] 8. Deep link / restore
    Görüşme sırasında uygulamayı öldür → /canli-falcilar/{id}/session → diskten devam

Detay: docs/LIVE_PSYCHICS_REMAINING.md · docs/KULLANICI_TEST_KILAVUZU.md
EOF
