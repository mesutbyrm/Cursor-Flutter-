#!/usr/bin/env bash
# Dokümante canlı test hesapları — docs/KULLANICI_TEST_KILAVUZU.md
# Şifreler repoda zaten açık; CI secret'ları hatalı/eksikse güvenli geri dönüş.
set -euo pipefail

DEFAULT_ACCEPTANCE_USER_EMAIL="cursor.test.1786235468@mailinator.com"
DEFAULT_ACCEPTANCE_USER_USERNAME="cursorusr1786235468"
DEFAULT_ACCEPTANCE_USER_PASSWORD="CursorTest!1786235468"
DEFAULT_ACCEPTANCE_HOST_EMAIL="cursor.host.1786235468@mailinator.com"
DEFAULT_ACCEPTANCE_HOST_PASSWORD="CursorTest!1786235468"

# Boş string = secret yok (GitHub Actions boş secret'ları "" olarak geçirir).
_acceptance_or_default() {
  local current="${1:-}" secret="${2:-}" default="${3:-}"
  if [[ -n "$current" ]]; then
    printf '%s' "$current"
  elif [[ -n "$secret" ]]; then
    printf '%s' "$secret"
  else
    printf '%s' "$default"
  fi
}

# Secret yoksa veya boşsa varsayılanları uygula.
apply_acceptance_credential_defaults() {
  USER_EMAIL="$(_acceptance_or_default "${USER_EMAIL:-}" "${ACCEPTANCE_USER_EMAIL:-}" "$DEFAULT_ACCEPTANCE_USER_EMAIL")"
  USER_USERNAME="$(_acceptance_or_default "${USER_USERNAME:-}" "${ACCEPTANCE_USER_USERNAME:-}" "$DEFAULT_ACCEPTANCE_USER_USERNAME")"
  USER_PASSWORD="$(_acceptance_or_default "${USER_PASSWORD:-}" "${ACCEPTANCE_USER_PASSWORD:-}" "$DEFAULT_ACCEPTANCE_USER_PASSWORD")"
  HOST_EMAIL="$(_acceptance_or_default "${HOST_EMAIL:-}" "${ACCEPTANCE_HOST_EMAIL:-}" "$DEFAULT_ACCEPTANCE_HOST_EMAIL")"
  HOST_PASSWORD="$(_acceptance_or_default "${HOST_PASSWORD:-}" "${ACCEPTANCE_HOST_PASSWORD:-}" "$DEFAULT_ACCEPTANCE_HOST_PASSWORD")"
  VIEWER_EMAIL="$(_acceptance_or_default "${VIEWER_EMAIL:-}" "${ACCEPTANCE_VIEWER_EMAIL:-}" "$USER_EMAIL")"
  VIEWER_PASSWORD="$(_acceptance_or_default "${VIEWER_PASSWORD:-}" "${ACCEPTANCE_VIEWER_PASSWORD:-}" "$USER_PASSWORD")"
}

# Falcı secret yoksa onaylı host hesabı (KULLANICI_TEST_KILAVUZU — canlı yayın onaylı).
apply_acceptance_teller_fallback() {
  local host_email="${1:-}" host_pass="${2:-}"
  local teller_email="${3:-}" teller_user="${4:-}" teller_pass="${5:-}"
  if [[ -n "${ACCEPTANCE_TELLER_EMAIL:-}" || -n "${ACCEPTANCE_TELLER_USERNAME:-}" ]]; then
    return 0
  fi
  if [[ -z "$teller_email" && -z "$teller_user" && -n "$host_email" && -n "$host_pass" ]]; then
    TELLER_EMAIL="$host_email"
    TELLER_PASSWORD="$host_pass"
  fi
}
