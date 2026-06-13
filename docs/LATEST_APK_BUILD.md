# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.205+208` |
| Tarih (UTC) | 2026-06-13 08:59 |
| Commit | [`f6dcb799213183bcc3989621ec86790403672d31`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/f6dcb799213183bcc3989621ec86790403672d31) |
| İş akışı | [Run 27462083545](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27462083545) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.205+208 (2026-06-12)

### Giriş sonrası gri overlay — iç Navigator kaldırıldı (kök neden)

- **Kök neden:** `AuthFlowOverlay` içindeki iç `Navigator` + `PageRouteBuilder` geçişleri, overlay ağaçtan kalkınca kök overlay'de yetim `ModalBarrier` bırakıyordu (dokunma engelli, geri tuşu çalışır)
- **Çözüm:** Auth overlay sayfa geçişi state tabanlı (`AuthOverlayRoute`); iç `Navigator.push` / `ModalRoute` yok
- **Giriş sonrası:** `shellSessionProvider++` ile temiz go_router; `purgeAfterLogin` + `NavigatorModalSanitizer` + `FeedBarrierWatchdog`
- **Bildirim izni** sonrası `purgeAfterLogin` (yalnızca `popDialogRoutes` değil)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
