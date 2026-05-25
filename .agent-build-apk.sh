#!/bin/bash
set -euo pipefail
cd /workspace/mobile
export PATH="/home/ubuntu/flutter32/bin:$PATH"
flutter pub get > /workspace/flutter-pub-get.txt 2>&1
flutter build apk --release > /workspace/flutter-build-apk.txt 2>&1
cp build/app/outputs/flutter-apk/app-release.apk /workspace/canlifal-mobile-release.apk
ls -la /workspace/canlifal-mobile-release.apk >> /workspace/flutter-build-apk.txt
