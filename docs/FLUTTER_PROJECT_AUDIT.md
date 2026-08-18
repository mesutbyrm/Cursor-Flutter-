# FAZ 0 — Flutter Proje Audit

**Tarih:** 2026-08-18  
**Sürüm:** `1.0.256+292` (`mobile/pubspec.yaml`)  
**Kapsam:** `mobile/` — kod değiştirilmedi, yalnızca analiz  
**Birincil kaynak:** `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` (27 Haziran 2026)

---

## 1. Özet

| Metrik | Değer |
|--------|------:|
| Dart dosyası (`lib/`) | ~1.543 |
| Test dosyası (`test/`) | 179 |
| Feature modülü | 34 |
| `api_endpoints.dart` sabit path | ~471 |
| Matrix satırı (`API_ENDPOINT_MATRIX.md`) | ~873 |
| State management (birincil) | Riverpod 2.6 |
| State management (ikincil) | flutter_bloc (oda müziği) |
| Routing | go_router 15 |
| RTC SDK | Tencent TRTC 13.2 (`tencent_rtc_sdk`) |
| Gerçek zamanlı (birincil) | SSE |
| Gerçek zamanlı (legacy) | Socket.IO (live gift — kısmi) |

**Durum:** Olgun, geniş kapsamlı üretim mobil istemci. Mimari clean-architecture eğilimli; `voice_hub` ve `live` en karmaşık modüller. Agora kaldırılmış; TRTC birincil.

---

## 2. Klasör yapısı

```
mobile/lib/
├── main.dart
├── app/                 # Router, shell, global overlay
├── core/                # network, auth, SSE, theme, bootstrap
├── features/            # 34 feature modülü
└── services/            # Legacy stub modeller (9 dosya — kullanım dışı riski)
```

### Feature modülleri (34)

| Modül | Dosya yoğunluğu | Not |
|-------|-----------------|-----|
| `voice_hub` | ~312 | Sesli oda, müzik, PK, SSE, TRTC |
| `live` | ~158 | Canlı yayın, PK, guest grid |
| `gifts` | ~108 | Hediye, battle, global overlay |
| `fortune` | ~107 | Fal türleri, SSE streaming |
| `profile` | ~101 | Profil hub, jeton/CFC, üyelik |
| `social` | 46 | Feed, story, post |
| `auth` | 32 | JWT, Google/Apple |
| `notifications` | 11 | SSE + liste |
| `trtc` | 10 | Token, bootstrap, coordinator |
| `shorts` | — | Dikey video |
| `messages` | — | DM + SSE |
| `wallet` | — | Jeton/CFC |
| `home` | — | Ana sayfa bootstrap |
| Diğer | admin, games, membership, referral, … | |

---

## 3. Mimari katmanlar

Hedef mimari (kılavuz §3–4) ile mevcut durum:

| Katman | Durum | Konum |
|--------|-------|-------|
| UI | ✅ | `features/*/presentation/` |
| State (Riverpod) | ✅ | `*providers.dart`, notifiers |
| Repository | ✅ Kısmi | `data/repositories/` |
| Remote datasource | ✅ | `data/datasources/` |
| API client | ✅ Merkezi | `core/network/dio_provider.dart` |
| Endpoints | ✅ Merkezi | `core/network/api_endpoints.dart` |
| Auth / token | ✅ | `token_storage.dart`, `auth_token_refresh_coordinator.dart` |
| Error handling | ✅ | `api_exception.dart`, `error_handler.dart` |
| Retry | ✅ | `api_retry_interceptor.dart` |
| SSE hub | ✅ | `core/network/sse/sse_connection_hub.dart` |

**Sapma:** Bazı feature'lar (özellikle `voice_hub`) god-file provider'lara sahip (`chat_room_providers.dart` + partials). Repository pattern her yerde tutarlı değil; büyük datasource dosyaları var (`chat_room_remote_datasource.dart`).

---

## 4. Ağ ve kimlik doğrulama

| Bileşen | Dosya | Davranış |
|---------|-------|----------|
| Base URL | `core/config/env.dart` | `https://canlifal.com` |
| JWT depolama | `core/network/token_storage.dart` | `flutter_secure_storage` |
| Refresh | `auth_token_refresh_coordinator.dart` | 401 → `POST /api/auth/mobile-refresh` |
| Dual backend | `api_backend_router.dart` | Main + games API (PK) |
| Cookie | `lazy_cookie_jar.dart` | Web parity (mobilde sınırlı) |

---

## 5. SSE (gerçek zamanlı)

