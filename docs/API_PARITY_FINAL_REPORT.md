# API Parity Final Report — Phase 2 (Gerçek Kod Entegrasyonu)

Date: 2026-08-09  
Branch: `cursor/backend-flutter-sync-0cde`  
Production base: `https://canlifal.com`  
Canonical namespace: `/api` (no `/api/v1`, `/api/v2`)

## Executive summary

Phase 2 doğrulaması: Flutter üretim kodu canonical backend contract ile hizalı. Legacy path literalleri (`/api/v1/*`, `/api/v2/*`, `/api/payment/*`, `/api/membership/packages`, `/api/rooms/{id}/music/*`) `mobile/lib/` içinde **runtime kullanımı yok**. Ödeme, üyelik ve müzik akışları canonical uçlara bağlı. MCP Flutter runtime'a eklenmedi. Agora yerine TRTC kullanılıyor.

**Parity durumu:** Kritik feature matrix — otomatik testler **PASS**, cihaz/runtime doğrulama **BLOCKED** (fiziksel cihaz + jeton bakiyesi yok).

## Inventory counts

| Metric | Count |
|---|---:|
| Backend handlers | 690 |
| Backend unique paths | 438 |
| Flutter normalized paths | 436 |
| Backend ↔ Flutter connected | 256 |
| Flutter-only / review paths | 180 |
| Fixed in Phase 2 | 0 runtime (yorum + regression genişletme) |
| Deprecated legacy literals removed | 5 pattern families |
| MCP tools (dev only) | 10 |
| Flutter runtime MCP | 0 |

## Legacy path removal (verified)

| Legacy pattern | Canonical replacement | Production `lib/` status |
|---|---|---|
| `/api/v1/*` | `/api/*` | ✅ Yok (`useApiV1=false`, regression test) |
| `/api/v2/*` | `/api/*` | ✅ Yok |
| `/api/payment/*` | `/api/payments/*` | ✅ Yok (constants + datasources) |
| `/api/membership/packages` | `/api/memberships/packages` | ✅ Yok |
| `/api/rooms/{id}/music/*` | `/api/chat/rooms/{roomId}/music*` | ✅ Yok |

**Not:** `youtube_stream_resolver.dart` içindeki `$host/api/v1/videos/$id` Invidious **harici** API'sidir; canlifal legacy değildir.

## Flutter-only path classification (180 paths)

Uploaded backend index ile Flutter `ApiEndpoints` karşılaştırması. Index eksikliği veya path normalizasyon farkı nedeniyle birçok üretim ucu "index'te yok" görünür; runtime'da backend'de mevcuttur.

| Classification | Count | Açıklama |
|---|---:|---|
| **BACKEND_CONFIRMED** | 142 | Üretimde kullanılan, backend envanterinde veya canlı API'de doğrulanmış uçlar (chat room alt yolları, PK, live, social, shorts, fal, DM, notifications vb.) |
| **BACKEND_ALIAS** | 8 | Aynı kaynağa farklı sembol (ör. `membershipsCatalog` ↔ `/api/memberships`) |
| **LEGACY** | 3 | Eski web auth: `/api/auth/login`, `/api/auth/register`, `/api/auth/refresh` — mobil JWT akışında kullanılmaz |
| **FRONTEND_LOCAL_ONLY** | 12 | Admin panel / debug-only sabitler; normal kullanıcı akışında çağrılmaz |
| **MOCK** | 0 | `ApiEndpoints` içinde mock path yok; UI mock data ayrı dosyada, API çağrısı yapmaz |
| **DUPLICATE** | 6 | Aynı path birden fazla sembol (ör. `chatRoomSongQueue` + `chatRoomSongQueueClear`) |
| **WRONG** | 0 | Phase 1'de düzeltilen payment/membership/music legacy kalmadı |
| **UNKNOWN** | 9 | Index ve canlı probe ile doğrulanamayan nadir uçlar — tahmin edilmedi, değiştirilmedi |

### UNKNOWN (değiştirilmedi — tahmin yok)

- `/api/video-streams/gifts/catalog` — backend index'te yok; Flutter sabiti `giftsCatalog` → `/api/gifts/types` alias
- `/api/gifts/insights/*` alt kümesi (8 path) — gamification; ürün kararı bekliyor

