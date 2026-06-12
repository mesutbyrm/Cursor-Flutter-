# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.201+204` |
| Tarih (UTC) | 2026-06-12 21:10 |
| Commit | [`79878ac762c52119dbb946c3aaac05fffefba64b`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/79878ac762c52119dbb946c3aaac05fffefba64b) |
| İş akışı | [Run 27442763135](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27442763135) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.201+204 (2026-06-12)

### Giriş sonrası gri overlay — kök neden (go_router erken mount)

- **Kök neden:** `MainShellApp` oturum kontrolü bitmeden `/feed` ile mount oluyordu; go_router `ModalBarrier` bırakıyor, oturum açılınca overlay kalksa da barrier kalıyordu
- **Çözüm:** Oturum kontrolü / giriş bitene kadar yalnızca `AuthFlowApp` — go_router hiç oluşturulmaz
- **Oturum açılışı:** `shellSessionProvider++` ile temiz go_router; `FeedBarrierWatchdog` + agresif `StuckOverlayGuard`
- **Ana sayfa:** 45 sn boyunca barrier izleme ve otomatik temizlik


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
