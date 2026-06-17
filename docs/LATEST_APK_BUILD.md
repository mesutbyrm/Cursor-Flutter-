# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.233+236` |
| Tarih (UTC) | 2026-06-17 04:06 |
| Commit | [`8fea3bd8ed60ae7682ba2536aace2eb6d009b129`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/8fea3bd8ed60ae7682ba2536aace2eb6d009b129) |
| İş akışı | [Run 27664672212](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27664672212) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.233+236 (2026-06-12)

### Müzik oynatma — ses gelmeme düzeltmesi

- Android'de googlevideo akışları artık önce canlifal.com `/api/chat/youtube-audio` proxy üzerinden oynatılıyor
- Medya bildirimi yalnızca ses gerçekten başladıktan sonra gösteriliyor
- `setAudioSource` / `play()` öncesi-sonrası ayrıntılı `[MusicPipeline]` logları
- 3 saniye içinde ses başlamazsa teşhis logu; oynatıcıyı kapatan periyodik timeout kaldırıldı
- Ses akışı alınamazsa / oynatma başarısızsa kullanıcıya hata mesajı
- Audio focus `gain` + 3 denemeli yeniden aktivasyon

### DJ yönetimi

- Oda sahibi, admin ve moderatörler DJ + butonunu kullanabilir
- DJ ekleme sonrası sunucu SSE ile tüm odaya yayınlar


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
