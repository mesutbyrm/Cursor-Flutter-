# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.733+786` |
| Tarih (UTC) | 2026-10-07 08:24 |
| Commit | [`2358b3e953c58d9cf444c78f2fd8df1583580cee`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/2358b3e953c58d9cf444c78f2fd8df1583580cee) |
| İş akışı | [Run 37591278226](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37591278226) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.733+786 (2026-10-07) — Backend gerektirmeyen düzeltmeler (GIFT-001, BG-002, PK-001, VOICE-006)

- **GIFT-001 video hediye:** süre (backend varsayılanı 3000 ms) veya `gift_finished` olayı oynayan videoyu artık kesmiyor; bitiş videonun sonuna ertelenir (`GiftVideoHold`, en fazla +60 sn). Canlı yayın, sesli oda ve PK overlay'leri
- **BG-002 arka plan:** SSE `room_update` içindeki `backgroundImage` (backend sütunu) ve iç içe `room.backgroundImage` okunuyor; eski anahtarlar korunuyor
- **PK-001:** `/api/pk/active`, `/leaderboard`, `/{matchId}`, `/{matchId}/stream` ana backend'e (SSE ile aynı veritabanı). Canlı karşılaştırma: games backend sıralaması boş, ana site dolu. Yalnız games'te olan `POST /api/pk/request` games'te kalır
- **VOICE-006 / GIFT-003:** gift köprüsü ve sesli oda SSE süzgeci tek eşleştirme kuralını (`roomKeysEquivalent`) kullanır; rastgele sonek eşleşmesi (`"11"`≈`"1"`) kaldırıldı
- Gerçek cihaz: **BLOCKED**


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
