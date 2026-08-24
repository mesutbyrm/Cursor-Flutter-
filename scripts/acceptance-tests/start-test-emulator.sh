#!/usr/bin/env bash
# Android emülatör başlatma — Cloud VM'de KVM yoksa başarısız olur (beklenen).
set -euo pipefail

export ANDROID_HOME="${ANDROID_HOME:-/home/ubuntu/android-sdk}"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"

AVD="${CANLIFAL_TEST_AVD:-canlifal_test}"
LOG="${CANLIFAL_EMULATOR_LOG:-/tmp/canlifal-emulator.log}"

if ! command -v emulator >/dev/null 2>&1; then
  echo "❌ emulator bulunamadı: $ANDROID_HOME/emulator"
  exit 1
fi

if [[ ! -r /dev/kvm ]] && ! groups | grep -q kvm; then
  echo "⚠️  KVM (/dev/kvm) yok — Cloud Agent VM'de emülatör çalışmaz."
  echo "   Çözüm: Kendi Android telefonunuzu USB ile bağlayın."
  echo "   Kılavuz: docs/KULLANICI_TEST_KILAVUZU.md"
  exit 2
fi

if adb devices 2>/dev/null | grep -qE 'emulator-[0-9]+\s+device'; then
  echo "✅ Emülatör zaten çalışıyor"
  adb devices
  exit 0
fi

echo "Emülatör başlatılıyor: $AVD (log: $LOG)"
nohup emulator -avd "$AVD" -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect \
  >"$LOG" 2>&1 &
echo $! > /tmp/canlifal-emulator.pid

for i in $(seq 1 60); do
  if adb devices 2>/dev/null | grep -qE 'emulator-[0-9]+\s+device'; then
    echo "✅ Emülatör hazır (${i}0s)"
    adb devices
    exit 0
  fi
  sleep 10
done

echo "❌ Emülatör 600s içinde açılmadı. Son log:"
tail -30 "$LOG" 2>/dev/null || true
exit 1
