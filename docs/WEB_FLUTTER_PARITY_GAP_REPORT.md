# Web ↔ Flutter Parity Gap Report

> **Tarih:** 31 Temmuz 2026  
> **Tek kaynak:** [`FLUTTER_ENTegrasyon_KILAVUZU.md`](FLUTTER_ENTegrasyon_KILAVUZU.md) + canlifal.com üretim  
> **Sürüm:** `1.0.115+148` (Faz 5 tamamlandı)

## Kabul kriterleri durumu

| Kriter | Durum | Not |
|--------|-------|-----|
| Aynı endpoint'ler | 🟢 | Theme, popups, ads, fortune-request-types registry |
| Aynı response model | 🟡 Kısmen | PostEntity metadata genişletildi |
| Aynı event sistemi (SSE) | 🟢 | 5 kılavuz SSE + bildirim SSE → DM/home invalidation |
| JWT / Bearer | 🟢 | Auth `features/auth/data` |
| Cache web parity | 🟡 | Voice discover 2dk; home keepAlive SSE invalidation |
| Gerçek zamanlı hediye | 🟢 | Canlı SSE aktifken poll kapalı |
| Tek repository | 🟢 | Legacy `services/` kaldırıldı |
| Global state | 🟢 | Live + voice + home streams tek kaynak |
| Performans | 🟡 | RepaintBoundary home live + shorts grid; preload ±2 |

---

## Faz 5 — Tamamlanan (1.0.115+148)

| Alan | Değişiklik |
|------|------------|
| Platform API | popups, ads/active, ads/reward, fortune-request-types, user/theme |
| Popup UI | `AppPopupsListener` shell içinde |
| Tema | `UserThemeSync` — ayarlar + giriş sonrası pull |
| Canlı fal | API tür kataloğu; `my-status` datasource |
| DM SSE | 404 → reconnect kapalı, poll-only |
| 429 | `ApiSnackBar` + `ApiException` rate-limit |
| Shorts | Controller pool ±2; keşfet grid RepaintBoundary |
| Modeller | Chat test modelleri → `voice_hub/data/models` |

## Faz 4 — Tamamlanan (1.0.114+147)

| Alan | Değişiklik |
|------|------------|
| Legacy services | Auth/config/compound → feature/core; `services/*.dart` silindi |
| Ana sayfa canlı | `homeLiveStreamsProvider` ← `liveStreamsListNotifier` |
| Home invalidation | `invalidateHomeKeepAliveProviders` — bildirim SSE + realtime bridge |
| DM realtime | Bildirim SSE mesaj tipi; `MessageSseService` + `conversationStream` |
| API registry | Chat room music log → `ApiEndpoints` |
| Cache | Voice discover bundle TTL 3dk → 2dk |
| Performans | `RepaintBoundary` ana sayfa canlı kartları |

## Faz 3 — Tamamlanan (1.0.113+146)

| Alan | Değişiklik |
|------|------------|
| Sosyal akış | `socialNotifierProvider` migration |
| Sesli odalar | `voiceRoomsListNotifier` tek kaynak |
| Hediye registry | insights/battle/goal/admin |
| DM | `openDmConversationIdProvider` |
| Legacy | `@Deprecated` services (Faz 4'te kaldırıldı) |

## Faz 2 — Tamamlanan (1.0.112+145)

| Alan | Değişiklik |
|------|------------|
| Canlı keşif | `discover_live_streams.dart` |
| Global state | followers/following/postComments |
| DM poll | çift poll kaldırıldı |
| Admin | ödeme SSE |

---

_Bu dosya parity çalışması ilerledikçe güncellenir._
