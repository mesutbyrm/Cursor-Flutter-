#!/usr/bin/env bash
# Play Console — Data safety form özeti (kopyala-yapıştır rehber).
set -euo pipefail

cat <<'EOF'
=== Play Console → App content → Data safety ===

Privacy policy URL: https://canlifal.com/gizlilik

Data collected (typical answers for Canlifal — verify against current app):

1. Personal info — Name, email address, user IDs
   Purpose: Account creation, authentication, profile
   Optional: No (required for login)
   Encrypted in transit: Yes

2. Photos and videos — User-generated content (profile, fortune, live)
   Purpose: App functionality, social features
   Optional: Partially (some features require camera/gallery)
   Encrypted in transit: Yes

3. Audio files — Voice in live rooms / fortune sessions
   Purpose: Real-time voice/video (TRTC/Agora)
   Optional: Yes (mic permission per session)
   Encrypted in transit: Yes

4. App activity — In-app actions, interactions
   Purpose: Analytics, fraud prevention, feature delivery
   Optional: Varies
   Encrypted in transit: Yes

5. Device or other IDs — Device identifiers, push tokens
   Purpose: Notifications, session security
   Optional: No (push requires token)
   Encrypted in transit: Yes

6. Financial info — In-app purchase / wallet (jeton, credits)
   Purpose: Purchases and virtual currency
   Optional: Yes (only when user buys)
   Encrypted in transit: Yes

Data shared with third parties (declare if applicable):
  - Payment processors (Google Play Billing)
  - Real-time media SDKs (Tencent TRTC / Agora) — session tokens only
  - Firebase / push (if enabled)

Security practices:
  - Data encrypted in transit (HTTPS, WSS/SSE)
  - Users can request account deletion (support / in-app settings per policy)

Account deletion: https://canlifal.com/gizlilik (policy) + in-app support flow

Children: App not primarily directed at children under 13 (confirm target audience in Console)

Detay: docs/PLAY_STORE_PRODUCTION_ACCESS.md (Data Safety bölümü)
EOF
