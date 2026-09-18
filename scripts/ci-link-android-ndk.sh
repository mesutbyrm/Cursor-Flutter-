#!/usr/bin/env bash
# Geriye dönük uyumluluk — yeni kurulum: ci-install-android-ndk.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec bash "$ROOT/scripts/ci-install-android-ndk.sh"
