# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 00:33:53 UTC |
| Run | local-1786235625 |
| API | https://canlifal.com |
| Geçti | 4 |
| Başarısız | 0 |
| Atlandı | 2 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| AUTH | Giriş + refresh | ✅ PASS | accessToken yenilendi |
| TRTC | Token | ✅ PASS | HTTP 200 |
| VOICE | Presence + SSE | ✅ PASS | room=cmokyb9o9007iod09gi6pb1tb join/leave OK |
| LIVE | Yayın oluşturma | ⏭️ SKIP | NOT_A_TELLER (falcı onayı gerekli) |
| PK | Voice PK endpoint | ⏭️ SKIP | oda sahibi hesabı gerekli (Sadece oda sahibi PK başlatabilir) |
| PSYCHIC | Falcı listesi | ✅ PASS | HTTP 200 |

**API testleri atlandı veya kısmen geçti** (2 atlandı) — istemci testleri bekleniyor.
