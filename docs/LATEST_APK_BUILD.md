# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.239+242` |
| Tarih (UTC) | 2026-06-17 07:49 |
| Commit | [`509d37c799e32cfe0983b5f5d810f208df56fc2d`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/509d37c799e32cfe0983b5f5d810f208df56fc2d) |
| İş akışı | [Run 27673427669](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27673427669) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.239+242 (2026-06-12)

### Video Müzik Modu — sesli sohbet odaları

- **!istek sanatçı şarkı:** Mesaj backend'e gider; YouTube Data API v3 ile ilk uygun video bulunur ve `videoId` oda state'ine yazılır
- **Tam ekran video:** Aktif video varken arka plan görseli yerine YouTube tam ekran oynatıcı (`youtube_player_iframe`)
- **Katmanlar:** Koltuklar, sohbet, konuşan göstergeleri ve hediyeler videonun üzerinde kalır
- **Yetkili kontroller:** Oda sahibi / admin / DJ — oynat, duraklat, kapat (WebSocket `roomVideo` + `dj` senkronu)
- **Yeni giren:** `music-queue` / SSE / socket ile mevcut konumdan devam
- **Mimari:** `RoomVideoState`, `RoomVideoController`, `RoomVideoOverlay`, `YoutubeVideoBackground`, `RoomVideoSocketEvents`
- **Kaldırıldı:** Mini video yedek oynatıcı ve alt müzik şeridi (`VoiceRoomWebMusicBar`)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