## Phase 2 code changes

1. **Regression test genişletildi** — `mobile/test/core/network/api_endpoint_canonical_contract_test.dart` artık tüm `lib/**/*.dart` tarar; legacy canlifal path literalleri fail eder; harici Invidious/Piped hariç tutulur.
2. **Yorumlar canonical** — profile/payment/membership dosyalarında `/api/payment/*` → `/api/payments/*` dokümantasyonu.
3. **Payment debug interceptor** — `/payments/` prefix ile hizalandı.
4. **API_ENDPOINT_MATRIX.md** — bozuk son satırlar düzeltildi.

## API client architecture (verified)

```
UI → Service/State (Riverpod) → Repository → ApiClient/Dio → https://canlifal.com/api/*
```

- Tek `baseUrl`: `Env.apiBaseUrl` (`https://canlifal.com`)
- `Authorization: Bearer <token>` merkezi `dio_provider` interceptor
- 401 → `POST /api/auth/mobile-refresh` (tek deneme, sonsuz retry yok)
- Token loglarda maskelenir (`PaymentDebugLog` yalnızca jwtLength)

## Feature matrix (critical)

| Feature | Auto test | Runtime device | Status |
|---|---|---|---|
| AUTH | PASS | BLOCKED | JWT login/refresh/me connected |
| PROFILE | PASS | BLOCKED | `/api/me`, profile paths connected |
| PAYMENT | PASS | BLOCKED | `/api/payments/*` canonical |
| MEMBERSHIP | PASS | BLOCKED | `/api/memberships/packages` canonical |
| GIFT | PASS | BLOCKED | Catalog + send; test hesabı 0 jeton |
| MUSIC | PASS | BLOCKED | Canonical chat room music + song-request |
| CHAT | PASS | BLOCKED | Messages, presence, stream SSE |
| SSE | PASS | BLOCKED | 5 endpoint reconnect policy |
| VOICE ROOM | PASS | BLOCKED | Join/leave/seat/gift connected |
| SEAT | PASS | BLOCKED | take/leave/swap endpoints |
| TRTC | PASS | BLOCKED | `/api/trtc/token`; client userSig üretmez |
| LIVE | PASS | BLOCKED | create/join/heartbeat/events/leave |
| PK | PASS | BLOCKED | voice + live PK HTTP; 2-user event BLOCKED |
| LIVE FALCI | PASS | BLOCKED | `/api/room/*`, live-fal paths |
| SOCIAL | PASS | BLOCKED | feed, stories, follow |
| SHORTS | PASS | BLOCKED | cursor pagination connected |
| FAL | PASS | BLOCKED | fortune endpoints present |
| NOTIFICATION | PASS | BLOCKED | list/read; push device BLOCKED |

**Legend:** PASS = `flutter analyze` + `flutter test` + acceptance scripts geçti. BLOCKED = fiziksel cihaz veya üretim hesap/jeton gerekli.

## Regression tests

| Test | Location |
|---|---|
| Canonical endpoint literals | `mobile/test/core/network/api_endpoint_canonical_contract_test.dart` |
| API v1 rewrite disabled | `mobile/test/core/network/api_version_contract_test.dart` |
| Gift jeton parse | `mobile/test/live_pk_gift_stabilize_test.dart` |
| Release gate | `scripts/acceptance-tests/api-final-phase.sh` |

## Remaining risks (not parity blockers for code)

1. **Device validation** — TRTC, SSE reconnect, gift animation, music playback gerçek cihazda doğrulanmadı.
2. **Split backend routing** — PK / bazı game uçları `ApiBackendRouter` ile abacus game backend'e yönlendirilir; ana site stub döndürür.
3. **Admin endpoints** — `ApiEndpoints` içinde admin sabitleri var; normal mobil akışta çağrılmaz.

## Conclusion

**Kod parity (Phase 2):** Legacy path'ler üretim kodundan temiz; canonical contract kullanılıyor; regression testleri genişletildi.  
**Production readiness:** Otomatik testler PASS; gerçek cihaz acceptance BLOCKED — **API PARITY KOD TARAFI TAMAM**, **ÜRETİM RELEASE HAZIR DEĞİL** (cihaz + jeton testi gerekli).
