#!/bin/bash
set -e
GH=/usr/bin/gh
REPO=mesutbyrm/Cursor-Flutter-
VERSION=1.0.46+48
APK=/workspace/apk-dl/canlifal-mobile-release.apk
test -f "$APK"

{
  echo "# Canlifal APK ${VERSION}"
  echo ""
  echo "**İndir:** https://github.com/${REPO}/releases/download/apk-latest/canlifal-mobile-release.apk"
  echo ""
  echo "## Bu sürümde"
  echo ""
  awk '/^## 1.0.46/,/^## 1.0.38/ { if (/^## 1.0.38/) exit; print }' /workspace/mobile/CHANGELOG.md
} > /workspace/release-notes.md

$GH release upload apk-latest "$APK" --repo "$REPO" --clobber
$GH release edit apk-latest --repo "$REPO" --title "Canlifal APK ${VERSION}" --notes-file /workspace/release-notes.md
$GH release view apk-latest --repo "$REPO" | head -5 > /workspace/release-after.txt
