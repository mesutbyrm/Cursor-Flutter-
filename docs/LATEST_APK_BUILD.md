# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.483+521` |
| Tarih (UTC) | 2026-09-14 00:59 |
| Commit | [`b311bc499123b9d835f01239f4a1d264b8af2f50`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/b311bc499123b9d835f01239f4a1d264b8af2f50) |
| İş akışı | [Run 34792989224](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34792989224) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.483+521 (2026-09-14) — PK / canlı fal Aşama 2

- Canlı PK: faz makinesi sıfırlama, kabul/red zaman aşımı, çift davet diyaloğu engeli
- Sesli PK: `GET /api/pk/me/invites` poll; davet zaman aşımında otomatik red kaldırıldı
- Canlı fal: bahşiş SSE iç içe `data`/`amount`; falcı sinyal poll sıklaştırma; seans oluşturma paralel kontrol
- PK JSON: `opponentStreamId` / `hostStreamId` alan eşlemesi

## Unreleased — hediye kutusu + Tanış Kaynaş

- Sesli oda ve canlı yayın hediye paneli: **Hediye kutusu** sekmesi (create / join / cancel, BÖLÜM 22)
- Oda SSE: `gift_box_*` olaylarında kutu listesi yenileme
- Tanış Kaynaş: Keşfet + Etkileşimler + Hashtag & Takım sekmeleri; `favorite` aksiyonu
- CI: `scripts/apk-pending-features-gate.sh` (release gate 2b) — eksik özellik varsa APK üretilmez


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
