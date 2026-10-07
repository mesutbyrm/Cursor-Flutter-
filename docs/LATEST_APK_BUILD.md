# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.739+792` |
| Tarih (UTC) | 2026-10-07 21:56 |
| Commit | [`b7edb36e5dc9fd333f8830f373961e94a45af913`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/b7edb36e5dc9fd333f8830f373961e94a45af913) |
| İş akışı | [Run 37690405721](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37690405721) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.739+792 (2026-10-07) — Sesli oda presence/koltuk/TRTC yaşam döngüsü (P0)

- **Oda değiştirme (hata):** A→B geçişinde eski odada yalnızca `leavePresence` deneniyordu; koltuk + live üyelik kalıyordu → kullanıcı A’da hayalet görünüyordu. Tam sunucu çıkışı: `clearSeat` + live `leaveRoom` + `DELETE presence?leave=1` (alternatif anahtarlar dahil)
- **Provider dispose (hata):** `_leavePresenceWithSeatClear` `force` olmadan erken dönüyordu → backend leave atlanabiliyordu; artık `force: true`
- **Koltuktan inme / ses (hata):** TRTC yeniden bağlanma `_trtc.micOn` ile mic’i tekrar açıyordu; `_desiredMicOn` otoriter. `releaseSeatVoice` sonrası reconnect askıda; audience `join` öncesi `setReconnectSuspended(true)`
- **Yarış:** seat fetch yanıtları oda değişiminden sonra uygulanmaz (`_liveSessionGeneration` koruması)
- **Açılış temizliği:** bekleyen presence kayıtları için de tam sunucu çıkışı
- Gerçek cihaz: kullanıcı Test 1–6


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
