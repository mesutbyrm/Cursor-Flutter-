# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.316+319` |
| Tarih (UTC) | 2026-06-21 00:06 |
| Commit | [`6f7910dcad2e1c7547967ffcc2d8ec46361e7da0`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/6f7910dcad2e1c7547967ffcc2d8ec46361e7da0) |
| İş akışı | [Run 27887608060](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27887608060) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.316+319 (2026-06-20)

### Sesli oda — seat/mic/role snapshot-diff senkronizasyonu

- **VoiceRoomGiftSocket:** `roomUsers` / `presenceUpdated` / `userJoined` / `userLeft` için presence snapshot diff callback (`onPresenceSnapshot`)
- **VoiceSeatRestService:** `takeSeat` REST (`PATCH/POST /seats`); `leaveSeat` / `toggleMic` / `changeRole` placeholder (`UnimplementedError` + net mesaj)
- **VoiceRoomLiveController:** `applyPresenceSnapshot` — sunucu-yetkili koltuk/konuşma/rol güncellemesi
- **Socket bağlantısı:** Oda açılışında gift socket + SSE birlikte; koltuk emit yok (REST)
- **Mikrofon:** TRTC yerel toggle + REST placeholder (yakında snackbar, crash yok)
- **Tencent demo:** `VoiceRoomState.applyPresenceSnapshot`, `onUserAudioAvailable` artık koltuk atamaz


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
