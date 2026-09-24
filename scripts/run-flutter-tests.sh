#!/usr/bin/env bash
# Flutter test suite çalıştırıcı - tüm Phase 1-6 test cases
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/mobile" || exit 1

log() { printf '==> %s\n' "$*"; }
error() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# Flutter PATH'i kontrol et
if ! command -v flutter >/dev/null 2>&1; then
  error "Flutter SDK bulunamadı. Önce 'bash scripts/cursor-update.sh' çalıştırın"
fi

log "Flutter SDK sürümü:"
flutter --version

log ""
log "================================"
log "Phase 4-6 Test Suites Çalıştırılıyor"
log "================================"
log ""

TEST_RESULTS=()
TEST_COUNT=0
FAIL_COUNT=0

run_test_file() {
  local test_file="$1"
  local test_name="$(basename "$test_file" .dart)"

  if [ ! -f "$test_file" ]; then
    echo "⚠️  Bulunamadı: $test_file"
    return 1
  fi

  TEST_COUNT=$((TEST_COUNT + 1))
  echo ""
  log "[$TEST_COUNT] Çalıştırılıyor: $test_name"
  echo "───────────────────────────────────"

  if flutter test "$test_file" --reporter=expanded 2>&1; then
    echo "✅ PASS: $test_name"
    TEST_RESULTS+=("✅ $test_name")
  else
    echo "❌ FAIL: $test_name"
    TEST_RESULTS+=("❌ $test_name")
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# Phase 4: RoomSessionManager Tests
log ""
log "Phase 4: Unit Tests"
run_test_file "test/features/voice_hub/room_session_manager_test.dart"

# Phase 4: Integration Tests
log ""
log "Phase 4: Voice Room Integration Tests"
run_test_file "test/features/voice_hub/voice_room_manager_integration_test.dart"

# Phase 5: PK Integration Tests
log ""
log "Phase 5: PK + Voice Room Integration Tests"
run_test_file "test/features/pk/pk_session_integration_test.dart"

# Summary
log ""
log "================================"
log "Test Sonuçları Özeti"
log "================================"
log ""

for result in "${TEST_RESULTS[@]}"; do
  echo "$result"
done

log ""
if [ $FAIL_COUNT -eq 0 ]; then
  log "✅ TÜKÜM TESTLER BAŞARILI ($TEST_COUNT/$TEST_COUNT)"
  exit 0
else
  log "❌ BAŞARISIZ: $FAIL_COUNT/$TEST_COUNT test failed"
  exit 1
fi
