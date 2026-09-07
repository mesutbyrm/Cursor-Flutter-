#!/usr/bin/env bash
# Üretim falcı listesi — Psychic P0 hesap seçimi (herkese açık API).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=acceptance-tests/lib.sh
source "$ROOT/scripts/acceptance-tests/lib.sh"

require_cmd curl python3

echo "=== Üretim falcı listesi ==="
echo "Base: $BASE"
echo ""

curl_json "$BASE/api/fortune-tellers" | python3 -c "
import json, sys
raw = sys.stdin.read().strip()
d = json.loads(raw) if raw else {}
items = d.get('tellers') or d.get('data', {}).get('tellers') or d.get('items') or []
print(f'Toplam: {len(items)} falcı')
print()
print('| # | Görünen ad | tellerId (kısa) | userId (kısa) |')
print('|---|------------|-----------------|---------------|')
for i, t in enumerate(items, 1):
    if not isinstance(t, dict):
        continue
    name = (t.get('displayName') or t.get('name') or t.get('username') or '?').strip()
    tid = str(t.get('id') or '')[:22]
    uid = str(t.get('userId') or t.get('user', {}).get('id') or '')[:22]
    print(f'| {i} | {name} | \`{tid}\` | \`{uid}\` |')
print()
print('Psychic P0 falcı telefonu: yukarıdaki hesaplardan birinin giriş bilgisi gerekir.')
print('Host (cursor.host.*) bu listede değil — bash scripts/probe-psychic-teller.sh')
"
