#!/bin/bash
set -euo pipefail
export PATH="/home/ubuntu/flutter32/bin:${PATH:-/usr/bin:/bin}"
LOG=/workspace/final-build.log
: > "$LOG"
cd /workspace
git pull --rebase origin main >> "$LOG" 2>&1 || git pull origin main >> "$LOG" 2>&1
git push origin main >> "$LOG" 2>&1
cd /workspace/mobile
flutter pub get >> "$LOG" 2>&1
flutter build apk --release >> "$LOG" 2>&1
cp -f build/app/outputs/flutter-apk/app-release.apk /workspace/canlifal-mobile-release.apk
mkdir -p /opt/cursor/artifacts
cp -f /workspace/canlifal-mobile-release.apk /opt/cursor/artifacts/canlifal-mobile-1.0.83+85-release.apk
ls -la /opt/cursor/artifacts/canlifal-mobile-1.0.83+85-release.apk >> "$LOG" 2>&1
echo BUILD_OK >> "$LOG"
