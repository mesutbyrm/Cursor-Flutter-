# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.184+186` |
| Tarih (UTC) | 2026-06-10 23:11 |
| Commit | [`77cf8832d016d90b1b3e6ebea9a87bfc1dc8bf2a`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/77cf8832d016d90b1b3e6ebea9a87bfc1dc8bf2a) |
| İş akışı | [Run 27311345294](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27311345294) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.184+186 (2026-06-10)

### Müzik veri hattı teşhis logları (`[MusicPipeline]`)

- `!istek` / `song-request` / `music-queue` / `dj` yanıtlarında `musicUrl`, `videoId`, endpoint loglanır
- `musicUrl` null nedenleri (`musicUrl.null`) — sunucu stream çözemedi, merge çakışması vb.
- `fields.compare` — `musicUrl` vs `playbackSource` vs `nowPlaying.youtubeUrl`
- `setAudioSource.before` + `play.entered` — oynatıcıya girmeden önce URL
- `just_audio.error` — `PlayerException` ve diğer hatalar
- `exo.probe` — Android ExoPlayer ile URL doğrudan test (MethodChannel)

Logcat filtresi: `MusicPipeline` veya `VoiceRoom`


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
