# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 01:12:24 UTC |
| Run | local-1786237934 |
| API | https://canlifal.com |
| Geçti | 3 |
| Başarısız | 0 |
| Atlandı | 3 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| 8 | Kullanıcı adı ile giriş | ✅ PASS | token alındı (@cursorusr1786235468) |
| 7 | Profil ekranı < 2 sn | ✅ PASS | /api/me 122ms |
| 6 | SSE bağlantıları | ✅ PASS | chat stream veri alındı |
| 4 | Canlı yayın fal isteği | ⏭️ SKIP | yayın oluşturma 403; canlı liste API erişilebilir |
| 3 | Canlı falcı görüntülü görüşme | ⏭️ SKIP | ACCEPTANCE_TELLER_* yok |
| 5 | Jeton bildirimi admin paneli | ⏭️ SKIP | ACCEPTANCE_ADMIN_* yok |

**API testleri atlandı veya kısmen geçti** (3 atlandı) — istemci testleri bekleniyor.
