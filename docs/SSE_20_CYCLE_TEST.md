# SSE 20-Cycle Test

| Alan | Değer |
|------|--------|
| Başlangıç | 2026-08-10 13:45:43 UTC |
| Bitiş | 2026-08-10 13:46:46 UTC |
| API | https://canlifal.com |
| Oda | cmokyb9o9007iod09gi6pb1tb |
| Döngü | 20 |
| Başarılı döngü | 20 |
| Başarısız döngü | 0 |
| Header probe (TEST 20) | FAIL |
| SSE acceptance | **19/20** |
| Toplam byte | 10240 |
| Sonuç | **FAIL** |

## Kontrol listesi

- Her döngüde ayrı curl süreci (CONNECT → READ → EXIT = DISCONNECT)
- TEST 20: `X-Accel-Buffering: no` + Content-Type + Cache-Control (production response)
- Ardışık 3+ HTTP hata → FAIL
- Başarı oranı <%50 → FAIL
- Flutter SseClient unit 20-cycle: mobile/test/sse_20_cycle_test.dart

## Cihaz notu

Bu test ağ katmanıdır; Flutter listener/timer birikimi için birim testi gereklidir.
Gerçek cihazda 20 ekran giriş/çıkış döngüsü **BLOCKED** (adb yok).
