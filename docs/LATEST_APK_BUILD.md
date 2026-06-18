# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.258+261` |
| Tarih (UTC) | 2026-06-18 06:14 |
| Commit | [`a2f61476c2b072bb24eda66d905065e67c988d0a`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/a2f61476c2b072bb24eda66d905065e67c988d0a) |
| İş akışı | [Run 27740078035](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27740078035) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.258+261 (2026-06-18)

### Bildirimler — push kayıt ve izin akışı düzeltmesi

- **Mevcut oturum:** Uygulama zaten girişli açıldığında OneSignal `login` ve push token kaydı artık anında tetiklenir
- **İzin sonrası kayıt:** Bildirim izni banner’dan açıldığında Firebase/FCM token kaydı tekrar denenir
- **İlk kurulum:** OneSignal/FCM token geç oluşursa kısa retry ile `/api/auth/mobile/device-token`, `/api/devices/fcm`, `/api/user/device-token` kayıtları kaçırılmaz


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
