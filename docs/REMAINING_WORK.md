# Kalan işler — canlı takip listesi

**Son güncelleme:** 2026-08-19 15:44 UTC — `1.0.283+319`  
**Master:** `docs/PHASE_MASTER_TRACKER.md` | **Test:** `docs/PHASE_TEST_REPORT.md` (15 PASS)

---

## Durum özeti

| Alan | Durum | Not |
|------|--------|-----|
| FAZ 0 | `[~]` | A1–A8 ✅; A9 M5/jeton |
| FAZ 1–11 | `[x]` otomatik | 15 PASS — `PHASE_TEST_REPORT.md` |
| FAZ 12 | `[~]` | Otomatik kapılar ✅; cihaz 25 senaryo |
| FAZ 13 | `[~]` | CI APK ✅ |
| APK `1.0.283+319` | `[x]` | apk-latest (CI) |
| P0 müzik kod | `[x]` | M5/M7 manuel |

---

## Tek manuel bloker (tüm fazlar)

| # | İş | Çözüm |
|---|-----|--------|
| B1 | Jeton ≥10 | `bash scripts/admin-jeton-cheatsheet.sh` |
| B2 | M7 HTTP 200 | `bash scripts/m7-on-jeton.sh` |
| B3 | M5 cihaz | `bash scripts/m5-device-prep.sh` |
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

## Oturum günlüğü (2026-08-19 devam 11)

- **1.0.283+319:** LiveGiftPanel + PremiumGiftPanel jeton hata UX (sessiz catch kaldırıldı)

## Oturum günlüğü (2026-08-19 devam 10)

- **1.0.282+318:** Canlı hediye + oyun lobisi + fal jeton UX

## Oturum günlüğü (2026-08-19 devam 9)

- **1.0.281+317:** Hediye gönderimi jeton diyaloğu + FAZ0_STATUS güncelleme

## Oturum günlüğü (2026-08-19 devam 8)

- **1.0.280+316:** RTC/Basic state error → `showJetonAwareError`; FAZ0/M5 doc sync

## Oturum günlüğü (2026-08-19 devam 7)

- **1.0.279+315:** Sesli oda tüm `err` SnackBar → `showJetonAwareError`; üyelik jeton diyaloğu

## Oturum günlüğü (2026-08-19 devam 6)

- **1.0.278+314:** `showJetonAwareError` — !duyuru, RTC/basic şarkı, oyunlar

## Oturum günlüğü (2026-08-19 devam 5)

- **1.0.277+313:** Falcı profil + fal sheet jeton UX (`showInsufficientJetonDialog` / Görevler)

## Oturum günlüğü (2026-08-19 devam 4)

- **1.0.275+311:** Komut paneli Görevler butonu + `m5-device-prep.sh`
- **1.0.274+310:** Oda açma jeton diyaloğu + FAZ0 checklist

## Oturum günlüğü (2026-08-19 devam 3)

- **1.0.270+306:** Growth Hub tamamlanan görev ilerlemesi, mission rotaları, claim tap

## Oturum günlüğü (2026-08-19 devam 2)

- **1.0.269+305:** Daily missions `type`/`reward`/`earnedJeton` parse; `taskType` claim; Growth Hub jeton daily_login
- `daily_task_entity_test.dart` (FAZ2)

## Oturum günlüğü (2026-08-19 devam)

- `wait-for-jeton.sh` + `m5-ready.sh` — jeton eklenince otomatik M7/M5-preflight
- Jeton probe: daily-missions tamam, credits=107, jeton=0 (admin gerekli)
- FAZ12 otomatik 4/4 doğrulandı

## Oturum günlüğü (2026-08-18 devam)

- `PHASE_MASTER_TRACKER.md` + `run-phase-tests.sh` + `phase-progress.sh`
- FAZ3–13 parity/status belgeleri
- Social `getUserPosts` kılavuz ucu (`1.0.267+303`)
- Faz testleri: 12 PASS, 0 FAIL
