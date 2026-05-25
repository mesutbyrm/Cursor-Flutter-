#!/bin/bash
set -euo pipefail
export PATH="/home/ubuntu/flutter32/bin:${PATH:-/usr/bin:/bin}"
LOG="/workspace/merge-build-log.txt"
: > "$LOG"
cd /workspace/mobile
flutter pub get >> "$LOG" 2>&1
flutter build apk --release >> "$LOG" 2>&1
cp -f build/app/outputs/flutter-apk/app-release.apk /workspace/canlifal-mobile-release.apk
ls -la /workspace/canlifal-mobile-release.apk >> "$LOG" 2>&1
echo "BUILD_OK" >> "$LOG"
