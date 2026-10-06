# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.727+780` |
| Tarih (UTC) | 2026-10-06 16:46 |
| Commit | [`bebc24be4a1e8b29811d739a566a8e5b96a8537f`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/bebc24be4a1e8b29811d739a566a8e5b96a8537f) |
| İş akışı | [Run 37495416350](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37495416350) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.727+780 (2026-10-06) — Canlı falcı donma önlemleri + Canlifal Diagnostics

- **Canlı falcı isteği:** tüm çağıranlarda tek rezervasyon kapısı (çift dokunuş/başka falcı ikinci istek atmaz); ekran kapanınca `ref` StateError'u giderildi; zaman aşımı mesajı net
- **Seans bağlantısı:** yoklamalar (sinyal/oda/sohbet/ping) aynı anda tek istekle sınırlı; oda+durum sorgusu paralel; gereksiz senkron atlanır; TRTC token 20 sn zaman aşımı
- **SSE:** bilerek iptal edilen bağlantı artık ek yeniden bağlanma başlatmıyor
- **Bekleme/oturum güvenliği:** bekleme ekranı kapandıktan sonra gelen yanıt `StateError` vermiyor; eski seansın SSE `disconnect`'i yeni seansın bağlantısını kapatmıyor; SSE ve sohbet yoklaması TRTC join'i beklemiyor; yoklama hataları yakalanmamış async hataya dönüşmüyor
- **Yeni:** CANLIFAL DIAGNOSTICS (Hakkında → sürüm satırına uzun bas): kendi kendine tanı, kare/donma izleyici, iz kimliği (CF-TRACE), kategorili hata kaydı
- **Rapor:** `docs/CANLIFAL_PERFORMANCE_DIAGNOSTIC_REPORT.md`


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
