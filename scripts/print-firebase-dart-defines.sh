#!/usr/bin/env bash
# google-services.json varsa flutter build için --dart-define satırı üretir.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JSON="$ROOT/mobile/android/app/google-services.json"

if [[ ! -f "$JSON" ]] || ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

if head -c 1 "$JSON" | grep -qv '{'; then
  exit 0
fi

PROJECT_ID=$(jq -r '.project_info.project_id' "$JSON")
SENDER_ID=$(jq -r '.project_info.project_number' "$JSON")
API_KEY=$(jq -r '.client[0].api_key[0].current_key' "$JSON")
APP_ID=$(jq -r '.client[0].client_info.mobilesdk_app_id' "$JSON")

# OAuth Web client (client_type 3) — Google Sign-In serverClientId / idToken
WEB_CLIENT_ID=$(jq -r '
  .client[0].oauth_client[]?
  | select(.client_type == 3)
  | .client_id
' "$JSON" 2>/dev/null | head -1)
if [[ -z "$WEB_CLIENT_ID" || "$WEB_CLIENT_ID" == "null" ]]; then
  WEB_CLIENT_ID=$(jq -r '.client[0].oauth_client[0].client_id // empty' "$JSON" 2>/dev/null)
fi

DEFINES=(
  "--dart-define=FIREBASE_PROJECT_ID=$PROJECT_ID"
  "--dart-define=FIREBASE_API_KEY=$API_KEY"
  "--dart-define=FIREBASE_APP_ID=$APP_ID"
  "--dart-define=FIREBASE_MESSAGING_SENDER_ID=$SENDER_ID"
)
if [[ -n "$WEB_CLIENT_ID" && "$WEB_CLIENT_ID" != "null" ]]; then
  DEFINES+=("--dart-define=GOOGLE_SERVER_CLIENT_ID=$WEB_CLIENT_ID")
fi

printf '%s ' "${DEFINES[@]}"
