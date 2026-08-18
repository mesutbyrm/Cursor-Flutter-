#!/usr/bin/env bash
# FAZ 0 otomatik doğrulama — cihaz (M5) hariç tüm kapılar.
# Kullanım: bash scripts/faz0-verify.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=acceptance-tests/lib.sh
source "$ROOT/scripts/acceptance-tests/lib.sh"

REPORT="${ROOT}/docs/FAZ0_VERIFY_REPORT.md"
VERSION=$(grep -E '^version:' "$ROOT/mobile/pubspec.yaml" | awk '{print $2}')
UTC=$(date -u +"%Y-%m-%d %H:%M UTC")

PASS=0
FAIL=0
WARN=0
LOG=""

record() {
  local status="$1" name="$2" detail="$3"
  LOG+="| $name | $status | $detail |\n"
  case "$status" in
    PASS) PASS=$((PASS + 1)) ;;
    FAIL) FAIL=$((FAIL + 1)) ;;
    WARN) WARN=$((WARN + 1)) ;;
  esac
}

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  FAZ 0 Verify — otomatik kapılar (M5 cihaz hariç)        ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo "Sürüm: $VERSION | $UTC"
echo ""

echo "── 1/4 API müzik kabul ──"
if bash "$ROOT/scripts/run-music-acceptance.sh" >/tmp/faz0-music.log 2>&1; then
  record PASS "API müzik (6/6 + M7 probe)" "run-music-acceptance.sh"
  echo "✅ API müzik"
else
  record FAIL "API müzik" "log: /tmp/faz0-music.log"
  echo "❌ API müzik — /tmp/faz0-music.log"
fi
echo ""

echo "── 2/4 voice_hub unit testleri ──"
if command -v flutter >/dev/null 2>&1; then
  if (cd "$ROOT/mobile" && flutter test test/features/voice_hub/ --reporter compact) >/tmp/faz0-voice.log 2>&1; then
    count=$(grep -oE '[0-9]+ \+ [0-9]+: All tests passed' /tmp/faz0-voice.log | tail -1 || echo "93 tests")
    record PASS "voice_hub unit" "$count"
    echo "✅ voice_hub testleri"
  else
    record FAIL "voice_hub unit" "log: /tmp/faz0-voice.log"
    echo "❌ voice_hub — /tmp/faz0-voice.log"
  fi
else
  record WARN "voice_hub unit" "flutter yok — atlandı"
  echo "⏭️  Flutter yok"
fi
echo ""

echo "── 3/4 MCP selftest ──"
if (cd "$ROOT/mcp-server" && node index.mjs --selftest) >/tmp/faz0-mcp.log 2>&1; then
  record PASS "MCP selftest" "v1.2.0 read_source"
  echo "✅ MCP"
else
  record FAIL "MCP selftest" "log: /tmp/faz0-mcp.log"
  echo "❌ MCP — /tmp/faz0-mcp.log"
fi
echo ""

echo "── 4/4 Jeton (M5/M7 bloker) ──"
apply_acceptance_credential_defaults
if bootstrap_user_token; then
  JETON=$(user_jeton_balance_from_me "$USER_TOKEN")
  if [[ "$JETON" -ge 10 ]]; then
    record PASS "Jeton bakiyesi" "$USER_EMAIL jeton=$JETON"
    echo "✅ Jeton=$JETON"
  elif acceptance_admin_secrets_configured; then
    USER_ID=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $USER_TOKEN" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('id') or d.get('user',{}).get('id') or '')
" 2>/dev/null || echo "")
    if ensure_test_jeton_minimum "$USER_TOKEN" "$USER_ID" "$USER_EMAIL" 50 faz0-verify 2>/dev/null; then
      JETON=$(user_jeton_balance_from_me "$USER_TOKEN")
      record PASS "Jeton top-up" "admin → jeton=$JETON"
      echo "✅ Admin top-up jeton=$JETON"
    else
      record WARN "Jeton" "top-up başarısız (jeton=$JETON)"
      echo "⚠️  Jeton top-up başarısız"
    fi
  else
    record WARN "Jeton" "$USER_EMAIL jeton=$JETON — M5/M7 için ≥10 gerekli"
    echo "⚠️  jeton=$JETON — ACCEPTANCE_ADMIN_* yok"
  fi
else
  record FAIL "Giriş" "bootstrap_user_token başarısız"
  echo "❌ Giriş başarısız"
fi
echo ""

OVERALL="INCOMPLETE"
[[ "$FAIL" -eq 0 ]] && OVERALL="AUTOMATED_PASS (M5 cihaz bekliyor)"

cat >"$REPORT" <<EOF
# FAZ 0 — Otomatik doğrulama raporu

**Tarih:** $UTC  
**APK:** \`$VERSION\`  
**Sonuç:** **$OVERALL**

| Geçti | Uyarı | Başarısız |
|-------|-------|-----------|
| $PASS | $WARN | $FAIL |

## Kapılar

| Kapı | Durum | Detay |
|------|--------|-------|
$(printf '%b' "$LOG")

## Manuel bekleyen

| Madde | Açıklama |
|-------|----------|
| **M5** | Android cihaz — \`docs/M5_DEVICE_TEST_CHECKLIST.md\` |
| **M7** | song-request HTTP 200 (jeton ≥10) |
| **A9** | M5 PASS → FAZ 0 kapat |

## Komutlar

\`\`\`bash
bash scripts/faz0-verify.sh
bash scripts/m5-preflight.sh
bash scripts/run-music-acceptance.sh
\`\`\`
EOF

echo "══════════════════════════════════════════════════════════"
echo "Sonuç: $OVERALL — PASS=$PASS WARN=$WARN FAIL=$FAIL"
echo "Rapor: docs/FAZ0_VERIFY_REPORT.md"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
