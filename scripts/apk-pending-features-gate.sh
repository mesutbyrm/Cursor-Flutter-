#!/usr/bin/env bash
# APK yayın kilidi — bekleyen özellikler kodda yoksa CI durur (sürüm bump yapılmamalı).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOBILE="$ROOT/mobile"
FAIL=0

check() {
  local name="$1"
  local path="$2"
  local pattern="$3"
  if [[ ! -f "$path" ]]; then
    echo "❌ $name — dosya yok: $path"
    FAIL=$((FAIL + 1))
    return
  fi
  if ! grep -qE "$pattern" "$path"; then
    echo "❌ $name — işaret bulunamadı ($pattern) in $path"
    FAIL=$((FAIL + 1))
    return
  fi
  echo "✅ $name"
}

echo "=== APK pending features gate ==="

check "Gift box panel UI" \
  "$MOBILE/lib/features/gift_box/presentation/widgets/gift_box_panel_section.dart" \
  'GiftBoxPanelSection'

check "Voice gift panel — hediye kutusu" \
  "$MOBILE/lib/features/voice_hub/presentation/widgets/premium_2026/voice_premium_gift_panel_2026.dart" \
  'Hediye kutusu'

check "Live gift panel — gift_box" \
  "$MOBILE/lib/features/gifts/presentation/widgets/premium_gift_panel.dart" \
  'gift_box'

check "SSE gift_box refresh" \
  "$MOBILE/lib/features/voice_hub/presentation/providers/chat_room_providers_room_sync.dart" \
  'gift_box_created'

check "Tanış — actions provider" \
  "$MOBILE/lib/features/social/presentation/providers/social_discovery_providers.dart" \
  'socialDiscoveryActionsProvider'

check "Tanış — hashtag tab" \
  "$MOBILE/lib/features/social/presentation/pages/tanis_kaynas_page.dart" \
  'socialTrendingHashtagsProvider'

check "Tanış — favorite action (süper beğeni)" \
  "$MOBILE/lib/features/social/presentation/pages/tanis_discover_tab.dart" \
  "'favorite'"

if [[ "$FAIL" -gt 0 ]]; then
  echo ""
  echo "APK yayın kilidi: $FAIL madde eksik. docs/APK_PENDING_FEATURES.md"
  exit 1
fi

echo ""
echo "APK pending features gate: PASS"
