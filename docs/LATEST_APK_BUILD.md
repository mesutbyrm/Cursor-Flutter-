# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.209+212` |
| Tarih (UTC) | 2026-06-13 13:35 |
| Commit | [`2a243cbe278de83cb8f3efe65b151b3d832f1418`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/2a243cbe278de83cb8f3efe65b151b3d832f1418) |
| İş akışı | [Run 27468031092](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27468031092) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.209+212 (2026-06-13)

### Giriş sonrası gri overlay — login navigasyon sadeleştirme

- Tam ekran loading dialog yok; `authUserActionBusyProvider` + buton içi `CircularProgressIndicator` (try/finally garantili)
- Giriş başarısı: yalnızca go_router redirect `/login` → `/feed` — sayfa içi `context.go` / çift navigasyon kaldırıldı
- `guestMode` sıfırlama merkezi: `AuthController._clearGuestModeOnSuccess` (login/register listener tekrarı yok)
- `RouterAuthRefresh` post-frame tek bildirim; redirect aynı hedefe tekrarlanmaz


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
