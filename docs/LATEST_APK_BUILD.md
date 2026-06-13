# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.211+214` |
| Tarih (UTC) | 2026-06-13 16:01 |
| Commit | [`937764b7cf4c9c29e6e37113c287b846bca5c046`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/937764b7cf4c9c29e6e37113c287b846bca5c046) |
| İş akışı | [Run 27471497450](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27471497450) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.211+214 (2026-06-13)

### Giriş sonrası gri overlay — kök mimari düzeltme

- **Kök neden:** `/login` go_router rotasından `/feed` shell rotasına geçiş (redirect veya shellSession) kök overlay'de tema `ModalBarrier` (`0x8C000000`) bırakıyordu — içerik görünür, dokunma ölü
- **Çözüm:** Giriş/kayıt UI artık **go_router rotası değil** — `MaterialApp.builder` içinde `AuthGatewayHost` widget'ı; oturum açılınca yalnızca builder yenilenir, **navigasyon yok**, barrier oluşmaz
- `/login`, `/register`, `/auth/forgot-password` → `/feed` redirect (derin link / OTP / şifre sıfırlama sayfaları korunur)
- `RouterAuthRefresh` oturum dinleyicisi kaldırıldı (redirect yarışı yok); `initialLocation` her zaman `/feed`
- Girişte `shellSession++` kaldırıldı (çıkış + misafir modunda kalır)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
