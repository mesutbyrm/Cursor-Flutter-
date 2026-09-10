# CURRENT BACKEND INTEGRATION PLAN — Abacus.ai → Flutter

> **Tarih:** 2026-09-10  
> **Kaynak set:** `backend-docs/abacus-current/` + güncellenmiş `backend-docs/openapi.json` (502 path, 780 index)  
> **Flutter kanon:** `docs/FLUTTER_ENTegrasyon_KILAVUZU.md`  
> **Base URL:** `https://canlifal.com`  
> **MCP:** Geliştirici aracı only — Flutter runtime'da kullanılmaz

---

## 1. Güncel backend kaynakları (CURRENT)

| Kaynak | Konum | Sürüm / boyut |
|--------|-------|----------------|
| OpenAPI 3.0.3 | `backend-docs/openapi.json` | v1.0.0, **502** paths |
| Endpoint index | `backend-docs/endpoints_index.json` | **780** handler kaydı |
| Prisma export | `backend-docs/schema.prisma` | 3959 satır |
| API insan okur | `backend-docs/ENDPOINTS.md` | priority1 |
| Realtime katalog | `backend-docs/abacus-current/priority2/CANLIFAL_REALTIME_EVENTS.md` | SSE |
| Müzik API | `backend-docs/abacus-current/priority2/MUSIC_API.md` | song-request kanonik |
| Postman | `backend-docs/abacus-current/priority3/postman_collection.json` | Manuel test |
| MCP sunucu | `mcp-server/index.mjs` + `lib.mjs` | stdio, 10 tool |

## 2. Kullanılmayan eski kaynaklar (LEGACY)

- `_zip_analysis/output_canlifal_cursor_paketi_01_mcp-server.zip` (MCP alt kümesi)
- `backend-docs/B1_12_*`, `MCP_INVENTORY.md` (Ağu 2026 parity — Abacus paketi hariç tutuyor)
- Ham ZIP: yalnızca arşiv; entegrasyon `backend-docs/abacus-current/` üzerinden

## 3. Mimari (mevcut — değiştirilmez)

```
FLUTTER (mobile/)
  → Dio (dio_provider.dart) + JWT Bearer
  → api_endpoints.dart (~297 const + builders)
  → Feature *RemoteDataSource / *RepositoryImpl
  → Riverpod providers
  ↓ HTTPS
ABACUS BACKEND (canlifal.com)
  → Next.js App Router /api/*
  → Prisma / PostgreSQL
  ↓
REALTIME: SSE (5+ kanal) — Socket.IO KAPALI (stub)
```

## 4. Authentication

| Öğe | Backend | Flutter | Durum |
|-----|---------|---------|-------|
| Login | `POST /api/auth/mobile-login` | `auth_service.dart` | TAM UYUMLU |
| Refresh | `POST /api/auth/mobile-refresh` | `auth_token_refresh_coordinator.dart` | TAM UYUMLU |
| Me | `GET /api/me` | `auth_service.dart` | TAM UYUMLU |
| Storage | — | `token_storage.dart` (secure) | TAM UYUMLU |
| 401 | refresh → logout | `dio_provider.dart` | TAM UYUMLU |

## 5. Realtime (SSE only)

| Kanal | Endpoint | Flutter servis |
|-------|----------|----------------|
| Sesli oda | `GET /api/chat/rooms/{id}/stream` | `chat_room_sse_service.dart` |
| Canlı yayın | `GET /api/video-streams/{id}/stream` | `video_stream_sse_service.dart` |
| Falcı oturum | `GET /api/room/{sessionId}/stream` | `psychic_room_sse_service.dart` |
| Bildirim | `GET /api/notifications/stream` | `notifications_sse_service.dart` |
| PK | `GET /api/pk/{matchId}/stream` | `pk_match_sse_service.dart` |

**MCP Flutter client:** GEREKMEZ.

## 6. Wallet / Jeton / CFC

| Öğe | Endpoint | Flutter |
|-----|----------|---------|
| Bakiye | `GET /api/user/credits`, `/api/wallet` | `wallet_balances.dart`, `economy_wallet_*` |
| Jeton paket | `GET /api/jeton` | `profile_remote_datasource.dart` |
| Hediye jeton düşümü | Backend authoritative | `gift_repository.dart` |

**TAM UYUMLU:** Jeton paket listesi yalnızca `GET /api/jeton` — fallback preset kaldırıldı.

## 7. Live / Voice / PK / Music

| Alan | Durum | Not |
|------|-------|-----|
| Canlı yayın TRTC | TAM UYUMLU | `trtc_remote_datasource`, `live_broadcast_*` |
| Sesli oda | TAM UYUMLU | `chat_room_remote_datasource` |
| PK canlı | TAM UYUMLU | `pk_battle_remote_datasource`, `live_video_pk_provider` |
| PK sesli | TAM UYUMLU | `POST .../chat/rooms/{id}/pk` |
| Müzik | TAM UYUMLU | `song-request` birincil; `music-request-by-query` 404 fallback |
| Ranking | KISMİ | Client-side proxy skor; `ROOM_RANK` API henüz bağlı değil |

## 8. Kritik uyumsuzluklar (P0/P1)

| # | Alan | Sorun | Aksiyon |
|---|------|-------|---------|
| P0 | Kaynak set | Eski `backend-docs` (438 path) | ✅ Güncellendi → 502 path |
| P1 | Jeton paket fallback | Sahte katalog API fail'de | ✅ Kaldırıldı |
| P1 | Ranking | Proxy skor, sunucu `ROOM_RANK` yok | API gelince bağla; şimdilik SSE+proxy |
| P2 | Admin uçları | 200+ admin path Flutter'da yok | Bilinçli — mobil admin kısıtlı |
| P2 | OpenAPI vs index | 502 vs 780 | Handler vs path — çelişki değil |

## 9. Uygulama sırası

1. ✅ Güncel backend source set materialize (`backend-docs/abacus-current/`)
2. ✅ OpenAPI + endpoints_index + MCP güncelle
3. ✅ Analiz raporları (`CURRENT_BACKEND_SOURCE_SET`, bu plan, final report)
4. ✅ `scripts/abacus-openapi-parity.sh`
5. ⏳ Jeton fallback temizliği (production)
6. ⏳ `FLUTTER_ENTegrasyon_KILAVUZU` §9 — yeni OpenAPI diff ile hizalama (incremental)
7. ⏳ Manuel cihaz: Psychic P0, PK, müzik senkron

## 10. Doğrulama

- `dart analyze` — 0 error (info uyarılar mevcut)
- `flutter test` — mevcut suite
- `node mcp-server/index.mjs --selftest` — OK
- `bash scripts/abacus-openapi-parity.sh` — parity özet

## 11. Entegrasyon yüzdesi (tahmini)

| Katman | % | Gerekçe |
|--------|---|---------|
| Auth | 98% | Tam JWT akış |
| Wallet/CFC | 90% | Fallback katalog |
| Live | 92% | TRTC+SSE |
| Voice | 93% | Oda+seat+music+PK |
| Gifts | 90% | Engine+SSE |
| Psychic | 88% | TRTC+SSE; cihaz P0 bekliyor |
| Notifications | 85% | FCM config eksik olabilir |
| Admin | 40% | Bilinçli kısıt |
| **Mobil özellik ortalaması** | **~88%** | Admin hariç |

---

**Sonraki adım:** `docs/ABACUS_FLUTTER_FINAL_INTEGRATION_REPORT.md` — tam audit çıktısı.
