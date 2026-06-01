#!/bin/bash
set -euo pipefail
cd /workspace
BRANCH="cursor/auth-social-ux-7009"
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"
git add \
  api/.env.example \
  api/prisma/schema.prisma \
  api/prisma/migrations/20250522140000_auth_profile_oauth \
  api/src/index.ts \
  api/src/routes/auth.ts \
  api/src/routes/messages.ts \
  api/src/lib/auth_user.ts \
  api/src/lib/google_auth.ts \
  api/src/lib/tiktok_auth.ts \
  mobile/lib \
  mobile/pubspec.yaml \
  mobile/pubspec.lock \
  mobile/macos/Flutter/GeneratedPluginRegistrant.swift \
  docs/CANLIFAL_COM_AI_PROMPT.md \
  2>/dev/null || true
git add -u api mobile docs/CANLIFAL_COM_AI_PROMPT.md 2>/dev/null || true
git status -sb > /workspace/git-status-sb.txt
git commit -m "$(cat <<'EOF'
feat: native Google/TikTok auth, DM start, voice room UX

- SQL-backed /api/auth register, login, google, tiktok (no WebView OAuth)
- Flutter register form aligned with web; native Google/TikTok on login
- POST /api/messages/conversations for direct messages
- Profile Mesaj button opens DM thread
- Voice rooms: 3-column larger tiles, sort by occupancy, red count badge
EOF
)" || true
git push -u origin "$BRANCH" > /workspace/git-push-result.txt 2>&1 || true
