# FAZ 1 — Durum (Core + Auth + API)

**Tarih:** 2026-08-18  
**Önkoşul:** FAZ 0 INCOMPLETE (M5 cihaz + jeton) — FAZ 1 hazırlık paralel devam ediyor.

---

## Tamamlanan (hazırlık)

| Madde | Durum | Çıktı |
|-------|--------|-------|
| Error envelope referansı | ✅ | `docs/FAZ1_API_ERROR_ENVELOPE.md` |
| ApiException birim testleri | ✅ | `api_exception_test.dart` |
| Dio interceptor envanteri | ✅ | FAZ1_API_ERROR_ENVELOPE § zincir |
| JWT refresh tek yolu | ✅ mevcut | `auth_token_refresh_coordinator.dart` |
| Repository standardı | 🔄 | Kılavuz §9 — çoğu modül uyumlu |

---

## Bekleyen (FAZ 1 tam kapanış)

| Madde | Bloker |
|-------|--------|
| God-file parçalama (`chat_room_providers.dart`) | Büyük refactor — ayrı oturum |
| OpenAPI error response otomasyonu | Backend MCP şema |
| FAZ 1 resmi PASS | FAZ 0 PASS önerilir |

---

## Komutlar

```bash
cd mobile && flutter test test/core/network/api_exception_test.dart
dart analyze
```
