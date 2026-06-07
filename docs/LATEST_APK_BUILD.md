# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.149+151` |
| Tarih (UTC) | 2026-06-07 23:34 |
| Commit | [`c54439f480efb18343cb579e9d540aaf54614aed`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/c54439f480efb18343cb579e9d540aaf54614aed) |
| İş akışı | [Run 27107698768](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27107698768) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.149+151 (2026-06-07)

### Sesli oda — teşhis + gri ekran yerine hata UI

- `VoiceRoomErrorBoundary`: Flutter `ErrorWidget` gri ekranı yerine anlamlı hata paneli
- `VoiceRoomDiagnosticProvider`: JWT, presence, SSE, socket, TRTC durumu tek yerde
- `VoiceRoomApiLogInterceptor`: `/api/chat/rooms` ve `/api/trtc/usersig` yanıtları loglanır
- TRTC `enterRoom`, socket connect/disconnect release logları
- `main.dart`: `FlutterError` / `PlatformDispatcher` / zone hataları `[VoiceRoom]` tag ile
- Oda route: API hatalarında retry + açıklayıcı mesaj


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
