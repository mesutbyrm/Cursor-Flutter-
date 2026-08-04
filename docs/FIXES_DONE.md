# CanliFal — Fixes Done & Remaining

**Date:** 2026-08-04  
**Branch:** `main`  
**Sürüm:** `1.0.129+163`

---

## Tamamlanan senkronizasyon (10/10)

| Modül | Durum |
|-------|-------|
| 1. Sesli sohbet odaları | ✅ lock/kick koltuk UI + API |
| 2. Canlı yayın | ✅ TRTC reconnect + moderasyon unmute/unban |
| 3. Canlı falcılar | ✅ Üretim sessions önceliği |
| 4. Sosyal | ✅ Post detay sayfası + deep link |
| 5. CDN | ✅ Genişletilmiş prefix + stories cache |
| 6. Hediyeler | ✅ Backend süre tam animasyon |
| 7. Tencent RTC | ✅ TRTC-only (`flutter_webrtc` kaldırıldı) |
| 8. Performans | ✅ Provider entry split, cache TTL |
| 9. API senkronizasyonu | ✅ Kılavuz uyumu |
| 10. Test / rapor | ✅ 366 test, acceptance OK |

---

## Test

- `flutter test`: **366 passed**, 2 skipped
- `scripts/run-acceptance-tests.sh`: **OK**

Detay: `docs/BACKEND_FLUTTER_SYNC_REPORT.md`
