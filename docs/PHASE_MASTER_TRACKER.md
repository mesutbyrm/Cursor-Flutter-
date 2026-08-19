# Faz master takip — Canlifal Flutter

**Son güncelleme:** 2026-08-19 15:35 UTC — APK `1.0.281+317`  
**Faz testleri:** 15 PASS, 0 FAIL (`docs/PHASE_TEST_REPORT.md`)

---

## Özet tablo

| Faz | Ad | Otomatik | Manuel bloker | Durum |
|-----|-----|----------|---------------|--------|
| **0** | Audit | ✅ A1–A8, M1–M12 | M5 cihaz, M7 jeton | 🔄 INCOMPLETE |
| **1** | Core + Auth | ✅ **AUTOMATED_PASS** | God-file refactor | ✅ otomatik |
| **2** | Profile | ✅ **AUTOMATED_PASS** | Skeleton UI | ✅ otomatik |
| **3** | Social | ✅ **AUTOMATED_PASS** | Story repo | ✅ otomatik |
| **4** | Fortune | ✅ **AUTOMATED_PASS** | SSE body | ✅ otomatik |
| **5** | Live | ✅ **AUTOMATED_PASS** | Comments uç | ✅ otomatik |
| **6** | Voice | ✅ **AUTOMATED_PASS** | M5 cihaz | ✅ otomatik |
| **7** | Gifts | ✅ **AUTOMATED_PASS** | gifts/send | ✅ otomatik |
| **8** | Shorts | ✅ **AUTOMATED_PASS** | Pagination prod | ✅ otomatik |
| **9** | Messages | ✅ **AUTOMATED_PASS** | SSE/request UI | ✅ otomatik |
| **10** | Performance | ✅ **AUTOMATED_PASS** | Cihaz profil (opsiyonel) | ✅ otomatik |
| **11** | Security | ✅ **AUTOMATED_PASS** | — | ✅ otomatik |
| **12** | E2E QA | ✅ otomatik kapılar PASS | 25 senaryo cihaz | 🔄 INCOMPLETE |
| **13** | Release | ✅ CI APK | Signing | 🔄 HAZIRLIK |

---

## Komutlar

```bash
bash scripts/phase-progress.sh
bash scripts/run-phase-tests.sh          # 15 PASS
bash scripts/faz12-automated-gates.sh    # FAZ12 otomatik
bash scripts/faz11-security-scan.sh
bash scripts/m7-on-jeton.sh
bash scripts/probe-jeton-earn.sh          # jeton kazanım tanısı
bash scripts/m5-device-prep.sh           # M5 cihaz hazırlık özeti
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
