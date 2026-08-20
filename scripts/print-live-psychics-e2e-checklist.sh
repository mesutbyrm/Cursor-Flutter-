#!/usr/bin/env bash
# Canlı Falcılar — cihaz E2E kontrol listesi (manuel test).
set -euo pipefail

cat <<'EOF'
=== Canlı Falcılar — Manuel E2E Checklist ===
İki cihaz veya danışan + falcı hesabı gerekir.
APK: https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk

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

Detay: docs/LIVE_PSYCHICS_REMAINING.md
EOF
