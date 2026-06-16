# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.232+235` |
| Tarih (UTC) | 2026-06-16 20:38 |
| Commit | [`1e890eb3eca3530bfc93a911cf1201119dea3636`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/1e890eb3eca3530bfc93a911cf1201119dea3636) |
| İş akışı | [Run 27645890014](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27645890014) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.232+235 (2026-06-12)

### Müzik sistemi — sıfırdan yeniden yazım

- **!istek:** YouTube Data API v3 ile ilk 5 sonuç; modern seçim ekranı
- **Ses kaynağı:** videoId sunucuya gider; yt-dlp ile güncel stream URL; istemci yalnızca bu URL'yi oynatır
- **Oynatıcı:** Kapak, süre, ilerleme çubuğu, play/pause/stop, sessiz, ses seviyesi, kapat (X)
- **Bildirim:** just_audio + audio_service medya kontrolleri; kapatınca bildirim kalkar
- **Oda senkronu:** currentPosition / isPlaying / currentVideoId SSE ile; geç katılan doğru konumdan başlar
- **Kuyruk:** Tam kuyruk ekranı; DJ silme; sıradaki otomatik
- **Yaşam döngüsü:** Odadan çıkınca müzik ve bildirim durur


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
