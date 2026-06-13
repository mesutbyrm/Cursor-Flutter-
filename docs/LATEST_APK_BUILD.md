# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.212+215` |
| Tarih (UTC) | 2026-06-13 17:40 |
| Commit | [`b033929af950c78cb834f2b7d2cd14f8ed82dfdd`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/b033929af950c78cb834f2b7d2cd14f8ed82dfdd) |
| İş akışı | [Run 27473935877](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27473935877) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.212+215 (2026-06-13)

### Giriş sonrası gri overlay — çift MaterialApp + izin kaldırma

- **Kök neden (güncel):** Oturumsuzken `MaterialApp.router` arka planda `/feed` shell yüklüyordu; girişte navigator yeniden kurulurken yetim `ModalBarrier` kalıyordu. Giriş sonrası otomatik bildirim izni dialogu da barrier ile çakışıyordu
- **Çözüm:** Oturumsuz → ayrı `MaterialApp` (yalnızca `AuthGatewayHost`, **go_router yok**). Oturum açılınca tamamen yeni `MaterialApp.router` mount
- Girişte otomatik bildirim izni kaldırıldı (Bildirimler sayfası banner'ı ile açılır)
- `resetRootNavigatorKey` — oturum değişiminde temiz navigator
- `FeedTouchRecovery` — ana kabuk mount sonrası yetim barrier tek seferlik kurtarma
- `refreshListenable` / `RouterAuthRefresh` kaldırıldı


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
