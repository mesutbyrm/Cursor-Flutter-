# Kalan işler — canlı takip listesi

**Son güncelleme:** 2026-08-19 21:09 UTC — `1.0.285+321`  
**Agent:** Kod otomasyonu tamam — tek bloker jeton + M5 cihaz (`bash scripts/faz0-handoff.sh`)  
**Master:** `docs/PHASE_MASTER_TRACKER.md` | **Test:** `docs/PHASE_TEST_REPORT.md` (15 PASS)

---

## Durum özeti

| Alan | Durum | Not |
|------|--------|-----|
| FAZ 0 | `[~]` | A1–A8 ✅; A9 M5/jeton |
| FAZ 1–11 | `[x]` otomatik | 15 PASS — `PHASE_TEST_REPORT.md` |
| FAZ 12 | `[~]` | Otomatik kapılar ✅; cihaz 25 senaryo |
| FAZ 13 | `[~]` | CI APK ✅ |
| APK `1.0.285+321` | `[x]` | apk-latest (CI) |
| P0 müzik kod | `[x]` | M5/M7 manuel |
| P0 PK kod | `[x]` | M5/M7 manuel (bildirim + davet) |

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

## Oturum günlüğü (2026-08-19 devam 24)

- `faz0-handoff.sh` — agent→kullanıcı devir teslim betiği (jeton + M5 checklist)
- `faz0-status.sh` admin URL + kod otomasyonu tamam mesajı
- FAZ12 otomatik 4/4 doğrulandı

## Oturum günlüğü (2026-08-19 devam 23)

- Push `/home` ve `/index` → `/feed` testleri (4 PASS)
- PK REST davet parse: `invited` durumu testi
- `admin-jeton-cheatsheet.sh` admin URL düzeltmesi

## Oturum günlüğü (2026-08-19 devam 22)

- PK parse testi: `pkBattleId` + ayrı `inviteId` → effectiveId
- `wait-for-jeton.sh` admin panel URL hatırlatması
- Faz testleri yenilendi (15 PASS)

## Oturum günlüğü (2026-08-19 devam 21)

- PK bildirim metin yedeklemesi testleri (PK/düello → voice-room veya /live) — 10 PASS
- faz0-verify yenilendi: AUTOMATED_PASS; jeton=0

## Oturum günlüğü (2026-08-19 devam 20)

- Push navigation testleri: `/` → `/feed`, PK push → voice-room (3 PASS)
- Jeton=0 bloker devam; otomatik kapılar geçer durumda

## Oturum günlüğü (2026-08-19 devam 19)

- PK bildirim yönlendirme testleri: canlı yayın path + targetId yok → `/live` (8 PASS)
- Jeton hâlâ 0 — M5/M7/A9 manuel bloker

## Oturum günlüğü (2026-08-19 devam 18)

- Canlı PK davet listesi hata: `ApiException.userMessage` (live_pk_invite_page)

## Oturum günlüğü (2026-08-19 devam 17)

- Oda keşif provider + PK geçmişi: `ApiException.userMessage` (ham exception yok)
- FAZ1 userMessage kapsamı voice_hub discover/history genişletildi

## Oturum günlüğü (2026-08-19 devam 16)

- Müzik arama sheet + oda moderasyon (kick/ban/mute): `ApiException.userMessage`
- `pkChallengerRoomLabelFromRooms` saf fonksiyon + 2 test (9 PASS toplam)
- `faz0-status.sh` apk-latest release adı gösterir

## Oturum günlüğü (2026-08-19 devam 15)

- `pickPkInviteTargetRoom` saf fonksiyon + aktif oda önceliği testleri (7 PASS)
- PK dialog hata: `ApiException.userMessage` (ham exception yok)
- `LATEST_APK_BUILD.md` 1.0.285+321 ile senkron; `print-build-status` apk-latest adı

## Oturum günlüğü (2026-08-19 devam 14)

- PK `opponentVoiceRoomId` eşleşmesi için birim test eklendi (`pk_opponent_room_filter_test.dart`)
- faz0-verify yenilendi: AUTOMATED_PASS; jeton=0 bloker devam
- APK CI: run 32298394670 başarılı; 32299026600 devam ediyor

## Oturum günlüğü (2026-08-19 devam 13)

- Otomatik doğrulama yenilendi: faz0-verify AUTOMATED_PASS, 15/15 faz testi, FAZ12 4/4, FAZ11 PASS
- Jeton hâlâ 0 — M5/M7/A9 manuel bloker devam
- `voice_room_session_utils.dart` yinelenen import temizlendi; `m5-device-prep.sh` PK test hatırlatması

## Oturum günlüğü (2026-08-19 devam 12)

- **1.0.285+321:** PK bildirimi `/` fix, PK davet donması, oda geçişi presence leave
- **1.0.284+320:** Sesli oda müzik isteği ANR (`deferVoiceMusicSubmit`)

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
