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
export SYNC_RUN_URL=""
if [[ -f "$ROOT/docs/LATEST_APK_BUILD.md" ]]; then
  SYNC_RUN=$(grep -oE 'Run [0-9]+' "$ROOT/docs/LATEST_APK_BUILD.md" | head -1 | sed 's/Run //' || true)
  if [[ -n "$SYNC_RUN" ]]; then
    SYNC_RUN_URL="https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/${SYNC_RUN}"
  fi
fi

python3 <<'PY'
import os
import re
from pathlib import Path

root = Path(os.environ["SYNC_ROOT"])
version = os.environ["SYNC_VERSION"]
date = os.environ["SYNC_DATE"]
run = os.environ.get("SYNC_RUN", "")
run_url = os.environ.get("SYNC_RUN_URL", "")
header = (
    f"> **Güncel ({date}):** **`{version}`** · Release gate **FINAL PASS** · "
    f"**RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)"
)
surum_release = (
    f"> **Sürüm:** `{version}` · **RELEASE READY: NO** · "
    f"[`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)"
)
surum_kalan = (
    f"> **Sürüm:** `{version}` · **RELEASE READY: NO** · "
    f"Canlı durum: `bash scripts/kalan-isler.sh`"
)
surum_quick = (
    f"> **Sürüm:** `{version}` · **RELEASE READY: NO** · "
    f"Agent prep **✅ TAMAM** · Cihaz + keystore sizde"
)
surum_play = (
    f"> **Sürüm:** `{version}` · Cihaz P0/P1 **sonra** · Agent prep **✅ TAMAM**"
)

guncel_docs = [
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
    "docs/RELEASE_GATE_CLOSURE.md",
    "docs/FAZ13_RELEASE_STATUS.md",
    "docs/REMAINING_WORK.md",
]
pat_guncel = re.compile(r"> \*\*Güncel \([^)]*\)[^\n]*")
for rel in guncel_docs:
    p = root / rel
    if not p.is_file():
        continue
    text = p.read_text(encoding="utf-8")
    if pat_guncel.search(text):
        text = pat_guncel.sub(header, text, count=1)
        p.write_text(text, encoding="utf-8")

# > **Sürüm:** satırları (dosyaya göre şablon)
surum_map = {
    "docs/USER_DEVICE_TEST_LOG.md": surum_release,
    "docs/USER_TEST_QUICK_REF.md": surum_quick,
    "docs/PLAY_STORE_AGENT_CHECKLIST.md": surum_play,
    "docs/KALAN_ISLER.md": surum_kalan,
}
pat_surum = re.compile(r"> \*\*Sürüm:\*\* `[^`]*`[^\n]*")
for rel, repl in surum_map.items():
    p = root / rel
    if p.is_file() and pat_surum.search(p.read_text(encoding="utf-8")):
        t = pat_surum.sub(repl, p.read_text(encoding="utf-8"), count=1)
        p.write_text(t, encoding="utf-8")

kalan = root / "docs/KALAN_ISLER.md"
if kalan.is_file():
    t = kalan.read_text(encoding="utf-8")
    t = re.sub(r"^# Kalan işler — özet \([^)]*\)", f"# Kalan işler — özet ({date})", t, count=1)
    kalan.write_text(t, encoding="utf-8")

# DOCS_RELEASE_INDEX üst tablo
idx = root / "docs/DOCS_RELEASE_INDEX.md"
if idx.is_file() and run and run_url:
    t = idx.read_text(encoding="utf-8")
    t = re.sub(r"^\*\*Son güncelleme:\*\* [^\n]*", f"**Son güncelleme:** {date}", t, count=1, flags=re.M)
    t = re.sub(r"^\*\*Sürüm:\*\* `[^`]*`", f"**Sürüm:** `{version}`", t, count=1, flags=re.M)
    t = re.sub(
        r"^\*\*Release gate:\*\* \*\*FINAL PASS\*\* — \[Run [0-9]+\]\([^\)]*\)",
        f"**Release gate:** **FINAL PASS** — [Run {run}]({run_url})",
        t,
        count=1,
        flags=re.M,
    )
    t = re.sub(
        r"\| `\.\./mobile/CHANGELOG\.md` \| \*\*[0-9.]+\+[0-9]+\*\* sürüm geçmişi \|",
        f"| [`../mobile/CHANGELOG.md`](../mobile/CHANGELOG.md) | **{version}** sürüm geçmişi |",
        t,
        count=1,
    )
    idx.write_text(t, encoding="utf-8")

# GITHUB_ACTIONS_CI tablo
gh = root / "docs/GITHUB_ACTIONS_CI.md"
if gh.is_file() and run and run_url:
    t = gh.read_text(encoding="utf-8")
    t = re.sub(r"^\*\*Son güncelleme:\*\* [^\n]*", f"**Son güncelleme:** {date}", t, count=1, flags=re.M)
    t = re.sub(
        r"\| `build-apk\.yml` \| ✅ \*\*FINAL PASS\*\* \| \[Run [0-9]+\]\([^\)]*\) \|",
        f"| `build-apk.yml` | ✅ **FINAL PASS** | [Run {run}]({run_url}) |",
        t,
        count=1,
    )
    t = re.sub(r"\| `apk-latest` \| ✅ \| `[^`]*` \|", f"| `apk-latest` | ✅ | `{version}` |", t, count=1)
    gh.write_text(t, encoding="utf-8")

