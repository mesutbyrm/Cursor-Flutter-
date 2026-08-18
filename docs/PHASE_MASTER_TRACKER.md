# Faz master takip — Canlifal Flutter

**Son güncelleme:** 2026-08-18  
**Kural:** Her faz **AUTOMATED_PASS** + manuel kapılar → **PASS**

---

## Özet tablo

| Faz | Ad | Otomatik | Manuel bloker | Durum |
|-----|-----|----------|---------------|--------|
| **0** | Audit | ✅ A1–A8, M1–M12, 93 test | M5 cihaz, M7 jeton | 🔄 INCOMPLETE |
| **1** | Core + Auth | ✅ error envelope, testler | God-file refactor | 🔄 HAZIRLIK |
| **2** | Profile | ✅ parity doc | Skeleton UI | 🔄 HAZIRLIK |
| **3** | Social | ✅ getUserPosts fix | Story repo yüzeyi | 🔄 HAZIRLIK |
| **4** | Fortune | ✅ modül mevcut | SSE body parity | 🔄 HAZIRLIK |
| **5** | Live | ✅ 36 test | Comments endpoint | 🔄 HAZIRLIK |
| **6** | Voice | ✅ 93 test, M1–M12 | M5 PASS | 🔄 HAZIRLIK |
| **7** | Gifts | ✅ 47 test | gifts/send canonical | 🔄 HAZIRLIK |
| **8** | Shorts | ⏸ test yok | Pagination | 🔄 HAZIRLIK |
| **9** | Messages | ⏸ codec test | SSE path, request | 🔄 HAZIRLIK |
| **10** | Performance | ✅ perf modülleri | Cihaz profil | ⏸ |
| **11** | Security | ✅ ApiException guard | Secret scan CI | ⏸ |
| **12** | E2E QA | ⏸ | 25 senaryo cihaz | ⏸ |
| **13** | Release | ✅ APK CI | Signing | ⏸ |

---

## Komutlar

```bash
bash scripts/phase-progress.sh      # bu özet
bash scripts/run-phase-tests.sh     # faz testleri
bash scripts/faz0-verify.sh           # FAZ0 kapıları
bash scripts/m7-on-jeton.sh           # jeton sonrası M7
```

---

## Kapı tanımları

| Etiket | Anlam |
|--------|--------|
| **AUTOMATED_PASS** | Unit/API testleri + parity doc tamam |
| **PASS** | Otomatik + manuel (cihaz/jeton) tamam |
| **HAZIRLIK** | Kod büyük ölçüde var; kapanış maddeleri sürüyor |
| **INCOMPLETE** | Resmi kapanış bekliyor |

---

## Sıra (kullanıcı aksiyonu)

1. Admin → test hesabına **≥50 jeton**
2. `bash scripts/m7-on-jeton.sh` → M7 HTTP 200
3. `docs/M5_DEVICE_TEST_CHECKLIST.md` → FAZ0 PASS
4. FAZ1–11 otomatik kapanış testleri (`run-phase-tests.sh`)
5. FAZ12 cihaz QA → FAZ13 release
