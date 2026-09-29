# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.640+691` |
| Tarih (UTC) | 2026-09-29 18:59 |
| Commit | [`85585cab3e923046af6c81d696bb70da58565485`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/85585cab3e923046af6c81d696bb70da58565485) |
| İş akışı | [Run 36612781538](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36612781538) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.643+694 (2026-09-29) — PK davet önbelleği + sesli poll SSE

- **`/pk/me/invites`:** 8 sn paylaşımlı önbellek (canlı/sesli poll + pk session); davet kabul/red/create/end sonrası sıfırlanır
- **Sesli PK davet poll:** SSE ile yakın PK olayı varsa yedek REST turu atlanır (`deferVoicePkInviteRestPoll`)
- **Konuşma isteği (moderatör):** poll 3 sn → 5 sn; odadayken SSE açıkken yalnız periyodik yedek atlanır (SSE sinyali `force` ile çalışır)
- Backend değişikliği yok


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
