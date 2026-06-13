# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.215+218` |
| Tarih (UTC) | 2026-06-13 19:46 |
| Commit | [`e9b4aa786c8a6ef1e18d04aaa8310afcc495068f`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/e9b4aa786c8a6ef1e18d04aaa8310afcc495068f) |
| İş akışı | [Run 27476958958](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27476958958) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.215+218 (2026-06-13)

### Sesli oda — çift müzik player

- **Kök neden:** Oda içi `VoiceRoomBottomDock` + global `VoiceRoomGlobalMusicBar` aynı anda `VoiceRoomWebMusicBar` render ediyordu
- **Çözüm:** RTC sayfası açıkken `voiceRoomRtcForegroundProvider` ile global player gizlenir; debug URL satırı yalnızca debug modda


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
