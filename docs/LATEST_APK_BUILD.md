# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.779+835` |
| Tarih (UTC) | 2026-10-12 21:57 |
| Commit | [`ad2507c0c9546d88fd4a1f4b734f8d0f3a8c743f`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/ad2507c0c9546d88fd4a1f4b734f8d0f3a8c743f) |
| İş akışı | [Run 38311303108](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/38311303108) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.779+835 (2026-10-12) — Sesli oda arka plan / ön plan koltuk

- **Arka plan:** Uzun süre arka planda presence/TRTC düşünce ön plana dönüşte otomatik yeniden katılım, koltuk geri talebi ve TRTC yeniden bağlanma
- **45 sn arka plan leave:** Oda ekranı açık kalsa bile oturum yeniden kurulur; RTC sayfası ses kanalını tekrar açar
- **Uygulama kapanışı:** `detached` lifecycle’da sesli oda yerel presence kayıtları (`SharedPreferences`) temizlenir — hayalet oturum azaltılır
- **SSE resync:** Listede görünmeyen kullanıcı için presence yeniden join + yetkili otomatik koltuk denemesi


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
