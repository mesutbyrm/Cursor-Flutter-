#!/usr/bin/env bash
# USER_DEVICE_TEST_LOG.md — P0/P1 PASS satır kontrolü (ortak).
# shellcheck disable=SC2034
device_test_log_has_pass() {
  local phase_label="$1"
  local log="${2:-${ROOT:-}/docs/USER_DEVICE_TEST_LOG.md}"
  [[ -f "$log" ]] && grep -qE "^## .* — ${phase_label} \\*\\*PASS\\*\\*" "$log" 2>/dev/null
}

device_test_log_recent_entries() {
  local log="${1:-${ROOT:-}/docs/USER_DEVICE_TEST_LOG.md}"
  [[ -f "$log" ]] && grep -E '^## .* — (Psychic P0|P1 Platform) \*\*(PASS|FAIL)\*\*' "$log" | tail -6
}
