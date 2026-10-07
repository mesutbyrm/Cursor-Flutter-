#!/usr/bin/env bash
set +e
set +u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" 2>/dev/null || exit 0

# Flutter / Android (Cloud Agent — /opt/android-sdk yoksa ~/Android/Sdk)
if [ -z "${ANDROID_HOME:-}" ] || [ ! -d "${ANDROID_HOME}" ]; then
  if [ -d /opt/android-sdk ]; then
    export ANDROID_HOME=/opt/android-sdk
  elif [ -d "${HOME}/Android/Sdk" ]; then
    export ANDROID_HOME="${HOME}/Android/Sdk"
  fi
fi
for d in /opt/flutter/bin "${HOME}/flutter/bin" \
  "${ANDROID_HOME:+$ANDROID_HOME/cmdline-tools/latest/bin}" \
  "${ANDROID_HOME:+$ANDROID_HOME/platform-tools}"; do
  [ -n "$d" ] && [ -d "$d" ] && PATH="$d:${PATH:-}"
done
export PATH

if [ -d "$ROOT/api" ]; then
  cd "$ROOT/api" || exit 0
  if [ ! -f .env ] && [ -f .env.example ]; then
    cp -n .env.example .env 2>/dev/null || cp .env.example .env 2>/dev/null || true
  fi
fi

exit 0
