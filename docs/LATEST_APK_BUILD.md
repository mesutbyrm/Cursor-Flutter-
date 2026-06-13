# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.204+207` |
| Tarih (UTC) | 2026-06-13 08:13 |
| Commit | [`8be8f3bf9e54b14ea24ecd1bf6f53006e4486cd8`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/8be8f3bf9e54b14ea24ecd1bf6f53006e4486cd8) |
| İş akışı | [Run 27461131601](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27461131601) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.204+207 (2026-06-12)

### Giriş sonrası gri overlay — bildirim izni + go_router yenileme

- **Kök neden:** Giriş anında `AuthRefresh` go_router'ı yeniliyordu (geçiş barrier); eşzamanlı `OneSignal.requestPermission` + `popDialogRoutes` sistem dialogu ile çakışıp yetim `ModalBarrier` bırakıyordu
- **`AuthRefresh` kaldırıldı** — oturum UI `AuthFlowOverlay` ile; çıkışta `shellSessionProvider` router sıfırlar
- **Bildirim izni gecikmeli** (~2.8 sn) — ana sayfa otursun, sonra sistem dialogu; bitince güvenli barrier temizliği
- Giriş anında agresif `popDialogRoutes` kaldırıldı


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
