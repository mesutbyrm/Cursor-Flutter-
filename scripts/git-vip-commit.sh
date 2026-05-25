#!/bin/bash
set -euo pipefail
cd /workspace
BRANCH="${1:-cursor/vip-gold-premium-2026-7009}"
git checkout -B "$BRANCH" 2>/dev/null || git checkout "$BRANCH"
git add \
  mobile/lib/features/vip_gold \
  mobile/lib/app/router/app_router.dart \
  mobile/lib/features/voice_hub/presentation/voice_room_rtc_page.dart \
  mobile/lib/features/voice_hub/presentation/voice_rooms_body.dart \
  mobile/lib/features/voice_hub/presentation/pages/voice_gold_vip_page.dart \
  mobile/lib/features/voice_hub/presentation/widgets/voice_room_grid_tile.dart \
  mobile/lib/features/voice_hub/presentation/widgets/premium_2026/voice_mic_seat.dart \
  mobile/lib/features/profile/presentation/pages/profile_page.dart \
  mobile/pubspec.yaml \
  mobile/CHANGELOG.md
git status -sb > /workspace/git-status-short.txt
git commit -m "feat(mobile): PART 7 VIP/Gold premium system

- VIP badges, tiers, luxury hub at /vip-gold
- Gold entrance animation on voice room join
- VIP and password-locked room gates
- Discover VIP category and profile banner links
- Version 1.0.82+84" || true
git push -u origin "$BRANCH" 2>&1 | tail -20 > /workspace/git-push-log.txt || true
