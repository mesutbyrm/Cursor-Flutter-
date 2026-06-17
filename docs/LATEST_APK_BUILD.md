# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.236+239` |
| Tarih (UTC) | 2026-06-17 05:24 |
| Commit | [`d522b256070d21eca3e4bb23f4008c6e9a2891b0`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/d522b256070d21eca3e4bb23f4008c6e9a2891b0) |
| İş akışı | [Run 27667333824](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27667333824) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.236+239 (2026-06-12)

### Müzik + oda stabilitesi — istemci düzeltmeleri

- **Debug logları (release):** `ROOM JOIN/LEAVE`, `SSE CONNECT/DISCONNECT/RECONNECT`, `PRESENCE UPDATE`, `SEAT UPDATE`, `DJ UPDATE`, `MUSIC START/STOP/ERROR`, `DJ EVENT RECEIVED`
- **Müzik:** Aynı `videoId` ile player yeniden oluşturulmaz; `youtube.com` watch URL → explode çözümleme; `setAudioSource` / `errorStream` hata logları; bildirim yalnızca gerçek oynatma sonrası
- **Oda:** Boş presence SSE yanıtında koltuk/avatar korunur; `leaveRoomSession()` ile kontrollü çıkış; çift SSE/presence join engeli


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
