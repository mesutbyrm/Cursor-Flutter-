# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.315+318` |
| Tarih (UTC) | 2026-06-20 20:12 |
| Commit | [`3c01e134c795d246e19bead6488e4445e778fc94`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/3c01e134c795d246e19bead6488e4445e778fc94) |
| İş akışı | [Run 27882207520](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27882207520) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.315+318 (2026-06-20)

### Canlı yayın — Yayını Başlat timeout düzeltmesi

- **live_broadcast_prep_page:** `createVideoStream` ve `fetchToken` çağrılarına 15 sn timeout; sunucu yanıt vermezse spinner kalkar ve kullanıcıya hata mesajı gösterilir
- **Agora handoff:** `shutdownForHandoff` 8 sn timeout ile korundu (takılsa bile akış devam eder)
- **Hata sonrası:** `_previewReady` sıfırlanır; buton tekrar tıklanabilir


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
