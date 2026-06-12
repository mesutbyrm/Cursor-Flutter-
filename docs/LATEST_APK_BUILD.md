# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.200+203` |
| Tarih (UTC) | 2026-06-12 20:44 |
| Commit | [`3d4d965de55d1fdffd86cd292ab204ace40e6c94`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/3d4d965de55d1fdffd86cd292ab204ace40e6c94) |
| İş akışı | [Run 27441466506](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27441466506) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.200+203 (2026-06-12)

### Giriş sonrası gri overlay — kalıcı düzeltme (tek MaterialApp)

- **Kök neden:** `AuthFlowApp` ↔ `MainShellApp` ağaç değişimi ikinci `MaterialApp` mount ediyor; go_router geçişinden yetim `ModalBarrier` ana sayfada kalıyordu
- **Tek kabuk:** `_MainShellApp` her zaman mount; oturumsuzda `AuthFlowApp` üst katman overlay (go_router yok, barrier yok)
- **`auth_redirect`:** oturumsuz kullanıcı `/login`'e yönlendirilmez — shell `/feed`'de kalır, giriş overlay ile
- **`initialLocation: /feed`** sabit; `AuthRefresh` ile oturum açılınca `/login` → `/feed` redirect
- **`StuckOverlayGuard`:** `canPop` kilidi kaldırıldı; yetim barrier temizliği güçlendirildi
- **Giriş sonrası scrub:** overlay kalkınca 30 sn agresif modal temizliği


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
