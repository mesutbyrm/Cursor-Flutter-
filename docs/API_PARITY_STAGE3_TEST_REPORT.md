# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 10:52:12 UTC |
| Run | local-1786272639 |
| API | https://canlifal.com |
| Geçti | 15 |
| Başarısız | 0 |
| Atlandı | 10 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| AUTH | Login→JWT→storage chain | ✅ PASS | accessToken len=281 |
| AUTH | Protected /api/me | ✅ PASS | auth=200 anon=401 |
| AUTH | 401 without token | ✅ PASS | HTTP 401 |
| AUTH | Refresh token | ✅ PASS | yeni accessToken |
| PROFILE | GET /api/me fields | ✅ PASS | id=cmsl2h8fe007fns08myytsk6b user=cursorusr1786235468 |
| VOICE | Join/leave presence | ✅ PASS | room=cmokyb9o9007iod09gi6pb1tb |
| TRTC | Backend token fields | ✅ PASS | sdkAppId=20040423 userId=cmsl2h8fe007fns08myytsk6b |
| TRTC | enterRoom/publish (device) | ⏭️ SKIP | fiziksel cihaz gerekli (adb yok) |
| SSE | Chat stream connect | ✅ PASS | event alındı |
| SSE | 20-cycle leak test | ✅ PASS | network 20-cycle OK |
| CHAT | Send + list messages | ✅ PASS | mesaj listede |
| GIFT | Catalog + insufficient | ✅ PASS | api-gift-phase OK |
| GIFT | 500 jeton E2E | ⏭️ SKIP | test hesabı 0 jeton; 2 cihaz gerekli |
| GIFT | Receiver animation | ⏭️ SKIP | fiziksel cihaz gerekli |
| MUSIC | Search + queue + request | ✅ PASS | api-music-phase OK |
| MUSIC | Playback audio | ⏭️ SKIP | fiziksel cihaz + jeton gerekli |
| LIVE | Create stream | ⏭️ SKIP | NOT_A_TELLER — teller onayı gerekli |
| LIVE | TRTC join + heartbeat (device) | ⏭️ SKIP | fiziksel cihaz gerekli |
| PK | Voice PK endpoint | ⏭️ SKIP | oda sahibi gerekli |
| PK | 2-user accept flow | ⏭️ SKIP | ikinci kullanıcı + cihaz gerekli |
| PK | Live PK | ⏭️ SKIP | teller/yayın hesabı gerekli |
| LIVE_FALCI | Teller list | ✅ PASS | HTTP 200 |
| LIVE_FALCI | Request→accept→TRTC | ⏭️ SKIP | ACCEPTANCE_TELLER_* yok + cihaz gerekli |
| REGRESSION | flutter analyze | ✅ PASS | 0 error |
| REGRESSION | canonical + SSE unit | ✅ PASS | tests OK |

**API testleri atlandı veya kısmen geçti** (10 atlandı) — istemci testleri bekleniyor.
