# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.203+206` |
| Tarih (UTC) | 2026-06-13 07:50 |
| Commit | [`86048746f8d2fe691d604a9b15e829bcd1e53229`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/86048746f8d2fe691d604a9b15e829bcd1e53229) |
| İş akışı | [Run 27460641521](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27460641521) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.203+206 (2026-06-12)

### Giriş sonrası gri overlay — kök neden #2 (overlay scrub + IndexedStack)

- **Kök neden:** `LoginPage` / `HomePage` / `MainShellPage` giriş sırasında kök navigator overlay'inde `StuckOverlayGuard` çalıştırıyordu; private API ile barrier temizliği yetim `ModalBarrier` bırakıyordu
- **Çözüm:** Tüm periyodik overlay scrub kaldırıldı; girişte `authController` global loading state'i kapatıldı (`authUserActionBusyProvider` yeterli)
- **Shell:** `StatefulShellRoute` denendi; go_router 15 API uyumsuz — scrub düzeltmesi yeterli
- **Giriş sonrası:** Güvenli `popDialogRoutes` (yalnızca dialog route pop, private overlay API yok)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
