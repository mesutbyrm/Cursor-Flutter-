#!/usr/bin/env bash
# Kullanıcı cihaz test sonucu kaydı — PASS/FAIL bildirimi için şablon.
# Kullanım:
#   bash scripts/record-user-test-result.sh p0 PASS
#   bash scripts/record-user-test-result.sh p0 FAIL "T+5s video dondu"
#   bash scripts/record-user-test-result.sh p1 PASS
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="${ROOT}/docs/USER_DEVICE_TEST_LOG.md"

phase="${1:-}"
result="${2:-}"
note="${3:-}"

if [[ -z "$phase" || -z "$result" ]]; then
  cat <<EOF
Kullanım: bash scripts/record-user-test-result.sh <p0|p1> <PASS|FAIL> [not]

Örnek:
  bash scripts/record-user-test-result.sh p0 PASS
  bash scripts/record-user-test-result.sh p0 FAIL "T+5s donma devam ediyor"
  bash scripts/record-user-test-result.sh p1 PASS

Kayıt: docs/USER_DEVICE_TEST_LOG.md
EOF
  exit 1
fi

phase=$(echo "$phase" | tr '[:upper:]' '[:lower:]')
result=$(echo "$result" | tr '[:lower:]' '[:upper:]')

case "$phase" in
  p0|psychic|psychic-p0) phase_label="Psychic P0" ;;
  p1|platform) phase_label="P1 Platform" ;;
  *)
    echo "Geçersiz faz: $phase (p0 veya p1)"
    exit 1
    ;;
esac

case "$result" in
  PASS|FAIL) ;;
  *)
    echo "Geçersiz sonuç: $result (PASS veya FAIL)"
    exit 1
    ;;
esac

VERSION="?"
if [[ -f "${ROOT}/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "${ROOT}/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

TS=$(date -u +"%Y-%m-%d %H:%M UTC")

if [[ ! -f "$LOG" ]]; then
  cat >"$LOG" <<EOF
# Kullanıcı cihaz test günlüğü


> **Güncel (2026-09-07):** **`${VERSION}`** · Agent tarafından otomatik oluşturuldu · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

Kullanıcı test sonuçları — agent'a bildirmek için bu dosyayı veya tek satır mesajı kullanın.

---

EOF
fi

{
  echo "## ${TS} — ${phase_label} **${result}**"
  echo ""
  echo "| Alan | Değer |"
  echo "|------|--------|"
  echo "| Sürüm | \`${VERSION}\` |"
  echo "| Faz | ${phase_label} |"
  echo "| Sonuç | **${result}** |"
  if [[ -n "$note" ]]; then
    echo "| Not | ${note} |"
  fi
  echo ""
  if [[ "$result" == "PASS" && "$phase_label" == "Psychic P0" ]]; then
    echo "Sonraki: \`bash scripts/p1-go.sh\` · \`docs/P1_DEVICE_START.md\`"
  elif [[ "$result" == "PASS" && "$phase_label" == "P1 Platform" ]]; then
    echo "Sonraki: \`bash scripts/on-release-ready-candidate.sh\` · \`bash scripts/print-play-upload-day-checklist.sh\`"
  elif [[ "$result" == "FAIL" ]]; then
    echo "Agent: hotfix gerekir — logcat / ekran kaydı ekleyin."
  fi
  echo ""
} >>"$LOG"

echo "✅ Kaydedildi: $LOG"
echo "   ${phase_label} ${result}${note:+ — $note}"
echo ""
echo "Agent'a bildirin (kopyala-yapıştır):"
echo "  ${phase_label} ${result}${note:+ — $note}"
