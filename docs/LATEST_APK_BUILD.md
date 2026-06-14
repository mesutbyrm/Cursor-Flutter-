# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.216+219` |
| Tarih (UTC) | 2026-06-14 01:46 |
| Commit | [`92925e107d1ef6a6a4655874c813cf145ed1c6ee`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/92925e107d1ef6a6a4655874c813cf145ed1c6ee) |
| İş akışı | [Run 27484888955](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27484888955) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.216+219 (2026-06-13)

### Sesli oda — müzik çalmama (googlevideo / 00:00)

- **Kök neden:** İlk oynatma başarısız olunca `_currentSource` sıfırlanmıyordu; yeniden denemede `setAudioSource` atlanıyor, player `idle` + süre `00:00` kalıyordu
- **Kök neden 2:** Android medya bildirimi akış yüklenmeden açılıyordu (başlık görünür, ses yok)
- **Çözüm:** `invalidateLoadedSource()` — başarısızlıkta kaynak ve bildirim temizlenir
- Android googlevideo sırası: yerel indirme → `/api/chat/youtube-audio` proxy → doğrudan CDN
- `mediaItem` yalnızca `setAudioSource` başarılı olduktan sonra yayınlanır
- `[MusicPipeline]` logları: `backend.audioUrl`, `setAudioSource.result`, `duration`, `playerStateStream`, `playbackEvent`, `audioService`, `play.result`


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
