# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.199+202` |
| Tarih (UTC) | 2026-06-12 20:24 |
| Commit | [`ae1d7f3e41fb581173f89cec06a949be6b10b975`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/ae1d7f3e41fb581173f89cec06a949be6b10b975) |
| İş akışı | [Run 27440512464](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27440512464) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.199+202 (2026-06-12)

### Gri katman — giriş + ana sayfa (regresyon düzeltmesi)

- **Kök neden:** Tek `MaterialApp` ile `initialLocation: /feed` → shell önce yükleniyor, `/login` redirect'i yetim `ModalBarrier` bırakıyordu; girişte `goRouter` AuthFlow dışında erken oluşturuluyordu
- **AuthFlowApp geri:** oturumsuz kullanıcıda go_router yok (giriş gri ekranı çözümü)
- **`shellSessionProvider`:** her oturum açılışında yeni go_router — temiz navigator
- **`initialLocation: /login`:** shell oturumsuz yüklenmez
- **MainShellApp:** mount sonrası `/feed` + 15 sn overlay scrub


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