### Altyapı
- `core/sse_client.dart`, `core/network/sse/base_sse_service.dart`
- `sse_connection_hub.dart` — ref-count, reconnect backoff (max 20)
- `sse_reconnect_policy.dart`

### Feature SSE servisleri

| Servis | Path (kılavuz) | Dosya |
|--------|----------------|-------|
| Chat room | `GET /api/chat/rooms/{id}/stream` | `chat_room_sse_service.dart` |
| Live video | — | `video_stream_sse_service.dart` |
| Notifications | `GET /api/notifications/stream` | `notifications_sse_service.dart` |
| Messages | — | `message_sse_service.dart` |
| Fortune stream | — | `fortune_sse_service.dart` |
| Psychic room | — | `psychic_room_sse_service.dart` |
| PK match | — | `pk_match_sse_service.dart` |

**Risk:** Live gift hâlâ Socket.IO kullanıyor (`live_gift_realtime_service.dart`). Kılavuz SSE öncelikli; dual realtime karmaşıklık ve ANR riski.

---

## 6. Tencent RTC

| Bileşen | Dosya |
|---------|-------|
| SDK wrapper | `voice_hub/.../voice_trtc_engine.dart` |
| Audio coordinator | `voice_room_audio_coordinator.dart` |
| TRTC modül | `features/trtc/` |
| Token API | `trtc_remote_datasource.dart` → `/api/trtc/token` |
| Music mixer | `voice_room_trtc_music_mixer.dart` |

Agora referansları yalnızca legacy alias/comment; üretimde kullanılmıyor.

---

## 7. Müzik sistemi (sesli oda)

| Katman | Dosya |
|--------|-------|
| API | `chat_room_remote_datasource.dart` — `music-request-by-query`, `song-request` |
| State | `chat_room_providers*.dart` |
| Oynatıcı | `voice_room_dj_player.dart`, `room_music_service.dart` |
| Video | `room_video_controller.dart`, `youtube_video_background.dart` |
| Bloc | `room_song_bloc.dart` |

**Bilinen sorun (P0):** `!istek` / müzik isteği sonrası ANR — grace/SSE/iframe yolu üzerinde aktif düzeltme (`1.0.256+292`).

---

## 8. Routing

- `app/router/app_router.dart` — go_router, ~1.200 satır
- Shell: 5 tab (`/feed`, `/social`, `/live`, `/fortune`, `/profile`)
- Voice: `/voice-room/:id` (shell dışı)
- Auth redirect: `AuthRedirect.targetFor`

---

## 9. Testler

| Alan | Test sayısı (yaklaşık) |
|------|----------------------:|
| voice_hub | 30 |
| gifts | 17 |
| social | 14 |
| profile | 13 |
| acceptance | 1 (`client_acceptance_test.dart`, 20 madde CI) |
| SSE | 3 |
| Toplam | 179 |

**Eksik:** TRTC gerçek cihaz E2E, müzik `!istek` E2E, PK tam akış E2E otomasyonu sınırlı.

---

## 10. Performans ve teknik borç

| Risk | Önem | Detay |
|------|------|-------|
| God files | P1 | `chat_room_providers.dart`, `live_broadcast_room_page.dart` |
| Dual realtime | P1 | SSE + Socket.IO |
| Dual müzik çıkışı | P1 | TRTC mixer + WebView/just_audio |
| Legacy stubs | P2 | `mobile/lib/services/` |
| MCP stub | P1 | Repodaki MCP yalnızca matrix okur; backend MCP değil |
| Eski audit | P2 | `FLUTTER_AUDIT.md` (Ağustos 2026 öncesi sürüm) |

---

## 11. Dokümantasyon envanteri (repoda mevcut)

| Dosya | Rol |
|-------|-----|
| `FLUTTER_ENTegrasyon_KILAVUZU.md` | **Tek kaynak** — endpoint, auth, SSE |
| `API_ENDPOINT_MATRIX.md` | 873 satır matrix |
| `API_INTEGRATION_AUDIT.md` | Parity özeti (Ağustos 2026) |
| `ROOM_MUSIC_SYSTEM.md` | Müzik mimarisi |
| `STAGE7_MUSIC_ISTEK_ACCEPTANCE_REPORT.md` | Müzik istek acceptance |
| `AGENTS.md` | Agent iş akışı |

---

## 12. FAZ 0 sonucu

| Kriter | Durum |
|--------|-------|
| Proje yapısı belgelendi | ✅ |
| Mimari haritalandı | ✅ |
| Riskler listelendi | ✅ |
| Kod değişikliği | ❌ Yapılmadı (kurala uygun) |

**Sonraki adım:** `BACKEND_FLUTTER_PARITY_AUDIT.md` + backend'den eksik dosya talebi.
