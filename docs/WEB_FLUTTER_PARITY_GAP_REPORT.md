# Web ↔ Flutter Parity Gap Report

> **Tarih:** 31 Temmuz 2026  
> **Tek kaynak:** [`FLUTTER_ENTegrasyon_KILAVUZU.md`](FLUTTER_ENTegrasyon_KILAVUZU.md) + canlifal.com üretim  
> **Sürüm:** `1.0.114+147` (Faz 4 tamamlandı)

## Kabul kriterleri durumu

| Kriter | Durum | Not |
|--------|-------|-----|
| Aynı endpoint'ler | 🟡 Kısmen | Gift + chat room registry; kalan §9 uçları devam |
| Aynı response model | 🟡 Kısmen | PostEntity metadata genişletildi |
| Aynı event sistemi (SSE) | 🟢 | 5 kılavuz SSE + bildirim SSE → DM/home invalidation |
| JWT / Bearer | 🟢 | Auth `features/auth/data` |
| Cache web parity | 🟡 | Voice discover 2dk; home keepAlive SSE invalidation |
| Gerçek zamanlı hediye | 🟢 | Canlı SSE aktifken poll kapalı |
| Tek repository | 🟢 | Legacy `services/` kaldırıldı (modeller test için `services/models`) |
| Global state | 🟢 | Live + voice + home streams tek kaynak |
| Performans | 🟡 | RepaintBoundary home live; liveStreams copyWithPrevious |

---

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

## Faz 5 — Sıradaki

1. Kalan §9 endpoint UI bağlantıları (theme, popups, ads, fortune-request-types)
2. `services/models` chat test modellerini feature'a taşı
3. DM SSE üretim doğrulama (404 ise poll-only)
4. Shorts preload + grid RepaintBoundary genişletme
5. 429 standart snackbar

---

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
