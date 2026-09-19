# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.561+604` |
| Tarih (UTC) | 2026-09-19 02:07 |
| Commit | [`f4ec6c72380b35199363be046a2b89c5de80df1a`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/f4ec6c72380b35199363be046a2b89c5de80df1a) |
| İş akışı | [Run 35413514437](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/35413514437) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.561+604 (2026-09-19) — PK UI + audit düzeltmeleri (release APK)

- Canlı 1v1 PK ekranı referans tasarım: `PkBattleScreen` (split video, VS, skor barı, sohbet, kontrol çubuğu)
- PK: süren maçta provider **keepAlive**; geçici ağ hatasında ekran düşmez; stale guard; 90 sn istemci sayacı kaldırıldı
- PK: boş/hatalı `refresh` **90 sn stale latch**; kalp skoru API hatasında rate-limited snackbar; "PK zaten bitmiş" ham exception sızmasın
- Hediye: rastgele alıcı kaldırıldı; jeton + hediye kaydı tek transaction
- Keşif sayfalama; feed hikâye şeridinde uydurma kullanıcı yok
- Fal/UI: korumasız **BuildContext** ve `CdsError` sızıntı düzeltmeleri


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
