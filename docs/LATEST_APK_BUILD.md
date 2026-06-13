# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.210+213` |
| Tarih (UTC) | 2026-06-13 14:21 |
| Commit | [`807b2fe08c3fdc40d04f0943834ea56c398df77f`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/807b2fe08c3fdc40d04f0943834ea56c398df77f) |
| İş akışı | [Run 27469092623](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27469092623) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.210+213 (2026-06-13)

### Giriş sonrası gri overlay — yetim ModalBarrier (kök neden)

- **Kök neden:** go_router redirect `/login` → `/feed` kök navigator overlay'inde tema rengi `0x8C000000` yetim `ModalBarrier` bırakıyordu (içerik görünür, dokunma engelli, geri tuşu çalışır). `RootOverlayPurge` / `StuckOverlayGuard.purgeAfterLogin` private overlay API ile durumu kötüleştiriyordu
- **Çözüm:** Giriş ve kayıtlı oturum açılışında `shellSessionProvider++` — yeni `GoRouter` doğrudan `initialLocation: /feed` (redirect yok)
- `MaterialApp.router` `ValueKey('shell-$session')` — navigator overlay sıfırlanır
- Bildirim izni sonrası yalnızca güvenli `popDialogRoutes` (agresif scrub kaldırıldı)
- Post-login 5 sn zorla purge kaldırıldı


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
