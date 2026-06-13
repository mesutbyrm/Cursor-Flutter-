# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.213+216` |
| Tarih (UTC) | 2026-06-13 18:24 |
| Commit | [`5f54a6ff6d277e630c2e656a6f0c7c3ab1fe1352`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/5f54a6ff6d277e630c2e656a6f0c7c3ab1fe1352) |
| İş akışı | [Run 27474955017](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27474955017) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.213+216 (2026-06-13)

### Giriş sonrası gri ekran — kanıtlanmış kök neden

- **Kök neden:** `app.dart` `MaterialApp.router` builder içindeki `ListenableBuilder(router.routerDelegate)` — GoRouter ilk mount sırasında build fazında `notifyListeners` tetikliyor → `setState() called during build` → overlay/barrier bozulması → tema `ModalBarrier` (`0x8C000000`) dokunmayı kesiyor
- **İkincil:** `FeedTouchRecovery` / `StuckOverlayGuard._scrubOrphanModalBarriers` private overlay API ile `OverlayEntry` çift kaldırıyor → `OverlayEntry should be removed only once`
- **Çözüm:** `MainAppShell` — route dinleyicisi `addListener` ile post-frame; `ListenableBuilder` kaldırıldı
- `VoiceRoomGlobalMusicBar` — `GoRouter.of(context)` yerine `routePath` parametresi (builder Stack'inde GoRouter yok)
- `AppBottomNavHost` — `location` parametresi; `ListenableBuilder` kaldırıldı
- `FeedTouchRecovery` kaldırıldı (agresif scrub gri ekranı kötüleştiriyordu)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
