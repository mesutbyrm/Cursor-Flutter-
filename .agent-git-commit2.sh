#!/bin/bash
set -euo pipefail
cd /workspace
git commit -m "$(cat <<'EOF'
feat: native Google/TikTok auth, DM start, voice room UX

- SQL-backed /api/auth register, login, google, tiktok (no WebView OAuth)
- Flutter register form aligned with web; native Google/TikTok on login
- POST /api/messages/conversations for direct messages
- Profile Mesaj button opens DM thread
- Voice rooms: 3-column larger tiles, sort by occupancy, red count badge
EOF
)" > /workspace/git-commit-result.txt 2>&1
git log -1 --oneline > /workspace/git-log-1.txt 2>&1
