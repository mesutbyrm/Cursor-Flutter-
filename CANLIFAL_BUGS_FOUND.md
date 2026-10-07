# CANLIFAL Bugs Found

**Güncelleme:** 2026-10-07 — Gerçek cihaz **interaktif** test bu VM’de yapılmadı. Aşağıdakiler **Telefon A diagnostic log** + kod incelemesi ile **FAIL** olarak kayıtlıdır.

| ID | Önem | Özet | Kanıt |
|----|------|------|--------|
| BUG-001 | P1 | Görsel 401 `GET /api/upload/get-url` | Telefon A log |
| BUG-002 | P1 | Sesli odadan çıkınca ses (TRTC leave erken kesinti — 731 fix retest) | Kullanıcı + kod |
| BUG-003 | P2 | DUPLICATE_SSE voice_sse | Diagnostic |
| BUG-004 | P2 | LEAK_SUSPECTED after EXIT, sse=3 | summary.json |
| BUG-005 | P2 | TweenSequence StateError | errors_a983.json |
| BUG-006 | P2 | TIMER_COUNT_HIGH live_fortune=5 | Diagnostic |
| BUG-007 | P2 | Pending sessions poll tekrarı | Telefon A log |

Mock/unit-only sonuçlar **eklenmez**.  
Tam format: `CANLIFAL_CRITICAL_ERRORS.md`
