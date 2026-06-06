#!/bin/bash
set -euo pipefail
cd /workspace
git add mobile/lib mobile/android/app/build.gradle.kts 2>/dev/null || true
git add -u mobile/
git add docs/ README.md APK_DOWNLOAD.md
git commit -m "fix(mobile): premium PART 4-7 import paths and Riverpod providers

- Correct relative imports for gifts, live, VIP widgets
- Fix VipGoldTokens goldRadial type, open_live_stream var
- NotifierProvider without autoDispose for PK/live/VIP notifiers
- Enables release APK build at 1.0.82+84"
git push origin main
