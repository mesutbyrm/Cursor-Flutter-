#!/usr/bin/env bash
# Psychic TRTC P0 — iki cihaz kabul checklist (manuel test; agent çalıştırmaz).
set -euo pipefail

APK_URL="https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk"
VERSION="?"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "${ROOT}/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "${ROOT}/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

PREREQ_NOTE=""
if [[ -x "${ROOT}/scripts/psychic-p0-prereqs.sh" ]]; then
  PREREQ_OUT=$("${ROOT}/scripts/psychic-p0-prereqs.sh" 2>&1 || true)
  if echo "$PREREQ_OUT" | grep -q 'jeton=0'; then
    PREREQ_NOTE="
⚠️  ÖNKOŞUL: Danışan jeton=0 — seans başlamaz.
    bash scripts/admin-jeton-cheatsheet.sh
    Sonra: bash scripts/psychic-p0-prereqs.sh (tekrar)
"
  elif echo "$PREREQ_OUT" | grep -q 'Önkoşullar hazır'; then
    PREREQ_NOTE="
✅ Önkoşullar OK (APK + giriş + jeton)
"
  fi
  if echo "$PREREQ_OUT" | grep -q 'Falcı listesinde DEĞİL'; then
    PREREQ_NOTE="${PREREQ_NOTE}
⚠️  Host hesabı falcı listesinde değil — onaylı falcı hesabı gerekir
    bash scripts/list-production-tellers.sh
    docs/PSYCHIC_TELLER_STATUS.md
"
  fi
fi

cat <<EOF
╔══════════════════════════════════════════════════════════════════╗
║  Psychic TRTC P0 — cihaz kabul (${VERSION})                    ║
╚══════════════════════════════════════════════════════════════════╝

APK: ${APK_URL}
${PREREQ_NOTE}
Gereksinim: 2 fiziksel cihaz VEYA 2 hesap (danışan + falcı)

Hesaplar (docs/KULLANICI_TEST_KILAVUZU.md):
  Danışan: cursor.test.1786235468@mailinator.com
  Falcı:   ONAYLI FALCI (host değil — admin panel hesabı)
           bash scripts/list-production-tellers.sh
  Şifre:   CursorTest!1786235468 (danışan) · falcı hesabına göre

Her adımda kontrol: çift yönlü A/V · senkron · rejoin yok · duplicate stream yok

┌─────────────────────────────────────────────────────────────────┐
│ Zaman / senaryo          │ PASS │ FAIL │ Not                      │
├─────────────────────────────────────────────────────────────────┤
│ T0 join                  │ [ ]  │ [ ]  │ A/V anında her iki taraf │
│ T+1s                     │ [ ]  │ [ ]  │                          │
│ T+3s                     │ [ ]  │ [ ]  │                          │
│ T+5s (KRİTİK)            │ [ ]  │ [ ]  │ Eski bug ~5 sn donma     │
│ T+10s                    │ [ ]  │ [ ]  │                          │
│ T+30s                    │ [ ]  │ [ ]  │                          │
│ T+60s                    │ [ ]  │ [ ]  │                          │
│ WiFi ↔ mobil data        │ [ ]  │ [ ]  │ Kontrollü reconnect      │
│ Oturum A → B → A         │ [ ]  │ [ ]  │ Eski stream kapanır      │
│ Arka plan → ön plan      │ [ ]  │ [ ]  │ Gereksiz rejoin yok      │
└─────────────────────────────────────────────────────────────────┘

Genel akış (opsiyonel — LIVE_PSYCHICS_REMAINING.md):
  [ ] Danışan happy path (liste → görüşme → bitir → yorum)
  [ ] Falcı happy path (kabul → timer → bitir)
  [ ] Push kabul (arka planda bildirim)

Sonuç (birini işaretle):
  [ ] Psychic P0 PASS — RELEASE adayı
  [ ] Psychic P0 FAIL — logcat / ekran kaydı + adım notu

Detay: docs/LIVE_PSYCHICS_REMAINING.md
EOF
