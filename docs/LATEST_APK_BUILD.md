# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.169+171` |
| Tarih (UTC) | 2026-06-10 00:25 |
| Commit | [`8c5270ad28d89114e93e9fe7fca81ff3003ce520`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/8c5270ad28d89114e93e9fe7fca81ff3003ce520) |
| İş akışı | [Run 27243782291](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27243782291) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.169+171 (2026-06-09)

### Socket parity — oda ve canlı yayın senkronu

- Sesli oda Socket.IO listener'larına `chatMessage`, `message`, `roomMessage`, `roomUsers`, `presenceUpdated`, `userJoined`, `userLeft` eklendi
- Socket reconnect sonrası oda/yayın/PK kanallarına yeniden join davranışı güçlendirildi
- Disconnect sırasında `leaveRoom`, `leaveStream`, `leavePk` emitleri eklendi
- `SOCKET_PARITY_REPORT.md` ile web ↔ Flutter socket/TRTC parite durumu raporlandı


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
