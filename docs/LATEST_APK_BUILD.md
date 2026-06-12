# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.196+198` |
| Tarih (UTC) | 2026-06-12 14:19 |
| Commit | [`faae33067e41f2a1b368338c371022f6c19b88a7`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/faae33067e41f2a1b368338c371022f6c19b88a7) |
| İş akışı | [Run 27421003268](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27421003268) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.196+198 (2026-06-12)

### Giriş gri katman — kalıcı çözüm (AuthFlowApp)

- **Kök neden:** go_router `refreshListenable` + oturum kontrolü giriş ekranında takılı `ModalBarrier` (yarı saydam gri katman) bırakıyordu; overlay temizliği yeterli değildi
- **AuthFlowApp:** Oturumsuz kullanıcı için ayrı `MaterialApp` + sıfır geçişli `Navigator` — go_router devre dışı
- **Ana uygulama:** Yalnızca oturumlu veya misafir modunda `MaterialApp.router`; `initialLocation: /feed`
- **AuthNavigation:** Login/register/forgot/OTP sayfaları hem AuthFlow hem go_router ile çalışır
- go_router `refreshListenable` → yalnızca misafir modu (`GuestModeRefresh`); auth loading sırasında redirect atlanır


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
