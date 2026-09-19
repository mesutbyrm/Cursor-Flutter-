# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.567+610` |
| Tarih (UTC) | 2026-09-19 16:08 |
| Commit | [`beb7cf902f6861d39cda172d0278c0348f2e8d39`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/beb7cf902f6861d39cda172d0278c0348f2e8d39) |
| İş akışı | [Run 35453057175](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/35453057175) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.567+610 (2026-09-19) — PK taraf titremesi düzeltildi

- **Taraf titremesi giderildi:** `resolveLivePkSplitLayout` içindeki `iAmChallenger`, battle verisi (hostStream/challengerId) geç geldiği için ilk karelerde ters karar veriyordu; kartlar/footer'lar ve skor sol↔sağ atlıyordu
- Taraf kararı bir kez **güvenle** belirlenince (`resolveIAmChallengerConfident`) battleId başına **kilitleniyor**; sonraki karelerde değişmiyor
- Bu, yanlış-tarafa atfedilen aksiyondan kaynaklanan **FORBIDDEN**'ı da azaltır
- Unit: `live_pk_side_resolver_test` (+3 vaka)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
