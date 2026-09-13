# Abacus ZIP paketi — dosya envanteri

> **Üretim:** 2026-09-13 02:19 UTC · `scripts/generate_abacus_zip_roadmap.py`
> **Kaynak:** `backend-reference/canlifal_flutter_paketi/` (değiştirilmez)

## Özet

| Ölçüm | Değer |
|-------|------:|
| Paket dosyası (toplam) | 77 |
| Doküman / sözleşme | 26 |
| `kaynak/lib/*.ts` referans | 28 |
| OpenAPI `FLUTTER_READY` path | 306 |

## Ana dosyalar (okuma sırası)

1. `00_OKU_BENI.md` — giriş
2. `TUM_OZELLIKLER_HARITASI.md` — 19 özellik alanı (§1–§19)
3. `ENDPOINTS.md` / `endpoints_index.json` — 953 uç
4. `endpoint_classification.json` — FLUTTER_READY / PUBLIC / ADMIN
5. `openapi.yaml` — OpenAPI 3.0.3
6. `authentication.md` · `REALTIME.md` · `websocket_events.md`
7. `BOLUM22_MULTIGUEST_PK_GIFTBOX.md`
8. `live_stream_api.md` · `voice_room_api.md` · `gifts_coins_wallet_api.md`
9. `flutter_integration_checklist.md`
10. `kaynak/` — prisma + kritik lib TS

## Tam dosya listesi (zip)

- `00_OKU_BENI.docx`
- `00_OKU_BENI.md`
- `00_OKU_BENI.pdf`
- `AUTHENTICATION.docx`
- `AUTHENTICATION.md`
- `AUTHENTICATION.pdf`
- `BOLUM22_MULTIGUEST_PK_GIFTBOX.docx`
- `BOLUM22_MULTIGUEST_PK_GIFTBOX.md`
- `BOLUM22_MULTIGUEST_PK_GIFTBOX.pdf`
- `DATA_MODELS.md`
- `ENDPOINTS.md`
- `FLUTTER_BACKEND_INTEGRATION_SPEC.docx`
- `FLUTTER_BACKEND_INTEGRATION_SPEC.md`
- `FLUTTER_BACKEND_INTEGRATION_SPEC.pdf`
- `FLUTTER_ENTEGRASYON_REHBERI.docx`
- `FLUTTER_ENTEGRASYON_REHBERI.md`
- `FLUTTER_ENTEGRASYON_REHBERI.pdf`
- `MCP_VE_ENTEGRASYONLAR.docx`
- `MCP_VE_ENTEGRASYONLAR.md`
- `MCP_VE_ENTEGRASYONLAR.pdf`
- `REALTIME.docx`
- `REALTIME.md`
- `REALTIME.pdf`
- `SERVICES.md`
- `TUM_OZELLIKLER_HARITASI.docx`
- `TUM_OZELLIKLER_HARITASI.md`
- `TUM_OZELLIKLER_HARITASI.pdf`
- `admin_permissions.md`
- `authentication.docx`
- `authentication.md`
- `authentication.pdf`
- `data_models.json`
- `database_schema.sql`
- `endpoint_classification.json`
- `endpoint_classification.md`
- `endpoints_index.json`
- `flutter_integration_checklist.docx`
- `flutter_integration_checklist.md`
- `flutter_integration_checklist.pdf`
- `gifts_coins_wallet_api.docx`
- `gifts_coins_wallet_api.md`
- `gifts_coins_wallet_api.pdf`
- `kaynak/lib/admin-utils.ts`
- `kaynak/lib/api-response.ts`
- `kaynak/lib/audit-log.ts`
- `kaynak/lib/auth-options.ts`
- `kaynak/lib/balance-guard.ts`
- `kaynak/lib/chat-events.ts`
- `kaynak/lib/critical-confirm.ts`
- `kaynak/lib/currency-branding.ts`
- `kaynak/lib/deeplink.ts`
- `kaynak/lib/gift-box.ts`
- `kaynak/lib/gift-pk-score.ts`
- `kaynak/lib/idempotency.ts`
- `kaynak/lib/ledger.ts`
- `kaynak/lib/live-guest.ts`
- `kaynak/lib/mobile-auth.ts`
- `kaynak/lib/pagination.ts`
- `kaynak/lib/payment-status.ts`
- `kaynak/lib/permissions.ts`
- `kaynak/lib/pk-state.ts`
- `kaynak/lib/presence-engine.ts`
- `kaynak/lib/rate-limit-guard.ts`
- `kaynak/lib/rbac.ts`
- `kaynak/lib/room-events.ts`
- `kaynak/lib/stream-events.ts`
- `kaynak/lib/trtc-room.ts`
- `kaynak/lib/voice-room-events.ts`
- `kaynak/lib/webrtc-config.ts`
- `kaynak/middleware.ts`
- `kaynak/prisma/schema.prisma`
- `live_stream_api.md`
- `openapi.yaml`
- `postman_collection.json`
- `ranking_api.md`
- `voice_room_api.md`
- `websocket_events.md`

## Flutter eşleme stratejisi

- **Sıra:** `TUM_OZELLIKLER_HARITASI.md` §1 → §18 (admin §19 web-only).
- **Katman:** `api_endpoints.dart` → feature `*RemoteDataSource` → Riverpod → mevcut UI.
- **Şema MISSING:** ham `Map` / `pick()` — alan uydurulmaz.
- **Katalog:** `mobile/lib/core/abacus/abacus_flutter_ready_catalog.dart` (otomatik).
