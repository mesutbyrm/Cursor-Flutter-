# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 10:27:46 UTC |
| Run | local-1786271262 |
| API | https://canlifal.com |
| Geçti | 7 |
| Başarısız | 4 |
| Atlandı | 1 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| S6 | TEST_VIEWER/HOST secrets | ✅ PASS | ACCEPTANCE_USER_* + HOST_* |
| S6 | TEST_PSYCHIC secret | ✅ PASS | HOST onaylı falcı fallback |
| S6 | Backend production | ✅ PASS | https://canlifal.com erişilebilir |
| S6 | TRTC credentials | ✅ PASS | sdkAppId+userSig backend OK |
| S6 | ADB device | ⏸️ BLOCKED | cihaz bağlı değil — RTC/ses/camera test edilemez |
| S6 | Admin jeton top-up | ❌ FAIL | ACCEPTANCE_ADMIN_* yok — test jetonu otomatik eklenemez |
| S6 | VIEWER jeton | ❌ FAIL | bakiye=10 — hediye/müzik için test jetonu gerekli |
| S6 | Auth JWT | ✅ PASS | me=200 anon=401 |
| S6 | Live create | ✅ PASS | streamId=cmslnsgpg00ovpk08jqzfm0bg |
| S6 | Gift send | ❌ FAIL | HTTP 400 before=10 after=10 |
| S6 | Auto fortune share | ✅ PASS | POST /api/social/posts + feed OK |
| S6 | Live fortune request | ❌ FAIL | HTTP 500 — backend 500 |

**Release APK oluşturulmadı** — yukarıdaki başarısız testleri düzeltin.
