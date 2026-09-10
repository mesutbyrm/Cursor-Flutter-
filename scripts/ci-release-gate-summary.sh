#!/usr/bin/env bash
# CANLIFAL RELEASE GATE — GitHub Actions özet çıktısı.
set -euo pipefail

COMMIT="${1:-${GITHUB_SHA:-unknown}}"
VERSION="${2:-unknown}"
VERSION_CODE="${3:-unknown}"
ANALYZE="${4:-UNKNOWN}"
TESTS="${5:-UNKNOWN}"
APK_BUILD="${6:-UNKNOWN}"
SIGNING="${7:-UNKNOWN}"
ARTIFACT="${8:-UNKNOWN}"
HTTP="${9:-UNKNOWN}"
METADATA="${10:-UNKNOWN}"

pass_count=0
fail_count=0
for gate in "$ANALYZE" "$TESTS" "$APK_BUILD" "$SIGNING" "$ARTIFACT"; do
  case "$gate" in
    PASS) pass_count=$((pass_count + 1)) ;;
    FAIL) fail_count=$((fail_count + 1)) ;;
  esac
done

# HTTP / metadata: bilinçli SKIP (doğrulama adımı çalışmadı) veya tam doğrulama.
http_ok=false
case "$HTTP" in
  200|SKIP) http_ok=true ;;
  FAIL) fail_count=$((fail_count + 1)) ;;
esac

metadata_ok=false
case "$METADATA" in
  PASS|SKIP) metadata_ok=true ;;
  FAIL) fail_count=$((fail_count + 1)) ;;
esac

core_ok=true
for required in "$ANALYZE" "$TESTS" "$APK_BUILD" "$SIGNING" "$ARTIFACT"; do
  [[ "$required" == PASS ]] || core_ok=false
done

if [[ "$fail_count" -eq 0 && "$core_ok" == true && "$http_ok" == true && "$metadata_ok" == true ]]; then
  FINAL="PASS"
else
  FINAL="NOT READY"
fi

{
  echo "CANLIFAL RELEASE GATE"
  echo ""
  echo "Commit: $COMMIT"
  echo "Version: $VERSION"
  echo "VersionCode: $VERSION_CODE"
  echo ""
  echo "Analyze: $ANALYZE"
  echo "Flutter Tests: $TESTS"
  echo "APK Build: $APK_BUILD"
  echo "Signing: $SIGNING"
  echo "APK Artifact: $ARTIFACT"
  echo "APK HTTP: $HTTP"
  echo "APK Metadata: $METADATA"
  echo ""
  echo "FINAL: $FINAL"
} | tee /tmp/canlifal-release-gate-summary.txt

if [[ "$FINAL" != PASS ]]; then
  exit 1
fi
