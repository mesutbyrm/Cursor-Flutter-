# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.742+795` |
| Tarih (UTC) | 2026-10-08 00:48 |
| Commit | [`2b875aa57ab705e1edd80164a1c48fb319394cca`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/2b875aa57ab705e1edd80164a1c48fb319394cca) |
| İş akışı | [Run 37707868745](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37707868745) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.742+795 (2026-10-07) — Oda çıkışı: presence + koltuk + heartbeat yarışı

- **Kök neden:** Çıkışta TRTC önce kapanıyordu; heartbeat timer iptal edilse bile uçuştaki tick veya `finally` içindeki resync, sunucuda presence/koltuk yeniden yazıyordu. `clearSeat`/`leavePresence` bazen farklı oda anahtarları (route slug vs canonical cuid) ile gidiyordu; `presence leave` kabul edilmeden kalıcı kayıt siliniyordu (dispose’da `ref.read` ile leave hiç gitmiyordu).
- **Sıra:** heartbeat/timer dur → `clearSeat` + live `leaveRoom` + `DELETE presence?leave=1` (retry + alternatif anahtar) → TRTC → SSE/polling → yerel state
- **`[ROOM_LEAVE]`** release logcat: roomId, userId, seatId, seat/presence/live yanıtları (HTTP status + body)
- Heartbeat: `_leaveInFlight` / `!_sessionActive` iken tick ve resync yok
- Gerçek cihaz: odaya gir → koltuk → tam çıkış; A→B→C hızlı geçiş; owner çıkışı


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
