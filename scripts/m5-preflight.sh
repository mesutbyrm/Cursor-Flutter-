#!/usr/bin/env bash
# M5 öncesi otomatik kontrol — API müzik fazı + jeton + APK sürümü.
# Kullanım: bash scripts/m5-preflight.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=acceptance-tests/lib.sh
source "$ROOT/scripts/acceptance-tests/lib.sh"

apply_acceptance_credential_defaults
export MUSIC_PROBE_ROOM="${MUSIC_PROBE_ROOM:-cmoohrbr}"

VERSION=$(grep -E '^version:' "$ROOT/mobile/pubspec.yaml" | awk '{print $2}')
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  M5 Preflight — müzik / !istek cihaz testi öncesi        ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "APK hedef sürüm: $VERSION"
echo "Oda: $MUSIC_PROBE_ROOM"
echo "APK: https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk"
echo ""

FAIL=0

echo "── 1/3 API müzik kabul testleri ──"
if bash "$ROOT/scripts/run-music-acceptance.sh"; then
  echo "✅ API müzik: OK"
else
  echo "❌ API müzik: BAŞARISIZ"
  FAIL=1
fi
echo ""

echo "── 2/3 Jeton bakiyesi ──"
if bootstrap_user_token; then
  JETON=$(user_jeton_balance_from_me "$USER_TOKEN")
  echo "Hesap: $USER_EMAIL — jeton=$JETON"
  if [[ "$JETON" -lt 10 ]]; then
    echo "⚠️  M5 için en az 10 jeton gerekli (song-request)."
    if acceptance_admin_secrets_configured; then
      USER_ID=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $USER_TOKEN" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('id') or d.get('user',{}).get('id') or '')
" 2>/dev/null || echo "")
      if ensure_test_jeton_minimum "$USER_TOKEN" "$USER_ID" "$USER_EMAIL" 50 m5-preflight 2>/dev/null; then
        JETON=$(user_jeton_balance_from_me "$USER_TOKEN")
        echo "✅ Admin top-up sonrası jeton=$JETON"
      else
        echo "❌ Jeton top-up başarısız"
        FAIL=1
      fi
    else
      echo "   ACCEPTANCE_ADMIN_* yok — admin panelden jeton ekleyin."
      FAIL=1
    fi
  else
    echo "✅ Jeton yeterli"
  fi
else
  echo "❌ Giriş başarısız"
  FAIL=1
fi
echo ""

echo "── 3/3 Flutter voice_hub testleri ──"
if command -v flutter >/dev/null 2>&1; then
  if (cd "$ROOT/mobile" && flutter test test/features/voice_hub/ --reporter compact); then
    echo "✅ voice_hub testleri: OK"
  else
    echo "❌ voice_hub testleri: BAŞARISIZ"
    FAIL=1
  fi
else
  echo "⏭️  Flutter yok — atlandı"
fi
echo ""

if [[ "$FAIL" -eq 0 ]]; then
  echo "✅ M5 preflight geçti — cihaz testine hazırsınız."
  echo "   Kontrol listesi: docs/M5_DEVICE_TEST_CHECKLIST.md"
  exit 0
fi

echo "❌ M5 preflight tamamlanamadı — yukarıdaki uyarıları giderin."
exit 1
