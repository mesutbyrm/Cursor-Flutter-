# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.208+211` |
| Tarih (UTC) | 2026-06-13 13:11 |
| Commit | [`cc3a53b450fa66f81a785ea0bd46b74c700dd011`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/cc3a53b450fa66f81a785ea0bd46b74c700dd011) |
| İş akışı | [Run 27467520277](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27467520277) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.208+211 (2026-06-13)

### Giriş sonrası gri overlay — Android BackdropFilter + lazy shell

- **Kök neden:** `StatefulShellRoute.indexedStack` tüm sekmeleri (Canlı → Sesli Sohbet hub) girişte önceden yüklüyordu; `VoiceDiscoverHub2026` içindeki korumasız `BackdropFilter` Android'de tam ekran gri katman oluşturuyordu (ModalBarrier değil — purge işe yaramıyordu)
- **Çözüm:** `StatefulShellRoute` (yalnızca aktif sekme yüklenir); `SafeBackdropFilter` (`PlatformBlur` koruması); Canlı sekmesinde sesli oda hub'ı yalnızca "Sohbet" sekmesi seçilince yüklenir
- `premium_liquid_nav_bar` ve `discover_premium_header` blur koruması


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
