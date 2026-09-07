#!/usr/bin/env bash
# Play Console — Content rating (IARC) anketi özeti.
set -euo pipefail

cat <<'EOF'
=== Play Console → App content → Content rating (IARC) ===

Category: Social / Entertainment (user-generated live content, fortune, voice rooms)

Typical answers for Canlifal (verify in questionnaire):

- Violence: None or mild (no graphic violence in app purpose)
- Sexual content: None (fortune/social; no adult content intended)
- Language: User-generated — may contain mild language; moderation exists
- Controlled substances: None
- Gambling: Virtual currency (jeton) for gifts/features — NOT real-money gambling
  → Declare in-app purchases / virtual items; NOT casino/gambling app
- User interaction: Yes — live chat, voice rooms, DMs, gifts
- Shares location: Optional (if user grants location permission)
- Shares personal info: Yes (profile, messages — with privacy policy)
- Digital purchases: Yes (Google Play in-app / jeton)

Target audience: 13+ or 16+ (confirm with product policy — not directed at children)

Contact email: support address on https://canlifal.com/gizlilik

After questionnaire: save IARC certificate ID in Play Console.

Detay: docs/PLAY_STORE_PRODUCTION_ACCESS.md
EOF
