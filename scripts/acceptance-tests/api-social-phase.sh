#!/usr/bin/env bash
# Sosyal API doğrulaması — gönderi listesi + yorum uçları (gerçek cihaz olmadan).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd curl python3

USER_EMAIL="${ACCEPTANCE_USER_EMAIL:-}"
USER_PASSWORD="${ACCEPTANCE_USER_PASSWORD:-}"
USER_TOKEN=""
POST_ID=""

echo "=== API Social Phase ==="
echo "Base: $BASE"
echo ""

gate_posts_list() {
  echo "--- SOCIAL POSTS LIST ---"
  if ! acceptance_user_secrets_configured; then
    record "POSTS" "Social posts" SKIP "ACCEPTANCE_USER_* yok"
    return
  fi
  local resp token
  resp=$(mobile_login_identifier email "$USER_EMAIL" "$USER_PASSWORD")
  token=$(extract_token "$resp")
  if [[ -z "$token" ]]; then
    record "POSTS" "Social posts" FAIL "token yok"
    return
  fi
  USER_TOKEN="$token"
  local code body count
  code=$(http_code -H "Authorization: Bearer $token" \
    "$BASE/api/social/posts?page=1&limit=5&feed=following")
  body=$(curl_json "$BASE/api/social/posts?page=1&limit=5&feed=following" \
    -H "Authorization: Bearer $token")
  count=$(printf '%s' "$body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d if isinstance(d,list) else (d.get('posts') or d.get('items') or d.get('data') or [])
print(len(items) if isinstance(items,list) else 0)
" 2>/dev/null || echo 0)
  POST_ID=$(printf '%s' "$body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d if isinstance(d,list) else (d.get('posts') or d.get('items') or d.get('data') or [])
if not items: sys.exit(0)
it=items[0]
print(it.get('id') or it.get('postId') or '')
" 2>/dev/null || echo "")
  if [[ "$code" == "200" ]]; then
    record "POSTS" "Social posts" PASS "${count} gönderi"
  else
    record "POSTS" "Social posts" FAIL "HTTP $code"
  fi
}

gate_comments_list() {
  echo "--- SOCIAL COMMENTS ---"
  skip_unless_user_token "COMMENTS" "Social comments" || return 0
  if [[ -z "$POST_ID" ]]; then
    record "COMMENTS" "Social comments" SKIP "gönderi yok"
    return
  fi
  local code body count
  code=$(http_code -H "Authorization: Bearer $USER_TOKEN" \
    "$BASE/api/social/posts/$POST_ID/comments")
  body=$(curl_json "$BASE/api/social/posts/$POST_ID/comments" \
    -H "Authorization: Bearer $USER_TOKEN")
  count=$(printf '%s' "$body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d if isinstance(d,list) else (d.get('comments') or d.get('items') or d.get('data') or [])
print(len(items) if isinstance(items,list) else 0)
" 2>/dev/null || echo 0)
  if [[ "$code" == "200" ]]; then
    record "COMMENTS" "Social comments" PASS "${count} yorum"
  else
    record "COMMENTS" "Social comments" FAIL "HTTP $code"
  fi
}

gate_like_probe() {
  echo "--- SOCIAL LIKE (probe) ---"
  skip_unless_user_token "LIKE" "Social like" || return 0
  if [[ -z "$POST_ID" ]]; then
    record "LIKE" "Social like" SKIP "gönderi yok"
    return
  fi
  local code body
  body=$(curl -sS -X POST "$BASE/api/social/posts/$POST_ID/likes" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json")
  code=$(http_code -X POST "$BASE/api/social/posts/$POST_ID/likes" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json")
  if [[ "$code" == "200" || "$code" == "201" ]]; then
    record "LIKE" "Social like" PASS "HTTP $code"
  elif [[ "$code" == "409" ]]; then
    record "LIKE" "Social like" PASS "zaten beğenilmiş (HTTP 409)"
  else
    record "LIKE" "Social like" FAIL "HTTP $code"
  fi
}

gate_posts_list
gate_comments_list
gate_like_probe

export RESULT_LINES_RAW="$(printf '%s\n' "${RESULT_LINES[@]}")"
export REPORT_MD="${REPORT_DIR}/API_SOCIAL_PHASE_REPORT.md"
finalize_reports || exit 1
