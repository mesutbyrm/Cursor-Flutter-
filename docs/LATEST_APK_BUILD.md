# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.195+197` |
| Tarih (UTC) | 2026-06-12 13:22 |
| Commit | [`569a5ff66c51bd3e9ff7d197666f3191233a391c`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/569a5ff66c51bd3e9ff7d197666f3191233a391c) |
| İş akışı | [Run 27417842501](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27417842501) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.195+197 (2026-06-12)

### Giriş ekranı — gri yarı saydam katman (kök neden)

- **Kök neden:** Oturum kontrolü bitince `RouterRefresh` gereksiz `notifyListeners` → go_router yenilemesi tek sayfa yığınında takılı `ModalBarrier` (gri katman) bırakıyordu
- **RouterRefresh:** Yalnızca redirect hedefi değişecekse yenile; aksi halde `StuckOverlayGuard` ile barrier temizle
- **StuckOverlayGuard:** `scrubStuckOverlayBarriers` — overlay'deki yetim `ModalBarrier` widget'larını kaldırır
- **AuthRedirect:** redirect mantığı tek dosyada (`auth_redirect.dart`)
- **LoadingTimeout:** oturum / giriş / kayıt / `me()` için zaman aşımı + `ApiException`
- **AuthController:** 14 sn boot watchdog — loading sonsuza kalmaz
- **LoginPage:** auth bitince 4 sn periyodik overlay temizliği


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
