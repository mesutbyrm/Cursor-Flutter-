# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.230+233` |
| Tarih (UTC) | 2026-06-16 17:09 |
| Commit | [`ee8c0b1a7c4d306eaddfadb93ed8a98e62b09a8a`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/ee8c0b1a7c4d306eaddfadb93ed8a98e62b09a8a) |
| İş akışı | [Run 27634235123](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27634235123) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.230+233 (2026-06-12)

### Hata düzeltmeleri — sesli oda bağlantısı ve DJ müziği

- **Oda giriş döngüsü:** `voiceRoomLiveProvider` artık yalnızca oda kimliği (`liveKey`) ile tutulur; online sayısı / avatar güncellemelerinde presence+SSE kopmaz
- **SSE:** Aynı odaya yeniden bağlanırken mevcut akış korunur
- **Müzik:** Süresi dolmuş `googlevideo.com` URL'leri videoId ile yeniden çözülür; DJ SSE güncellemelerinde gereksiz oynatıcı yeniden başlatma azaltıldı
- **Poll hataları:** Arka plan yenileme hataları artık SnackBar ile «bağlantı koptu» hissi vermez


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
