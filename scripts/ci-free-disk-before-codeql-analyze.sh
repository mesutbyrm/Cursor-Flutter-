#!/usr/bin/env bash
# CodeQL "Perform CodeQL Analysis" öncesi disk — Flutter APK derlemesi ~15–20 GB kullanır.
set -euo pipefail

echo "CodeQL analiz öncesi disk — önce:"
df -h / | tail -1

# Derleme çıktıları (CodeQL izleme veritabanı build sırasında oluşur).
rm -rf mobile/build/app/outputs \
  mobile/build/app/intermediates \
  mobile/build/ios \
  mobile/android/app/build \
  mobile/android/build \
  mobile/android/.gradle/caches/build-cache-* \
  mobile/android/.gradle/caches/*/fileContent \
  mobile/android/.gradle/caches/*/fileHashes 2>/dev/null || true

# NDK artık gerekmez (~1–2 GB).
if [ -n "${ANDROID_NDK_HOME:-}" ] && [ -d "${ANDROID_NDK_HOME}" ]; then
  rm -rf "${ANDROID_NDK_HOME}" 2>/dev/null || sudo rm -rf "${ANDROID_NDK_HOME}" || true
fi
if [ -n "${ANDROID_HOME:-}" ] && [ -d "${ANDROID_HOME}/ndk" ]; then
  rm -rf "${ANDROID_HOME}/ndk" 2>/dev/null || sudo rm -rf "${ANDROID_HOME}/ndk" || true
fi

# Gradle daemon / geçici dosyalar.
rm -rf /tmp/gradle-* /tmp/kotlin-* 2>/dev/null || true

sudo docker image prune --force 2>/dev/null || true
sudo docker builder prune -af 2>/dev/null || true

echo "CodeQL analiz öncesi disk — sonra:"
df -h / | tail -1
