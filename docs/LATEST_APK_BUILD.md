# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.190+192` |
| Tarih (UTC) | 2026-06-11 18:59 |
| Commit | [`1e9b0542a27d9dc02b18a0c58fc32bb0b52e267a`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/1e9b0542a27d9dc02b18a0c58fc32bb0b52e267a) |
| İş akışı | [Run 27370005181](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27370005181) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.190+192 (2026-06-11)

### Giriş ekranı — Android gri overlay (4. tur, kök neden)

- **Kök neden:** `/splash` → `/login` GoRouter geçişinde Navigator üstünde kalan modal barrier + olası yarım dialog
- `initialLocation: '/login'` — soğuk açılışta splash yığını kaldırıldı
- Auth rotaları: `NoTransitionPage` (sıfır süre, scrim yok)
- `LoginPage`: mount sonrası `StuckOverlayGuard` ile takılı `PopupRoute` temizliği
- `StartupRouteObserver` + `[AppStartup]` logları (route push/pop/barrier)
- `FortuneIncomingInviteHost`: oturum yokken dialog açmaz


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
