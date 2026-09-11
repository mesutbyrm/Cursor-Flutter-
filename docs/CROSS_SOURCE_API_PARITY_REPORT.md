# Cross-source API / MCP / Flutter parity report

> **Generated:** 2026-09-11 21:13 UTC (`scripts/generate_cross_source_parity_report.py`)

## 1. Kaynak önceliği (CURRENT)

1. Üretim davranışı (`https://canlifal.com`)
2. `_zip_analysis/` Sep 10 envanter (~852 satır)
3. `backend-docs/openapi.json` + `endpoints_index.json`
4. `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` (mobil sözleşme)
5. `backend-docs/abacus-current/**` (Abacus devir paketi)

**MCP:** `mcp-server/` yalnızca geliştirici aracı; Flutter runtime REST+SSE kullanır.

## 2. Şema / indeks uyumu

| Kaynak | Ölçüm |
|--------|------:|
| `backend-docs/openapi.json` paths | **502** |
| `abacus-current/priority1/openapi.json` paths | **502** |
| OpenAPI ↔ Abacus path farkı | **0** |
| `endpoints_index.json` handler | **780** |
| OpenAPI method×path çifti | **780** |
| Index ↔ OpenAPI fark | **0** |

## 3. Flutter (`mobile/lib`) ↔ OpenAPI

| Ölçüm | Adet |
|-------|-----:|
| `api_endpoints.dart` sabitleri | 290 |
| Tüm `lib/` `/api/` literal | **310** |
| OpenAPI ile normalize eşleşme | **196** |
| Flutter-only (OpenAPI’de yok / farklı şablon) | **114** |
| OpenAPI path Flutter’da hiç geçmiyor (yaklaşık) | **306** |
| Kılavuzda geçen `/api/...` backtick | **206** |

### 3.1 Flutter-only gruplar (ilk 15)

- `api/admin/site-animations` — **6** uç
- `api/users/me` — **5** uç
- `api/admin/users` — **3** uç
- `api/pk/me` — **3** uç
- `api/user/cosmetics` — **3** uç
- `api/admin/payment-requests` — **2** uç
- `api/pk/admin` — **2** uç
- `api/short-videos/hashtags` — **2** uç
- `/api/admin/` — **1** uç
- `api/admin/chat` — **1** uç
- `api/admin/mobile-auth` — **1** uç
- `api/admin/payment-notifications` — **1** uç
- `api/admin/payments` — **1** uç
- `api/admin/voice-room-backgrounds` — **1** uç
- `api/admin/voice-room-finance-audit` — **1** uç

### 3.2 Flutter-only örnek (ilk 25)

```
/api/admin/
/api/admin/chat/rooms/create-for-user
/api/admin/mobile-auth
/api/admin/payment-notifications
/api/admin/payment-requests
/api/admin/payment-requests/dismiss-pending
/api/admin/payments/stream
/api/admin/site-animations
/api/admin/site-animations/assign
/api/admin/site-animations/bulk-assign
/api/admin/site-animations/defaults
/api/admin/site-animations/exit-defaults
/api/admin/site-animations/stats
/api/admin/users/credits
/api/admin/users/grant-membership
/api/admin/users/stats
/api/admin/voice-room-backgrounds
/api/admin/voice-room-finance-audit
/api/admin/voice-room-settings
/api/advisors
/api/advisors/online
/api/agency/invite-earnings
/api/auth/
/api/auth/google
/api/auth/login
```

## 4. MCP dokümantasyonu

| Dosya | Var |
|-------|-----|
| `MCP_REGISTRY` | ✅ |
| `MCP_INTEGRATION_MATRIX` | ✅ |
| `zip MCP_VE_ENTEGRASYONLAR` | ✅ |

MCP araçları `endpoints_index.json` / OpenAPI ile aynı envanteri okur; **üretim API hızını etkilemez**.

## 5. Abacus / MD dosya envanteri

| Dosya | Boyut (KB) |
|-------|----------:|
| `_zip_analysis/CURRENT_BACKEND_SOURCE_SET.md` | 3.1 |
| `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` | 84.0 |
| `backend-docs/abacus-current/00_BASLA_BURADAN.md` | 5.7 |
| `backend-docs/B1_12_API_MCP_FLUTTER_PARITY.md` | 19.8 |
| `backend-docs/MCP_REGISTRY.md` | 2.1 |
| `docs/MCP_INTEGRATION_MATRIX.md` | 1.8 |
| `_zip_analysis/MCP_VE_ENTEGRASYONLAR.md` | 1.8 |
| `backend-docs/abacus-current/priority2/CANLIFAL_HEDIYE_SISTEMI_DOKUMANTASYONU.md` | 46.8 |

**`backend-docs/abacus-current/` toplam `.md`:** 38

## 6. Bilinen çelişkiler / güncellik

| Konu | Durum | Not |
|------|-------|-----|
| `B1_12` gifts insights WRONG_HOST | Muhtemelen güncel değil | 2026-09-11: `/api/gifts/insights/feed` canlifal.com → 200 |
| `admin/payment-requests` vs `cfc-payment-requests` | Mobil yedek | OpenAPI kanonik: `cfc-payment-requests` |
| `financeMode` (staff/real jeton) | OpenAPI yok | Mobil 1.0.473+ gönderir; şema/üretim doğrulanmalı |
| 852 vs 780 vs 502 sayım | Beklenen | Farklı ölçüm birimleri (route/handler/path) |

## 7. Hız / runtime (backend ile aynı davranış)

- **Doğru host:** `ApiBackendRouter` — sesli oda `.../pk*` → games API; geri kalan → `canlifal.com`.
- **Gereksiz 404:** Hediye insights ana backend’de; eski B1_12 games yönlendirme riski güncel değil.
- **Önbellek / retry:** `api_cache_interceptor`, `api_retry_interceptor` (kılavuz §7).
- **SSE:** 5 kanonik endpoint, backoff (kılavuz §5–6).

## 8. Komutlar

```bash
bash scripts/abacus-openapi-parity.sh
python3 scripts/generate_cross_source_parity_report.py
cd mobile && flutter test test/core/network/api_endpoint_canonical_contract_test.dart
```
