# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.749+802` |
| Tarih (UTC) | 2026-10-09 12:49 |
| Commit | [`d0f8b8c13e7d46e484fff280c2c1cea89a27a490`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/d0f8b8c13e7d46e484fff280c2c1cea89a27a490) |
| İş akışı | [Run 37930239481](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37930239481) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.749+802 (2026-10-09) — Canlı falcı: reklam ekranında takılma + süre isteği kaldırıldı + 401 retry sızıntısı

- **Takılma (kök neden):** Ücretsiz/admin seansında (totalJeton 0) ödüllü reklam yüklenemeyince/izlenmeyince `ad-transition` ekranı `return` ediyor, danışan "Canlı fal deneyiminiz başlıyor…"da, falcı "Kullanıcı bekleniyor…"da kalıyordu → reklam sonucu ne olursa olsun (20 sn zaman aşımı) seansa geçilir
- **Süre isteği kaldırıldı:** Danışan odaya girince falcı `start_timer`'ı doğrudan çağırır; sunucu `timer_started` ile iki tarafta görüntü/ses/süre aynı anda başlar. "Süre iste" düğmesi ve danışan onay penceresi kaldırıldı (eski sürüm falcıdan gelen istek otomatik kabul)
- **401 sızıntısı:** JWT yenileme sonrası tekrar deneme de hata verirse istisna interceptor dışına sızıp `ui.zone` hatası oluyor ve istek hiç tamamlanmıyordu → yakalanıp hata olarak iletiliyor
- **Backend (canlifal):** `GET /api/pk/me/invites` mobil JWT'de `mobile.user.id` okuyordu (her zaman boş) → her çağrı 401; `mobile.id` ile düzeltildi


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
