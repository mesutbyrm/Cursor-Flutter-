#!/usr/bin/env bash
# FAZ 0 tek ekran durum — hızlı (test çalıştırmaz).
# Kullanım: bash scripts/faz0-status.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=acceptance-tests/lib.sh
source "$ROOT/scripts/acceptance-tests/lib.sh"

apply_acceptance_credential_defaults
VERSION=$(grep -E '^version:' "$ROOT/mobile/pubspec.yaml" | awk '{print $2}')
UTC=$(date -u +"%Y-%m-%d %H:%M UTC")

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  FAZ 0 Durum — $UTC"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "APK: $VERSION"
RELEASE_NAME=$(gh release view apk-latest --repo "${GITHUB_REPOSITORY:-mesutbyrm/Cursor-Flutter-}" --json name -q .name 2>/dev/null || echo "")
if [[ -n "$RELEASE_NAME" ]]; then
  echo "apk-latest: $RELEASE_NAME"
fi
echo "İndir: https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk"
echo "Oda: cmoohrbr → cmoohrbrx00a4nt08zlkdjyil (SSE)"
echo ""

# Jeton
USER_J=0
HOST_J=0
if bootstrap_user_token 2>/dev/null; then
  USER_J=$(user_jeton_balance_from_me "$USER_TOKEN")
fi
if bootstrap_host_token 2>/dev/null; then
  HOST_J=$(user_jeton_balance_from_me "$HOST_TOKEN")
fi

echo "── Hesaplar ──"
echo "  USER: $USER_EMAIL — jeton=$USER_J"
echo "  HOST: $HOST_EMAIL — jeton=$HOST_J"
if acceptance_admin_secrets_configured; then
  echo "  ADMIN secret: yapılandırılmış (top-up mümkün)"
else
  echo "  ADMIN secret: yok"
fi
echo ""

# Son verify raporu
if [[ -f "$ROOT/docs/FAZ0_VERIFY_REPORT.md" ]]; then
  last=$(grep '^\*\*Tarih:\*\*' "$ROOT/docs/FAZ0_VERIFY_REPORT.md" | head -1 | sed 's/\*\*Tarih:\*\* //')
  result=$(grep '^\*\*Sonuç:\*\*' "$ROOT/docs/FAZ0_VERIFY_REPORT.md" | head -1 | sed 's/\*\*Sonuç:\*\* \*\*//;s/\*\*$//')
  echo "── Son otomatik verify ──"
  echo "  Tarih: ${last:-bilinmiyor}"
  echo "  Sonuç: ${result:-bilinmiyor}"
  echo ""
fi

# Blokerler
BLOCKERS=0
echo "── Blokerler ──"
if [[ "$USER_J" -lt 10 && "$HOST_J" -lt 10 ]]; then
  echo "  ⛔ Jeton: USER ve HOST < 10 — M5/M7 bekliyor"
  echo "     Admin: https://canlifal.com/admin → $USER_EMAIL"
  BLOCKERS=$((BLOCKERS + 1))
fi
echo "  ⏸  M5: Android cihaz testi (kullanıcı)"
echo "  ⏸  M7: song-request HTTP 200 (jeton ≥10)"
echo "  ⏸  A9: M5 PASS → FAZ 0 kapat"
echo ""

echo "── Tamamlanan (kod) ──"
echo "  ✅ M1–M12 (!istek/ANR/SSE) — 1.0.266+302"
echo "  ✅ Müzik isteği ANR — 1.0.284+320"
echo "  ✅ PK davet/bildirim/oda geçişi — 1.0.285+321"
echo "  ✅ Push/bildirim oda teardown — 1.0.286+322"
echo "  ✅ PK kabul teardown — 1.0.287+323"
echo "  ✅ Müzik arama CI retry (502) — scripts"
echo "  ✅ API müzik 6/6 + voice_hub + 15 faz test"
echo ""
echo "  📋 Kod otomasyonu tamam — agent beklemesi: jeton + M5 cihaz"
echo ""

if [[ "$BLOCKERS" -gt 0 ]]; then
  echo "── Sonraki adım ──"
  echo "  bash scripts/faz0-handoff.sh"
  echo "  bash scripts/wait-for-jeton.sh 10 3600  # jeton sonrası otomatik M7"
else
  echo "── Sonraki adım ──"
  echo "  bash scripts/m5-preflight.sh && docs/M5_DEVICE_TEST_CHECKLIST.md"
fi
echo ""
echo "══ AGENT DURUMU ══"
echo "FAZ1–11 otomatik PASS (15 test) | FAZ12 otomatik 4/4"
echo "Tek bloker: jeton≥10 + M5 cihaz — bash scripts/faz0-next.sh"
