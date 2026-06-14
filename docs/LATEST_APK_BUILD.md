# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.217+220` |
| Tarih (UTC) | 2026-06-14 02:21 |
| Commit | [`40dbc73f6ee1af8939f8de4db1b1d7e554accee3`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/40dbc73f6ee1af8939f8de4db1b1d7e554accee3) |
| İş akışı | [Run 27485590647](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27485590647) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.217+220 (2026-06-13)

### Sesli oda — müzik çalmama + X kapat + eski şarkı

- **YouTube önce:** Oynatma sırası web gibi — önce `nowPlaying.youtubeUrl` / videoId çözümle, sonra sunucu CDN
- **Eski şarkı:** Yeni istekte `state.dj.musicUrl` artık taşınmıyor; parça değişince eski googlevideo URL temizlenir
- **X kapat:** `closeMusicPlayer()` — yerel durdur + DJ/owner ise sunucu kuyruğu temizle
- **UI:** Süre gelmeden «Şu an çalıyor» gösterilmez; oynatma başarısızsa `playing: false`
- `youtube_explode` ikinci deneme `requireWatchPage: true`


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
