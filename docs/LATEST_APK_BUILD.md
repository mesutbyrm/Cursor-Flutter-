# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.191+193` |
| Tarih (UTC) | 2026-06-11 21:55 |
| Commit | [`5d9b66c68f18401be3f07c061c6a8a9a198eef02`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/5d9b66c68f18401be3f07c061c6a8a9a198eef02) |
| İş akışı | [Run 27379364303](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27379364303) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.191+193 (2026-06-11)

### Giriş ekranı — Android gri overlay (5. tur)

- **StartupOverlayGuard:** açılışta 1.5 sn boyunca kök navigator’daki takılı `PopupRoute` barrier’larını tekrarlı temizler
- **AUTH_FINISH** sonrası ve route değişiminde overlay temizliği; `APP_START` / `AUTH_START` / `OVERLAY_SHOW|HIDE` logları
- `/splash` rotası kaldırıldı — yalnızca redirect (`/login` veya `/feed`); çift navigasyon riski giderildi
- `FortuneIncomingInviteHost`: auth yüklenirken ve giriş/kayıt rotalarında dialog açmaz
- `MaterialApp.builder`: router `child == null` iken koyu arka plan (boş gri kare önlenir)
- `LoginPage`: auth bitince overlay temizliği (tek seferlik guard kaldırıldı)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
