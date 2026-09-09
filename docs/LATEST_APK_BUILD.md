# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.456+494` |
| Tarih (UTC) | 2026-09-09 15:40 |
| Commit | [`174bc470d4763a018be89115f833ee10a9262747`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/174bc470d4763a018be89115f833ee10a9262747) |
| İş akışı | [Run 34369899553](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34369899553) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.456+494 (2026-09-09) — Live/sesli oda realtime kök düzeltmeler

### PK
- Canlı PK `accept/reject/cancel/end` switch fallthrough düzeltildi (UI donma/kilitlenme)
- PK faz makinesi: `syncFromServer` — SSE authoritative phase
- Global PK ingest: odada değilken yabancı battle yazılmaz; duplicate snapshot atlanır
- Oda çıkışında `pkBattleProvider` + invite dedupe temizliği

### SSE / giriş / sıralama
- `onPk` SSE dedupe; `user_joined` tek `_announcePresenceJoin` yolu
- Oturum bazlı join userId dedupe; leave'de SSE dedupe sıfırlama
- Sıralama kutlaması: bootstrap'ta eski 1./2./3. spam engellendi

### Müzik
- `music-queue` endpoint önceliği; SSE/merge canonical boş kuyruk
- Kuyruk sheet duplicate `ValueKey` crash düzeltildi

### Canlı liste
- `patchStreamEnded` — biten yayın listeden anında çıkar


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
