# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.207+210` |
| Tarih (UTC) | 2026-06-13 12:46 |
| Commit | [`e35db6425207467bd2f6339c316db4b67e6936a2`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/e35db6425207467bd2f6339c316db4b67e6936a2) |
| İş akışı | [Run 27466977309](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27466977309) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.207+210 (2026-06-13)

### Giriş sonrası gri overlay — mimari düzeltme (kök neden)

- **Kök neden:** `MaterialApp.builder` Stack'inde `AuthFlowOverlay` + altta `/feed` go_router — girişte overlay kalkınca kök navigator'da yetim `ModalBarrier` kalıyordu
- **Çözüm:** Auth overlay kaldırıldı; oturumsuz kullanıcı `go_router` `/login` rotasında (`AuthGatewayHost`, iç Navigator yok)
- `RouterAuthRefresh` — giriş başarılı → redirect `/feed` (tek geçiş, barrier yok)
- `shellSession++` girişte kaldırıldı; `FeedBarrierWatchdog` / `NavigatorModalSanitizer` kaldırıldı
- Misafir modu: `/login` → `/feed` redirect


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
