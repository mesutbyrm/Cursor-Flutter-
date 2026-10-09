# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.746+799` |
| Tarih (UTC) | 2026-10-09 01:02 |
| Commit | [`5b77e5aa7526c59260e789ea4869c6d227baf34b`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/5b77e5aa7526c59260e789ea4869c6d227baf34b) |
| İş akışı | [Run 37866001194](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37866001194) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.746+799 (2026-10-09) — Sesli oda P0/P1: /voice kapısı, 403 durdurma, presence salınımı

- **/voice gövdesi:** backend yalnız `type` okuyor; eski gövde leave'i hep 400 yapıyordu → `{type, action}` tek istek
- **/voice join:** koltuk/konuşma izni yoksa hiç gönderilmez (`VOICE_JOIN_SKIPPED_NO_SEAT`); tek uçuş; 403 sonrası aynı oda için yeniden deneme yok (`VOICE_BLOCKED_403`); leave yalnız join edilmişse
- **Koltuk dinleyicisi:** her presence/SSE tikinde mic kapat → `/voice` leave spam'i; artık yalnız koltuk/izin değişiminde (kenar tetik)
- **speak-requests:** yalnız moderatör yetkisiyle; 403 sonrası oda için polling durur (`SPEAK_REQUESTS_BLOCKED_403`)
- **Presence:** `/state` `{success,data}` zarfı açılıyor; SSE sağlıklıyken boş snapshot SSE listesini ezmiyor (`PRESENCE_SNAPSHOT_EMPTY_IGNORED`); katılımcı `me` yetki sanılmıyor
- **Provider:** dispose/rebuild sırasında async geri çağrılar "uninitialized provider" StateError fırlatmıyor; dispose sonrası state yazımı yok sayılıyor
- **CI:** obfuscation sembolleri artifact olarak yükleniyor (cihaz stack trace çözümü)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
