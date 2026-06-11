# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.192+194` |
| Tarih (UTC) | 2026-06-11 23:34 |
| Commit | [`bd9f2c528dff6e4b424e781fe4f87061b2bb4576`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/bd9f2c528dff6e4b424e781fe4f87061b2bb4576) |
| İş akışı | [Run 27383845645](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27383845645) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.192+194 (2026-06-11)

### Giriş ekranı — Android gri overlay (6. tur)

- **RouterRefresh:** yalnızca oturum kontrolü bitince veya kullanıcı kimliği değişince `notifyListeners` — gereksiz go_router yenilemesi ve takılı modal barrier riski azaltıldı
- **NavigatorModalSanitizer:** `MaterialApp.builder` içinde; auth rotalarında 3 sn boyunca kök navigator’daki popup/barrier temizliği
- **StartupOverlayGuard** kaldırıldı (MaterialApp dışında navigator null kalıyordu)
- Auth rotalarında `FortuneIncomingInviteHost` / `AppBottomNavHost` devre dışı
- `AuthPremiumShell` tüm platformlarda opak `AuthPlainShell` (blur/cam yok)
- `LoginPage`: tam ekran bootstrapping kilidi kaldırıldı — form her zaman görünür, üstte ince progress
- Şifre sıfırlama / OTP: `AuthPremiumShell` + opak alanlar (`AuthShell` / LiquidGlass kaldırıldı)
- Android `pageTransitionsTheme`: `FadeUpwardsPageTransitionsBuilder` (Cupertino scrim yerine)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
