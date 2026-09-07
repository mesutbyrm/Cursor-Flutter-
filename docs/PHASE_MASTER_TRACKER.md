# Faz master takip — Canlifal Flutter



> **Güncel (2026-09-07):** **`1.0.371+409`** · Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

**Son güncelleme:** 2026-09-07 — APK **`1.0.371+409`** · Release gate **FINAL PASS** ([Run 34146919509](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34146919509))  
**Canlı checklist:** [`RELEASE_USER_NEXT_STEPS.md`](RELEASE_USER_NEXT_STEPS.md) · `bash scripts/kalan-isler.sh` · [`PSYCHIC_P0_START.md`](PSYCHIC_P0_START.md)  
**Jeton (P0-j):** ✅ kapandı (~100k, 2026-09-07) · **Falcı:** host onaylı listede ✅ — [`PSYCHIC_TELLER_STATUS.md`](PSYCHIC_TELLER_STATUS.md)  
**Faz testleri:** CI 1081+ pass (`docs/PHASE_TEST_REPORT.md` tarihsel)

---

## Özet tablo (2026-09-07)

| Faz | Ad | Otomatik | Manuel bloker | Durum |
|-----|-----|----------|---------------|--------|
| **0** | Audit | ✅ A1–A8, M1–M12 | M5 cihaz (müzik) | 🔄 cihaz testi |
| **1** | Core + Auth | ✅ | — | ✅ SSE SoT (1.0.370) |
| **2–11** | Modüller | ✅ otomatik | — | ✅ |
| **12** | E2E QA | ✅ CI kapıları | 25 senaryo + **Psychic P0** | 🔄 **P0 OPEN** |
| **13** | Release | ✅ **FINAL PASS** | Psychic 2-cihaz | 🔄 **RELEASE READY: NO** |

**Agent işleri tamam.** Kalan: cihaz kabul testleri (Psychic öncelik).

---

## Komutlar

```bash
bash scripts/phase-progress.sh
bash scripts/run-phase-tests.sh          # 15 PASS
bash scripts/faz12-automated-gates.sh    # FAZ12 otomatik
bash scripts/faz11-security-scan.sh
bash scripts/m7-on-jeton.sh
bash scripts/probe-jeton-earn.sh          # jeton kazanım tanısı
bash scripts/run-voice-seat-acceptance.sh  # presence/koltuk/SSE (jeton yok)
bash scripts/m5-preflight.sh               # müzik + voice seat + jeton + unit
bash scripts/faz0-next.sh                # durum + cheatsheet + probe (+ M7 jeton varsa)
bash scripts/wait-for-jeton.sh 10 3600   # jeton eklenince otomatik M7+M5-preflight
bash scripts/m5-ready.sh                # jeton sonrası
```

---

## Resmi PASS için kalan (agent yapamaz)

1. **Jeton ≥10** → admin panel
2. **M5/M7** → `m7-on-jeton.sh` + cihaz checklist
3. **FAZ12** → Android 25 senaryo
4. **FAZ13** → signing secrets (opsiyonel; CI apk-latest çalışıyor)
