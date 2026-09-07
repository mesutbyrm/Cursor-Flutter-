#!/usr/bin/env bash
# Play Console — Target audience & Ads (kopyala-yapıştır rehber).
set -euo pipefail

cat <<'EOF'
=== Play Console → App content ===

── Target audience and content (IARC / age groups) ──
- App NOT primarily directed at children under 13
- Recommended: Teen (13+) or Mature (16+) — social/live user content
- User-generated content: live chat, voice rooms, fortune sessions
- Moderation: platform moderation tools exist (declare honestly)

── Ads ──
- Does the app contain ads? Typically NO for core Canlifal APK
  (verify current build — no AdMob banner in release if unchanged)
- If NO: select "No, my app does not contain ads"
- In-app purchases: YES (jeton / virtual currency via Google Play Billing)

── Location permission (AndroidManifest) ──
- ACCESS_FINE_LOCATION / ACCESS_COARSE_LOCATION declared
- Purpose: optional social/location features (if enabled in app)
- Declare in Data safety if collected; optional for user

── Financial features ──
- Virtual currency (jeton) for gifts and paid features
- Not real-money gambling — declare in-app purchases only

Detay: docs/PLAY_STORE_PRODUCTION_ACCESS.md
Print: bash scripts/print-play-data-safety-summary.sh
EOF
