# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.457+495` |
| Tarih (UTC) | 2026-09-09 16:42 |
| Commit | [`2925322640ef6c65acdea15c61771de45b0a3303`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/2925322640ef6c65acdea15c61771de45b0a3303) |
| İş akışı | [Run 34376452733](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34376452733) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.457+495 (2026-09-09) — PK ingest, sesli davet, sıralama, falcı bahşiş, bot

### PK (canlı + sesli)
- Canlı PK SSE ingest: sahip yayınlar için `liveVideoPkProvider` senkronu; yabancı battle yazılmaz
- Davet sonrası `liveVideoPkProvider.applyRemoteBattle` — karşı taraf anında davet görür
- Sesli PK: `guestUserId` zorunlu değil; `opponentRoomId` ile davet gönderilir (0 çevrimiçi oda)
- PK daveti: bot hesapları engellendi

### Sıralama bildirimi
- Saatlik/günlük top 3 yalnızca saat/gün başında uygulamada olanlara gösterilir
- Sonradan giren kullanıcılar geçmiş kutlamayı görmez (oturum bazlı pencere anahtarı)

### Canlı falcı
- Bahşiş SSE `eventId` dedupe; falcıya anında «X size bahşiş attı» popup
- `timerStarted` SSE ile mikrofon/kamera yayın senkronu

### Bot kısıtları
- Müzik isteği (`!istek`, hub, API) bot hesaplarda engellendi


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
