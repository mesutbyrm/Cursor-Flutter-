#!/bin/bash
set -euo pipefail
export PATH="/home/ubuntu/flutter32/bin:${PATH:-/usr/bin:/bin}"
ROOT="/workspace"
LOG="/workspace/merge-build-log.txt"
: > "$LOG"
cd "$ROOT"

{
  echo "=== Current branch ==="
  git branch --show-current
  echo "=== Commit doc fixes on feature branch ==="
  git add README.md APK_DOWNLOAD.md docs/ mobile/README.md \
    mobile/lib/features/voice_hub/presentation/widgets/premium_2026/voice_live_chat_dock.dart
  git commit -m "docs: 1.0.82+84 sürüm dokümantasyonu; VIP sohbet adı rengi" || true
  git push origin cursor/vip-gold-premium-2026-7009 || true

  echo "=== Merge to main ==="
  git fetch origin main cursor/vip-gold-premium-2026-7009
  git checkout main
  git pull origin main
  git merge origin/cursor/vip-gold-premium-2026-7009 -m "merge: Premium 2026 PART 4-7 (1.0.82+84)"
  git push origin main

  echo "=== Flutter pub get ==="
  cd "$ROOT/mobile"
  flutter pub get

  echo "=== Build APK ==="
  flutter build apk --release
  cp -f build/app/outputs/flutter-apk/app-release.apk "$ROOT/canlifal-mobile-release.apk"
  ls -la "$ROOT/canlifal-mobile-release.apk"
  echo "DONE"
} >> "$LOG" 2>&1
