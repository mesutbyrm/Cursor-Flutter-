# SSE 20-Cycle Test

| Alan | Değer |
|------|--------|
| Başlangıç | 2026-08-09 10:50:41 UTC |
| Bitiş | 2026-08-09 10:51:41 UTC |
| API | https://canlifal.com |
| Oda | cmokyb9o9007iod09gi6pb1tb |
| Döngü | 20 |
| Başarılı | 20 |
| Başarısız | 0 |
| Toplam byte | 10240 |
| Sonuç | **PASS** |

## Kontrol listesi

- Her döngüde ayrı curl süreci (CONNECT → READ → EXIT = DISCONNECT)
- Ardışık 3+ HTTP hata → FAIL
- Başarı oranı <%50 → FAIL
- Flutter SseClient unit 20-cycle: mobile/test/sse_20_cycle_test.dart

## Cihaz notu

Bu test ağ katmanıdır; Flutter listener/timer birikimi için birim testi gereklidir.
Gerçek cihazda 20 ekran giriş/çıkış döngüsü **BLOCKED** (adb yok).
