# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.202+205` |
| Tarih (UTC) | 2026-06-13 07:09 |
| Commit | [`a97f2bef863dbc4e71bd1f672aee4504d676e628`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/a97f2bef863dbc4e71bd1f672aee4504d676e628) |
| İş akışı | [Run 27459740910](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27459740910) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.202+205 (2026-06-12)

### Giriş sonrası gri overlay — tek MaterialApp.router (kalıcı)

- **Kök neden:** Giriş sonrası `AuthFlowApp` ↔ `MainShellApp` ağaç değişimi ikinci `MaterialApp` mount ediyordu; go_router ilk kez burada oluşunca yetim `ModalBarrier` ana sayfada kalıyordu
- **Çözüm:** Uygulama başından itibaren tek `MaterialApp.router`; oturumsuzda `AuthFlowOverlay` üst katman (ayrı MaterialApp yok)
- **`AuthOverlayScope`:** Giriş ekranları go_router yerine overlay Navigator kullanır — `/register` push barrier oluşturmaz
- **`auth_redirect`:** Oturumsuz `/login` → `/feed` (overlay girişi gösterir); go_router auth redirect barrier kaldırıldı
- Agresif scrub/watchdog katmanları kaldırıldı (semptom tedavisi yerine mimari düzeltme)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
