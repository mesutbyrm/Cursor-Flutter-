# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.285+321` |
| Tarih (UTC) | 2026-08-19 20:33 |
| Commit | [`72b36b9eb7f4c8d2ef3b6615cf6c2e8338aa5a61`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/72b36b9eb7f4c8d2ef3b6615cf6c2e8338aa5a61) |
| İş akışı | [Run 32298394670](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/32298394670) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.285+321 (2026-08-19) — PK daveti + oda geçişi düzeltmeleri

- **PK bildirimi:** `targetPath: /` artık `GoException` vermez → `/feed` veya PK/oda rotası
- **PK daveti:** Sesli oda + canlı yayın isteği UI donmasını azaltır; kabul/red microtask'e alındı
- **PK alıcı:** Davet poll sıklaştı; SSE + bildirim sinyali `VoicePkInviteListener`'ı uyandırır
- **Oda değişimi:** Eski odada presence/koltuk backend leave beklenir (oturma hatası)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
