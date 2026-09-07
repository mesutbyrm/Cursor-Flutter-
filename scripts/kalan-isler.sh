#!/usr/bin/env bash
# Kalan release işleri — canlı durum + P0→P1→P2 yol haritası.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

bash "$ROOT/scripts/release-remaining-status.sh"

cat <<'EOF'

╔══════════════════════════════════════════════════════════════════╗
║  Yol haritası (kalan işler)                                       ║
╚══════════════════════════════════════════════════════════════════╝

| # | İş | Durum | Komut |
|---|-----|--------|--------|
| P0-j | Jeton | ✅ | (tamam) |
| P0 | Psychic TRTC 2 telefon | ⏳ OPEN | bash scripts/p0-go.sh |
| P1 | Platform 2 telefon | ⏸ P0 sonrası | bash scripts/p1-go.sh |
| P2 | Play Store / AAB | ⏸ P0+P1 sonrası | bash scripts/p2-go.sh |

Hesaplar: cursor.test.* (danışan) · cursor.host.* (falcı/host) · CursorTest!1786235468

Sonuç bildirimi:
  Psychic P0 PASS → bash scripts/on-p0-pass.sh
  P1 PASS         → bash scripts/on-p1-pass.sh
  RELEASE adayı   → bash scripts/on-release-ready-candidate.sh

Detay: docs/REMAINING_WORK.md · docs/RELEASE_USER_NEXT_STEPS.md
Statik özet: docs/KALAN_ISLER.md · bash scripts/print-kalan-isler.sh

EOF
