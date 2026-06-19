# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.291+294` |
| Tarih (UTC) | 2026-06-19 13:35 |
| Commit | [`fbf1deb937af00bd05051a7029b484eca169cd97`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/fbf1deb937af00bd05051a7029b484eca169cd97) |
| İş akışı | [Run 27828322259](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27828322259) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.291+294 (2026-06-19)

### Production readiness sprint

- **Görüntülü arama:** `IncomingVideoCallScreen`, 30 sn timeout, kabul/red/meşgul, kaçırılan arama bildirimi
- **SSE:** `BaseSseService`, reconnect 1→30 sn; `ChatRoomSseService`, `NotificationSseService`, `FalSseService`, `MessageSseService`
- **Falcı paneli:** SSE canlı istekler, aktif süre, dakika ücreti, anlık kazanç
- **Online sayılar:** 25 sn poll kaldırıldı; SSE presence ile keşfet listesi
- **Provider modülleri:** `voice_room_*_provider.dart` barrel ayrımı
- **Crashlytics:** Firebase Crashlytics + Sentry DSN stub
- **Offline:** `CacheFirstLoader` + bildirimler cache-first
- **Tablet:** `NavigationRail` (≥720px)
- **Hero + görsel:** `HeroTags`, feed/story `CachedNetworkImage`
- **Rapor:** `docs/PRODUCTION_READINESS_REPORT.md`



_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
