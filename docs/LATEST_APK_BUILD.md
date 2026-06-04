# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.127+129` |
| Tarih (UTC) | 2026-06-04 20:38 |
| Commit | [`93bf0009c47f8f327b4814a654fb93480e4dbdac`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/93bf0009c47f8f327b4814a654fb93480e4dbdac) |
| İş akışı | [Run 26976924303](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/26976924303) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.127+129 (2026-05-19)

### Google ile giriş

- `GOOGLE_SERVER_CLIENT_ID`: dart-define veya `google-services.json` Web client (`client_type: 3`)
- `GoogleAuthConfig` + net hata mesajları (SHA-1, yapılandırma eksik)
- `POST /api/auth/mobile-google` — düz JSON ve `{ success, data }` sarmalayıcı
- CI: `print-firebase-dart-defines.sh` APK’ya otomatik Web client ID ekler
- Kurulum: `docs/GOOGLE_SIGNIN_SETUP_TR.md`


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
