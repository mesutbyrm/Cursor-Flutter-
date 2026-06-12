# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.197+199` |
| Tarih (UTC) | 2026-06-12 14:42 |
| Commit | [`815736582717845b7d19c56a6191a621b95e57e7`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/815736582717845b7d19c56a6191a621b95e57e7) |
| İş akışı | [Run 27422343537](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27422343537) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.197+199 (2026-06-12)

### Ana sayfa gri katman — giriş sonrası

- **Kök neden:** Oturum açılınca `MainShellApp` + go_router shell rotaları varsayılan sayfa geçişiyle kök navigator'da takılı `ModalBarrier` bırakıyordu
- **Shell rotaları:** `/feed`, `/social`, `/live`, `/fortune`, `/profile` ve `StatefulShellRoute` → `NoTransitionPage`
- **Android geçiş teması:** `NoBarrierPageTransitionsBuilder` — modal scrim oluşturmaz
- **Overlay temizliği:** `MainShellPage` + `HomePage` mount sonrası periyodik scrub; oturum açılışı sonrası 6 sn `postAuthFeed` temizliği
- **StuckOverlayGuard.dismissAll:** kök + shell iç navigator barrier temizliği


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
