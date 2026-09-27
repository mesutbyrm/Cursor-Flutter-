# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.616+667` |
| Tarih (UTC) | 2026-09-27 16:52 |
| Commit | [`2275afd2b0d64d4ad0914b37ec919c5b2e5f9302`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/2275afd2b0d64d4ad0914b37ec919c5b2e5f9302) |
| İş akışı | [Run 36332576279](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36332576279) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.616+667 (2026-09-27) — Sesli oda, PK, DM (APK paketi)

- **Sesli oda mikrofon rozeti:** `isMicOn` yokken herkes susturulmuş sayılıyordu → bilinmeyen durumda koltukta açık; TRTC aç/kapa `applySelfMicOpen`
- **Konuşma halkası:** TRTC volume/VAD → koltuk animasyonu (`voiceRoomTrtcSpeakingIdsProvider`)
- **Koltuk stabilitesi:** `seatSlots` haritası + snapshot’ta `seatIndex` koruma; heartbeat’te güncel koltuk; `seatIndex: -1` dinleyici; koltuk bırakınca son koltuk hafızası temizlenir
- **PK:** sağ rail **PK** düğmesi; video PK ucu 404 olunca `/api/live/pk` yedeği artık çağrılıyor
- **DM:** SSE doğru konuşma stream ucu; gelen kutusunda bekleyen mesaj istekleri (Kabul/Reddet)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
