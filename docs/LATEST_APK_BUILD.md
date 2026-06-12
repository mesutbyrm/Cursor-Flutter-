# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.194+196` |
| Tarih (UTC) | 2026-06-12 11:01 |
| Commit | [`36c09d79294b088956b5b71091d9f5e9be306a49`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/36c09d79294b088956b5b71091d9f5e9be306a49) |
| İş akışı | [Run 27411125733](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27411125733) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.194+196 (2026-06-12)

### Açılış gri ekran düzeltmesi (7. tur)

- **Android native:** `drawable-v21/launch_background` artık `#0A0618` (API 21+ cihazlarda `?colorBackground` gri flash giderildi)
- **NormalTheme:** pencere arka planı `@color/canlifal_window_background` (`#05050D`) — Flutter yüklenirken gri sistem rengi yok
- **Auth rotaları:** `NoTransitionPage` geri eklendi (`/login`, `/register`, şifre sıfırlama, OTP) — geçiş scrim’i önlenir
- **NavigatorModalSanitizer:** ilk 4 sn + oturum açılışı sonrası `/feed` geçişinde barrier temizliği


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
