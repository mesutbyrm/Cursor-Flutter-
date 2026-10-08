# CANLIFAL Bugs Found

**Güncelleme:** 2026-10-08 — Gerçek cihaz **interaktif** test bu oturumda yapılmadı. Önceki log bulguları yeniden cihazda doğrulanmadı; BUG-007 için kod düzeltmesi eklendi, saha retesti bekliyor.

| ID | Önem | Özet | Kanıt |
|----|------|------|--------|
| BUG-001 | P1 | Görsel 401 `GET /api/upload/get-url` — CDN unwrap mevcut; cihaz retesti bekliyor | Telefon A log + kod düzeltmesi |
| BUG-002 | P1 | Sesli odadan çıkınca ses — TRTC leave 4 sn timeout düzeltmesi mevcut; cihaz retesti bekliyor | Kullanıcı + kod |
| BUG-003 | P2 | DUPLICATE_SSE voice_sse — keşif bağlantısı oda başına tekilleştirildi; cihaz retesti bekliyor | Diagnostic + kod düzeltmesi |
| BUG-004 | P2 | LEAK_SUSPECTED after EXIT, sse=3 — artık izlenmeyen el sıkışma lease'i bırakılıyor; cihaz retesti bekliyor | summary.json + kod düzeltmesi |
| BUG-005 | P2 | TweenSequence StateError — pulse replay düzeltmesi mevcut; cihaz retesti bekliyor | errors_a983.json + kod |
| BUG-006 | P2 | TIMER_COUNT_HIGH live_fortune=5 | Diagnostic |
| BUG-007 | P2 | Pending sessions poll tekrarı — tek uçuş kilidi eklendi; cihaz retesti bekliyor | Telefon A log + kod düzeltmesi |

Mock/unit-only sonuçlar **eklenmez**.  
Tam format: `CANLIFAL_CRITICAL_ERRORS.md`
