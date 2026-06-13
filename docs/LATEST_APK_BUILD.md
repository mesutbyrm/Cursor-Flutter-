# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.214+217` |
| Tarih (UTC) | 2026-06-13 19:10 |
| Commit | [`633b0b6114988f5361d20c7bccf3ac3519d5437b`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/633b0b6114988f5361d20c7bccf3ac3519d5437b) |
| İş akışı | [Run 27476088453](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27476088453) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.214+217 (2026-06-13)

### Sesli oda — "uninitialized provider" hatası

- **Kök neden:** `VoiceRoomLiveController.build()` içinde `return` öncesi `_schedulePoll()` → `state.dj` okunuyordu → `Bad state: Tried to read the state of an uninitialized provider`
- **Dosya:** `chat_room_providers.dart` satır 273 (`_schedulePoll` build sırasında)
- **Çözüm:** İlk poll `Future.microtask` içine taşındı (build tamamlandıktan sonra)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
