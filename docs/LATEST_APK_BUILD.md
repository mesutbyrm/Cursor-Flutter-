# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.134+136` |
| Tarih (UTC) | 2026-06-05 22:05 |
| Commit | [`19bb3fc75a9bdc8ef304acf4c34e01438fb27033`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/19bb3fc75a9bdc8ef304acf4c34e01438fb27033) |
| İş akışı | [Run 27041645557](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27041645557) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.134+136 (2026-05-19)

### Müzik isteği oynatma düzeltmesi

- `[SONG_REQUEST_FREE] videoId|başlık` sohbet satırı parse edilir; anında oynatma + sunucu senkronu
- `!istek` sonrası kademeli yeniden senkron (300 ms–3 sn)
- Kuyruk dolu ama `playing: false` ise mobil YouTube yedek URL ile çalmayı dener
- API: Piped çözümleme başarısızsa YouTube watch URL ile kuyruk başlatılır; `nowPlaying` kuyruk başında gösterilir


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
