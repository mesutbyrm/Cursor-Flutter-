#!/usr/bin/env bash
# Freezed / json_serializable üretimi — CI öncesi yerelde çalıştırın.
set -euo pipefail
cd "$(dirname "$0")/.."
dart run build_runner build --delete-conflicting-outputs