# RELEASE_CHECKLIST gövde sürüm satırı
rc = root / "docs/RELEASE_CHECKLIST.md"
if rc.is_file():
    t = rc.read_text(encoding="utf-8")
    t = re.sub(r"^Sürüm: \*\*[0-9.]+\+[0-9]+\*\*", f"Sürüm: **{version}**", t, count=1, flags=re.M)
    rc.write_text(t, encoding="utf-8")

# KULLANICI_TEST_KILAVUZU ikinci satır
kt = root / "docs/KULLANICI_TEST_KILAVUZU.md"
if kt.is_file() and run and run_url:
    t = kt.read_text(encoding="utf-8")
    t = re.sub(
        r"^\*\*Sürüm:\*\* `[^`]*` · \*\*Son release gate:\*\* \[FINAL PASS\]\([^\)]*\)",
        f"**Sürüm:** `{version}` · **Son release gate:** [FINAL PASS]({run_url})",
        t,
        count=1,
        flags=re.M,
    )
    kt.write_text(t, encoding="utf-8")

# RELEASE_GATE_CLOSURE başlık + metadata satırı
rg = root / "docs/RELEASE_GATE_CLOSURE.md"
if rg.is_file() and run and run_url:
    t = rg.read_text(encoding="utf-8")
    t = re.sub(
        r"^# Release Gate Closure — [0-9.]+\+[0-9]+",
        f"# Release Gate Closure — {version}",
        t,
        count=1,
        flags=re.M,
    )
    t = re.sub(
        r"\| apk-latest metadata \| ✅ PASS \| Ayrı adım; title `Canlifal APK [^`]*` \|",
        f"| apk-latest metadata | ✅ PASS | Ayrı adım; title `Canlifal APK {version}` |",
        t,
        count=1,
    )
    t = re.sub(
        r"\| `build-apk\.yml` \| ✅ \| \[Run [0-9]+\]\([^\)]*\) \|",
        f"| `build-apk.yml` | ✅ | [Run {run}]({run_url}) |",
        t,
        count=1,
    )
    rg.write_text(t, encoding="utf-8")

# P2_PLAY_STORE_START gövde
p2 = root / "docs/P2_PLAY_STORE_START.md"
if p2.is_file():
    t = p2.read_text(encoding="utf-8")
    t = re.sub(
        r"Mobil release gate CI: \*\*FINAL PASS\*\* \(`[0-9.]+\+[0-9]+`\)",
        f"Mobil release gate CI: **FINAL PASS** (`{version}`)",
        t,
        count=1,
    )
    p2.write_text(t, encoding="utf-8")

live = root / "docs/LIVE_PSYCHICS_REMAINING.md"
if live.is_file() and run and run_url:
    t = live.read_text(encoding="utf-8")
    t = re.sub(
        r"^\*\*APK:\*\* `[^`]*` — \[Run [0-9]+\]\([^\)]*\)[^\n]*",
        f"**APK:** `{version}` — [Run {run}]({run_url}) FINAL PASS",
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

# RELEASE_USER_NEXT_STEPS — özel üst satır + tablo
user_next = root / "docs/RELEASE_USER_NEXT_STEPS.md"
if user_next.is_file():
    header_un = (
        f"> **Güncel ({date}):** **`{version}`** · **RELEASE READY: NO** · "
        f"Agent prep **✅ TAMAM** · Cihaz + keystore + Play **sizde**"
    )
    t = user_next.read_text(encoding="utf-8")
    t = re.sub(r"> \*\*Güncel \([^)]*\)[^\n]*", header_un, t, count=1)
    if run and run_url:
        t = re.sub(
            r"\| Release gate CI \| ✅ FINAL PASS \[[0-9]+\]\([^\)]*\) \|",
            f"| Release gate CI | ✅ FINAL PASS [{run}]({run_url}) |",
            t,
            count=1,
        )
        t = re.sub(
            r"\| ZIP economy v2 \(Faz 1–24\) \| ✅ `[0-9.]+\+[0-9]+`",
            f"| ZIP economy v2 (Faz 1–24) | ✅ `{version}`",
            t,
            count=1,
        )
    user_next.write_text(t, encoding="utf-8")

# REMAINING_WORK — Run ID satırları
rw = root / "docs/REMAINING_WORK.md"
if rw.is_file() and run and run_url:
    t = rw.read_text(encoding="utf-8")
    t = re.sub(
        r"APK Run \[`[0-9]+`\]\([^\)]*\)",
        f"APK Run [`{run}`]({run_url})",
        t,
        count=1,
    )
    t = re.sub(
        r"apk-latest \+ metadata PASS \(Run `[0-9]+`\)",
        f"apk-latest + metadata PASS (Run `{run}`)",
        t,
        count=1,
    )
    t = re.sub(
        r"\| docs/LATEST_APK_BUILD \| `\[x\]` \| Run `[0-9]+` \|",
        f"| docs/LATEST_APK_BUILD | `[x]` | Run `{run}` |",
        t,
        count=1,
    )
    rw.write_text(t, encoding="utf-8")

suffix = f", run {run}" if run else ""
print(f"✅ Doc headers → {version} ({date}){suffix}")
PY
