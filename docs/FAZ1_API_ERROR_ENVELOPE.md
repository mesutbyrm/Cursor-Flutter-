# FAZ 1 — API hata zarfı (error envelope) referansı

**Tarih:** 2026-08-18  
**Kaynak:** `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` §8, `mobile/lib/core/network/api_exception.dart`  
**Durum:** Mevcut `ApiException.fromDio` her iki zarfı destekliyor; bu belge parity tablosudur.

---

## Desteklenen gövdeler

| Şekil | Örnek | Flutter |
|-------|--------|---------|
| Düz string | `{ "error": "Yetersiz jeton" }` | `ApiException.message` |
| Kod string | `{ "error": "insufficient_jeton" }` | `ApiErrorCode.insufficientJetons` |
| İç içe | `{ "success": false, "error": { "code": "RATE_LIMIT", "message": "..." } }` | `errorCode` + `message` |
| Mesaj alanı | `{ "message": "Oda bulunamadı" }` | `message` |
| Zod/liste | `{ "error": ["field invalid"] }` | `;` ile birleştirilmiş metin |

---

## HTTP kodu → kullanıcı mesajı

| Kod | Varsayılan (Flutter) | Not |
|-----|----------------------|-----|
| 400 | Sunucu `error` / `message` | Jeton/kredi → `insufficient_jeton` eşlemesi |
| 401 | Oturum süresi doldu | Refresh → `auth_token_refresh_coordinator` |
| 403 | Sunucu mesajı veya yetki | Admin/yonetici |
| 404 | Kaynak bulunamadı | |
| 429 | Rate limit (TR) | `ApiErrorCode.rateLimited` |
| 5xx | Sunucu mesajı veya ağ | Retry interceptor |

---

## Dio interceptor zinciri

Sıra (`dio_provider.dart`):

1. `ApiVersionInterceptor` — `/api` → `/api/v1`
2. `BackendRoutingInterceptor` — host seçimi
3. `CookieManager`
4. `PaymentRequestInterceptor`
5. `VoiceRoomApiLogInterceptor`
6. `ApiMonitorInterceptor` / `ApiTimingInterceptor`
7. `JsonContentTypeGuardInterceptor`
8. `ApiRetryInterceptor` — exponential backoff (kılavuz §7)
9. Auth `InterceptorsWrapper` — Bearer + 401 refresh
10. `GatewayFallbackInterceptor`
11. `ApiCacheInterceptor`

---

## Test kapsamı

- `mobile/test/core/network/api_exception_test.dart` — yapılandırılmış hata + jeton kodu
- `mobile/test/new_endpoints_test.dart` — 429 eşlemesi

---

## FAZ 1 kapanış kriterleri (bu başlık)

- [x] Error envelope tablosu (bu dosya)
- [x] `ApiException` birim testleri genişletildi
- [ ] Tüm repository'lerde `ApiException.userMessage` (devam — god-file refactor FAZ 1 sonrası)
- [ ] OpenAPI `components.responses` ile otomatik doğrulama (backend MCP)
