# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.635+686` |
| Tarih (UTC) | 2026-09-29 14:55 |
| Commit | [`5b1f82a5148e979021bb84218a419e9b90cb43f0`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/5b1f82a5148e979021bb84218a419e9b90cb43f0) |
| İş akışı | [Run 36583848837](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36583848837) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.635+686 (2026-09-29) — Cihaz testi: izin, PK bitişi, sesli PK daveti, misafir modu

- **İzinler:** mikrofon/kamera ilk açılışta bir kez istenir; odaya/yayına girişte yalnızca yayın gönderilecekse (sahip, koltuk, misafir) ve izin hâlâ yoksa sorulur. Dinleyici/izleyiciden izin istenmez, kalıcı reddedilmişse Ayarlar'a atılmaz
- **Canlı yayın PK bitişi:** durum okunmadan önce süresi doluyu kapatan uç (`GET /api/video-streams/pk`) çağrılır; sayaç bitince hemen yenilenir. Önceden PK sunucuda "aktif" kalıyor, ekran PK modundan çıkmıyordu
- **Sesli oda PK daveti:** `/api/pk/me/invites` her turda soruluyor (1.0.633'teki kısa devre "Odalarım" boşken daveti atlıyordu); hedef oda listede yoksa sunucudan çekilip davet yine gösteriliyor
- **Canlı yayın misafir:** kabul/red `requestId` ile gönderiliyor (önceden sunucu 400 dönüyordu); istek listesi `GET /api/live/guest?view=sync`'ten; izleyici istek attığında ekran artık misafir düzenine geçmiyor (yalnızca onaylı misafir varsa); kontrol merkezinde onaysız boş misafir karesi eklenmiyor
- Backend değişikliği yok


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
