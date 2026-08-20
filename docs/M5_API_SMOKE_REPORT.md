# M5 API smoke raporu

**Tarih:** 2026-08-20 11:42 UTC  
**APK:** `1.0.291+327`  
**Oda:** `cmoohrbr` → `cmoohrbrx00a4nt08zlkdjyil`  
**Hesap:** `cursor.test.1786235468@mailinator.com` — jeton 9580→9560

| Geçti | Atlandı | Başarısız |
|-------|---------|-----------|
| 6 | 2 | 0 |

## Sonuçlar

| Test | Durum | Detay |
|------|--------|-------|
| Jeton | PASS | jeton=9580 |
| Oda çözümleme | PASS | cmoohrbr → cmoohrbrx00a4nt08zlkdjyil |
| Test1-2 song-request | PASS | HTTP 200 jeton -20 |
| Müzik kuyruğu | PASS | nowPlaying veya queue dolu |
| Test4 presence | PASS | join=200 leave=200 |
| SSE dj/kuyruk | PASS | stream event alındı |
| Test5-6 PK | SKIP | cihaz gerekli |
| Test7-10 sesli P0-P2 | SKIP | cihaz gerekli |

## Not

Bu rapor **Test 1–4 API karşılığıdır**. Test 5–10 (PK, koltuk-ses, mod popup, giriş şeridi) yalnızca `docs/M5_DEVICE_TEST_CHECKLIST.md` ile Android cihazda doğrulanır.

Yenile: `bash scripts/m5-api-smoke.sh`
