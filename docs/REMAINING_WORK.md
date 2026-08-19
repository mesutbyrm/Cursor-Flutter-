# Kalan işler — canlı takip listesi

**Son güncelleme:** 2026-08-19 11:30 UTC — FAZ1–11 otomatik PASS (15 test) | FAZ12 otomatik 4/4  
**Master:** `docs/PHASE_MASTER_TRACKER.md` | **Test:** `docs/PHASE_TEST_REPORT.md` (12 PASS)

---

## Durum özeti

| Alan | Durum | Not |
|------|--------|-----|
| FAZ 0 | `[~]` | A1–A8 ✅; A9 M5/jeton |
| FAZ 1–11 | `[x]` otomatik | 15 PASS — `PHASE_TEST_REPORT.md` |
| FAZ 12 | `[~]` | Otomatik kapılar ✅; cihaz 25 senaryo |
| FAZ 13 | `[~]` | CI APK ✅ |
| APK `1.0.268+304` | `[x]` | apk-latest aktif |
| P0 müzik kod | `[x]` | M5/M7 manuel |

---

## Tek manuel bloker (tüm fazlar)

| # | İş | Çözüm |
|---|-----|--------|
| B1 | Jeton ≥10 | Admin panel → `cursor.test.1786235468@mailinator.com` |
| B2 | M7 HTTP 200 | `bash scripts/m7-on-jeton.sh` |
| B3 | M5 cihaz | `docs/M5_DEVICE_TEST_CHECKLIST.md` |
| B4 | FAZ12 E2E | 25 senaryo Android |

---

## Faz otomatik testleri (2026-08-18)

| Faz | Sonuç |
|-----|--------|
| FAZ1 core/network | PASS |
| FAZ2 profile | PASS |
| FAZ3 social | PASS |
| FAZ4 fortune | PASS |
| FAZ5 live | PASS |
| FAZ6 voice_hub (93) | PASS |
| FAZ7 gifts | PASS |
| FAZ8 shorts | PASS (3 test dosyası) |
| FAZ9 messages | PASS |
| FAZ0 MCP | PASS |

`bash scripts/run-phase-tests.sh`

---

## P0 — Müzik (FAZ 6 bloker)

M1–M12 `[x]` | M5 `[ ]` | M7 `[~]` jeton

---

## FAZ 0 audit

A1–A8 `[x]` | A9 `[ ]` M5 PASS

---

## FAZ 1–13 dosyaları

| Faz | Doc |
|-----|-----|
| 1 | `FAZ1_STATUS.md`, `FAZ1_API_ERROR_ENVELOPE.md` |
| 2 | `FAZ2_PROFILE_PARITY.md` |
| 3 | `FAZ3_SOCIAL_PARITY.md` |
| 4–13 | `FAZ4_FORTUNE_PARITY.md` … `FAZ13_RELEASE_STATUS.md` |

---

## Oturum günlüğü (2026-08-19 devam)

- `wait-for-jeton.sh` + `m5-ready.sh` — jeton eklenince otomatik M7/M5-preflight
- Jeton probe: daily-missions tamam, credits=107, jeton=0 (admin gerekli)
- FAZ12 otomatik 4/4 doğrulandı

## Oturum günlüğü (2026-08-18 devam)

- `PHASE_MASTER_TRACKER.md` + `run-phase-tests.sh` + `phase-progress.sh`
- FAZ3–13 parity/status belgeleri
- Social `getUserPosts` kılavuz ucu (`1.0.267+303`)
- Faz testleri: 12 PASS, 0 FAIL
