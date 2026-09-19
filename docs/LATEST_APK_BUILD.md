# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.571+614` |
| Tarih (UTC) | 2026-09-19 20:39 |
| Commit | [`ffaccc504c7e4700b40142a87f8838b0c715e1e1`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/ffaccc504c7e4700b40142a87f8838b0c715e1e1) |
| İş akışı | [Run 35467113669](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/35467113669) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.572+615 (2026-09-19) — Sesli oda: ağ değişiminde sessiz kopmaya karşı yeniden bağlanma

- **Sürekli odadan/koltuktan kopma:** sesli oda yalnızca TRTC `onConnectionLost`'a güveniyordu; WiFi↔mobil data geçişinde bu callback her zaman tetiklenmediği için ses sessizce donup toparlanamıyordu
- **Düzeltme:** oturum boyunca `connectivityService.onlineStream` dinleniyor; ağ geri gelince ve TRTC kanalı düşmüşse **tek uçuşlu** yeniden bağlanma (`ensureConnected`) + bir presence heartbeat tetikleniyor. Koltuk sunucu (presence) durumu olduğundan TRTC yeniden bağlanması koltuğu düşürmez
- Falcı tarafındaki kanıtlı `_watchNetwork` deseni sesli odaya taşındı; yeniden bağlanma askıya alınmışsa/zaten sürüyorsa çalışmaz (fırtına yok)
- Not — diğer maddeler istemcide zaten tam: **VIP şifre kapısı** (`voice_room_gated_entry`), **koltuk sayısı seçimi** (oda açma + yönetim, 8–15), **yetkiliye giriş anında oto-koltuk** (`_tryAutoPrivilegedSeat` + reaktif + host reconcile) kod tarafında mevcut ve bağlı; bu akışların cihazda çalışmaması durumunda kalan bağımlılık sunucu (oda listesinde kilit bayrağı, koltuk atama yetkisi, SSE yayını) tarafındadır


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
