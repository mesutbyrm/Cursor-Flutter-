# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 00:33:27 UTC |
| Run | local-1786235601 |
| API | https://canlifal.com |
| Geçti | 4 |
| Başarısız | 1 |
| Atlandı | 1 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| AUTH | Giriş + refresh | ✅ PASS | accessToken yenilendi |
| TRTC | Token | ✅ PASS | HTTP 200 |
| VOICE | Presence + SSE | ✅ PASS | room=cmokyb9o9007iod09gi6pb1tb join/leave OK |
| LIVE | Yayın oluşturma | ⏭️ SKIP | NOT_A_TELLER (falcı onayı gerekli) |
| PK | Voice PK endpoint | ❌ FAIL | HTTP 403 |
| PSYCHIC | Falcı listesi | ✅ PASS | HTTP 200 |

**Release APK oluşturulmadı** — yukarıdaki başarısız testleri düzeltin.
