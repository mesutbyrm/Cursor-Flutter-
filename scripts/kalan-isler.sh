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
| P0 | Psychic TRTC 2 telefon | ⏸ sonuç sonra | bash scripts/cihaz-sonra.sh |
| P1 | Platform 2 telefon | ⏸ sonuç sonra | bash scripts/p1-prep-go.sh |
| P2 | Play Store / AAB | ▶ agent prep | bash scripts/p2-prep-go.sh |

Hesaplar: cursor.test.* (danışan) · cursor.host.* (falcı/host) · CursorTest!1786235468

Sonuç bildirimi:
  Psychic P0 PASS → bash scripts/on-p0-pass.sh
  P1 PASS         → bash scripts/on-p1-pass.sh
  RELEASE adayı   → bash scripts/on-release-ready-candidate.sh

Başlangıç: bash scripts/kullanici-sonraki.sh  (kullanıcı · kalan)
Agent prep: bash scripts/agent-prep-tamam.sh
Cihaz sonra: bash scripts/cihaz-sonra.sh
Detay: docs/REMAINING_WORK.md · docs/RELEASE_USER_NEXT_STEPS.md
Statik özet: docs/KALAN_ISLER.md · bash scripts/print-kalan-isler.sh

EOF
