# SOCIAL V2 — Aşama 9 Raporu

**Dal:** `cursor/social-v2-premium-5ac6`  
**Sürüm:** `1.0.328+364`  
**Tarih:** 2026-08-21

Sosyal ana akış, Shorts, hikâyeler, takip, beğeni, yorum, paylaşım ve DM — mevcut backend API + SSE/HTTP mimarisine hizalandı. Socket.IO eklenmedi; yeni endpoint uydurulmadı.

**Referans dokümanlar:** `docs/FAZ3_SOCIAL_PARITY.md`, `docs/FAZ8_SHORTS_PARITY.md`, `docs/FAZ9_MESSAGES_PARITY.md`, `docs/HOME_SHORTS_PERF_REPORT.md`  
**Bulunamayan:** `SHORTS_VE_API_ANALIZ.md`, `PERFORMANS_OPTIMIZASYON_RAPORU.md` (repoda yok)

---

# SOCIAL

## Feed

- Provider: `socialNotifierProvider` — sayfa tabanlı pagination (`page`, `limit=20`), infinite scroll
- Endpoint: `GET /api/social/posts?page&limit&feed=following`
- Pull-to-refresh: **yalnızca** `socialNotifierProvider` + `socialStoryRingsProvider` (`refreshSocialFeedOnly`) — canlı/sesli oda provider'ları artık yenilenmiyor
- Fake local post (`addLocalPost`) devre dışı; composer gerçek `POST /api/social/posts` akışına yönlendirildi

## Posts

- Kart: `SocialInstagramPostCard` — avatar, verified badge, medya, like/comment/share
- Görüntülenme: `POST /api/social/posts/{id}/view` (dedupe `_viewedPostIds`)
- Oluşturma: `/social/create` → multipart/JSON backend

## Like

- `POST /api/social/posts/{id}/likes` — optimistic UI + server reconcile
- **Düzeltme:** başarı sonrası `reconcileLike()` ile feed provider senkronu
- Hata durumunda UI geri alınır; hardcoded like count yok

## Comment

- `GET/POST /api/social/posts/{id}/comments`
- Gönderim sonrası backend yanıtı + `syncSocialPostCommentAdded` (fake local comment yok)

## Follow

- Profil modülü: `POST/DELETE /api/users/{id}/follow`
- Feed'de tekrarlayan follow API yok — relationship state profilden gelir

## Stories

- `GET /api/stories` (+ `/api/social/stories` fallback)
- Viewer: video süresi medya duration; görsel süre backend `durationMs` varsa kullanılır
- **Backend gap:** görsel story süresi yoksa 5s varsayılan (yalnızca image)

## Shorts

- Feed: `GET /api/short-videos?cursor&limit` — cursor pagination
- Playback: `ShortsVideoControllerPool` (max 5 controller), coordinator ile tek aktif video
- **Düzeltme:** GTV sample fake sponsor slotları kaldırıldı (`shorts_feed_entries.dart`)

## Video

- URL backend `videoUrl` alanından — Flutter tahmin etmez
- Thumbnail: `displayThumbnailUrl` (backend thumbnail → music cover → avatar)
- 9:16 PageView, autoplay/pause lifecycle mevcut coordinator'da

## Upload

- `POST /api/short-videos/upload` multipart + `register` — R2/CDN backend yönetir

## CDN

- `cdn.canlifal.com` / backend dönen URL'ler — client-side URL icat yok

## DM

- Liste: `GET /api/messages` veya `/api/messages/conversations`
- Gönder: `POST /api/messages/{userId}` `{content}`
- Realtime: SSE `GET /api/messages/conversations/{id}/stream` + poll yedek
- **Düzeltme:** `dedupeMessagesById()` — duplicate messageId engeli

## Real-time

- DM SSE mevcut mimari korundu; Socket.IO eklenmedi
- Global poll 12s (`DmRealtimeListener`)

## Cache

- **Yeni:** `clearSocialSessionCache()` — logout/login'de feed, stories, DM, shorts tab state temizliği
- `ApiHttpCache` + `ApiCacheStore` logout'ta zaten temizleniyor

## Performance

- Feed: pagination, RepaintBoundary, lazy lists (mevcut)
- Shorts: controller pool, preload ±2, dispose on exit
- Refresh scope daraltıldı — ana sayfa canlı/sesli rebuild yok

## Memory

- Shorts pool max 5 controller; oda/feed değişiminde dispose (mevcut)

## Tests

| Dosya | Konu |
|-------|------|
| `test/features/shorts/shorts_feed_entries_test.dart` | Fake ad yok |
| `test/features/messages/dm_message_dedupe_test.dart` | Message dedup |
| Mevcut `test/features/social/*` | Feed refresh, pagination, routes |
| Mevcut shorts/social acceptance | Regresyon |

## Multi-user tests

Cloud ortamında fiziksel çift cihaz testi yapılamadı. Manuel senaryo: A post → B like/yorum/takip/DM → duplicate event yok.

## Backend Eksikleri

1. **`/api/messages/request`** — tanımlı, implement edilmemiş (FAZ9)
2. **DM SSE üretim doğrulaması** — 404'te poll-only (FAZ9)
3. **Story görsel süresi** — backend `durationMs` her payload'da yok
4. **Feed tab** — UI'da `feed=foryou` seçeneği yok (backend destekliyor olabilir)
5. **Story view event** — ayrı view endpoint repoda net değil

## Fake/Hardcoded Data

| Bulgu | Durum |
|-------|--------|
| GTV sample shorts ads | **Kaldırıldı** |
| `addLocalPost` / `local_*` post | **Devre dışı** |
| Story image 5s fallback | Backend gap — yalnızca image, video medya süresi kullanılır |

## Değişen Dosyalar

| Dosya | Değişiklik |
|-------|------------|
| `mobile/lib/features/shorts/presentation/utils/shorts_feed_entries.dart` | Fake sponsor kaldırıldı |
| `mobile/lib/features/social/presentation/utils/social_feed_refresh.dart` | Narrow refresh scope |
| `mobile/lib/features/social/presentation/utils/social_session_cache.dart` | **Yeni** logout cleanup |
| `mobile/lib/features/social/presentation/providers/social_providers.dart` | `reconcileLike`, `addLocalPost` noop |
| `mobile/lib/features/social/presentation/widgets/instagram/social_instagram_post_card.dart` | Like feed sync |
| `mobile/lib/features/feed/presentation/widgets/feed_composer_bar.dart` | Real create post flow |
| `mobile/lib/features/feed/presentation/providers/feed_providers.dart` | `addLocalPost` noop |
| `mobile/lib/features/messages/domain/utils/dm_message_dedupe.dart` | **Yeni** |
| `mobile/lib/features/messages/data/repositories/messages_repository_impl.dart` | Dedup on fetch |
| `mobile/lib/features/messages/presentation/providers/chat_messages_list_notifier.dart` | Dedup on load |
| `mobile/lib/features/social/domain/entities/social_story_ring_entity.dart` | `durationMs` |
| `mobile/lib/features/social/data/datasources/social_remote_datasource.dart` | Parse duration |
| `mobile/lib/features/social/presentation/pages/story_viewer_page.dart` | Backend duration |
| `mobile/lib/core/bootstrap/session_data_refresh.dart` | Social cache on login refresh |
| `mobile/lib/features/auth/presentation/providers/auth_providers.dart` | Logout social cleanup |
| Tests + `mobile/pubspec.yaml` + `mobile/CHANGELOG.md` | |

---

**Not:** Tencent RTC / canlı yayın sistemine dokunulmadı.
