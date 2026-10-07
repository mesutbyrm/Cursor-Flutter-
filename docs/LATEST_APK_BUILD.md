# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.734+787` |
| Tarih (UTC) | 2026-10-07 09:59 |
| Commit | [`a460695fd1426c6779a289e8e3691416d08c6fbf`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/a460695fd1426c6779a289e8e3691416d08c6fbf) |
| İş akışı | [Run 37602025847](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37602025847) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.734+787 (2026-10-07) — Tanı + dayanıklılık (FORTUNE-003, CORE-001, CORE-002, otomatik tespit, fal timer)

- **FORTUNE-003:** Falcı gelen-istek SSE'sine 40 sn kalp atışı bekçisi; yarı açık bağlantı kapatılıp yeniden bağlanır
- **Fal timer:** sunucu `elapsedSeconds` gönderdiğinde saniyelik sayaç bir sonraki senkrona kadar donuyordu; artık anlık alınan değerden ilerler (`PsychicRoomEntity.snapshotAt`)
- **CORE-001:** TRTC, canlı fal, hediye ve ağ katmanındaki 52 sessiz `catch (_) {}` artık `CfDiag.swallowed` ile Diagnostics'e (warn, maskeli) yazılır; davranış değişmez
- **Otomatik tespit (`CfAutoDetect`):** TIMER_DRIFT, AUDIO_ACTIVE_WITHOUT_SEAT, TRTC_JOINED_TWICE, DUPLICATE_GIFT kuralları; 30 sn tekrar sınırı
- **CORE-002:** Hiçbir akışın bağlanmadığı eski `core/sse_client.dart` + sağlayıcı + yaşam döngüsü bağlaması kaldırıldı (realtime `BaseSseService` / SSE hub üzerinden)
- Gerçek cihaz: **BLOCKED**


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
