#!/usr/bin/env bash
# Üst bilgi satırlarındaki sürüm/tarihi pubspec + LATEST_APK_BUILD ile hizalar.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export SYNC_ROOT="$ROOT"
export SYNC_VERSION
SYNC_VERSION=$(grep -E '^version:' "$ROOT/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
export SYNC_DATE
SYNC_DATE=$(date -u +%Y-%m-%d)
export SYNC_RUN=""
if [[ -f "$ROOT/docs/LATEST_APK_BUILD.md" ]]; then
  SYNC_RUN=$(grep -oE 'Run [0-9]+' "$ROOT/docs/LATEST_APK_BUILD.md" | head -1 | sed 's/Run //' || true)
fi

python3 <<'PY'
import os
import re
from pathlib import Path

root = Path(os.environ["SYNC_ROOT"])
version = os.environ["SYNC_VERSION"]
date = os.environ["SYNC_DATE"]
run = os.environ.get("SYNC_RUN", "")
header = (
    f"> **Güncel ({date}):** **`{version}`** · Release gate **FINAL PASS** · "
    f"**RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)"
)
surum = (
    f"> **Sürüm:** `{version}` · **RELEASE READY: NO** · "
    f"Canlı durum: `bash scripts/kalan-isler.sh`"
)
docs = [
    "docs/PSYCHIC_P0_START.md",
    "docs/P1_DEVICE_START.md",
    "docs/P2_PLAY_STORE_START.md",
    "docs/FLUTTER_ENTegrasyon_KILAVUZU.md",
    "docs/RELEASE_CHECKLIST.md",
    "docs/GITHUB_ACTIONS_CI.md",
    "docs/PLAY_STORE_PRODUCTION_ACCESS.md",
    "docs/KULLANICI_TEST_KILAVUZU.md",
    "docs/DOCS_RELEASE_INDEX.md",
    "docs/API_ENDPOINT_MATRIX.md",
    "docs/LIVE_PSYCHICS_REMAINING.md",
    "docs/USER_TEST_QUICK_REF.md",
    "docs/USER_DEVICE_TEST_LOG.md",
    "docs/PLAY_STORE_AGENT_CHECKLIST.md",
    "docs/RELEASE_GATE_CLOSURE.md",
]
pat = re.compile(r"> \*\*Güncel \([^)]*\)[^\n]*")
for rel in docs:
    p = root / rel
    if not p.is_file():
        continue
    text = p.read_text(encoding="utf-8")
    if pat.search(text):
        text = pat.sub(header, text, count=1)
        p.write_text(text, encoding="utf-8")

kalan = root / "docs/KALAN_ISLER.md"
if kalan.is_file():
    t = kalan.read_text(encoding="utf-8")
    t = re.sub(r"> \*\*Sürüm:\*\* `[^`]*`[^\n]*", surum, t, count=1)
    t = re.sub(r"^# Kalan işler — özet \([^)]*\)", f"# Kalan işler — özet ({date})", t, count=1)
    kalan.write_text(t, encoding="utf-8")

live = root / "docs/LIVE_PSYCHICS_REMAINING.md"
if live.is_file() and run:
    t = live.read_text(encoding="utf-8")
    t = re.sub(
        r"^\*\*APK:\*\* `[^`]*` — \[Run [0-9]+\]\([^\)]*\)[^\n]*",
        f"**APK:** `{version}` — [Run {run}](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/{run}) FINAL PASS",
        t,
        count=1,
        flags=re.M,
    )
    t = re.sub(
        r"^APK: `[^`]*` — iki cihaz",
        f"APK: `{version}` — iki cihaz",
        t,
        count=1,
        flags=re.M,
    )
    live.write_text(t, encoding="utf-8")

suffix = f", run {run}" if run else ""
print(f"✅ Doc headers → {version} ({date}){suffix}")
PY
