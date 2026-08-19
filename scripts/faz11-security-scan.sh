#!/usr/bin/env bash
# FAZ 11 — güvenlik taraması (repo içi, secret sızıntısı yok).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0

echo "=== FAZ11 Security scan ==="

# Bilinen test şifreleri repoda dokümante — gerçek prod secret arama
if rg -l 'sk_live_|AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]{20,}' "$ROOT/mobile" "$ROOT/api" 2>/dev/null | rg -v test | head -5; then
  echo "❌ Olası secret pattern bulundu"
  FAIL=$((FAIL + 1))
else
  echo "✅ Secret pattern taraması temiz"
fi

if [[ -f "$ROOT/mobile/lib/core/network/json_content_type_guard_interceptor.dart" ]]; then
  echo "✅ JsonContentTypeGuard mevcut"
else
  echo "❌ JsonContentTypeGuard eksik"
  FAIL=$((FAIL + 1))
fi

if [[ -f "$ROOT/mobile/lib/core/network/api_exception.dart" ]]; then
  echo "✅ ApiException mevcut"
else
  FAIL=$((FAIL + 1))
fi

echo ""
[[ "$FAIL" -eq 0 ]] && echo "FAZ11 scan: PASS" && exit 0
echo "FAZ11 scan: FAIL=$FAIL" && exit 1
