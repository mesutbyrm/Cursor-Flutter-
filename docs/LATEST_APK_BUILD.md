# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.13+15` |
| Tarih (UTC) | 2026-05-20 22:38 |
| Commit | [`00548229f4801e8a139e9c0ec438c0f2e31f8d9e`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/00548229f4801e8a139e9c0ec438c0f2e31f8d9e) |
| İş akışı | [Run 26193618677](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/26193618677) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.13+15 (2026-05-20)

### Derleme (CI)

- Dart SDK `^3.8.0` (Actions ile uyumlu; `^3.11.5` kırılıyordu)
- `pubspec.lock` güncellendi (`flutter_web_auth_2`)
- `glow_panel` null-aware liste sözdizimi düzeltildi

### Google giriş düzeltmeleri

- **403 disallowed_useragent:** Chrome Mobile user-agent + güvenli tarayıcı (Custom Tab) yedek
- Oturum çerezleri uygulamaya aktarılıyor (`sessionCookieMarker` + yeniden deneme)
- Site ana sayfası / onboarding WebView’da açılmıyor (yalnızca `/api/auth/*`)

### Ana sayfa ve canlı (1.0.12+14)

- Sesli odalar: 4 sütun grid, gerçek `/api/chat/rooms` verisi
- Canlı izleme native TRTC (WebView yok); yayın bitince liste yenilenir
- TRTC izleyici video düzeltmesi (`hostUserId`)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
