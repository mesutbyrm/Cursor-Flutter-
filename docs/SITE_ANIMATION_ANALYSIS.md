# Site Animasyonları — Sistem Analizi ve Mimari Plan

> Tarih: 8 Eylül 2026 · Dal: `cursor/site-animation-engine-5ac6` · PR #365

Bu belge, kullanıcı spesifikasyonu §34 sırasına göre mevcut CanlıFal mimarisinin analizini, boşluk matrisini ve uygulama planını içerir. Tasarım referansı olarak belirtilen 7 uygulama ekran görüntüsü repoda dosya olarak bulunmuyor; mevcut Flutter tema token'ları (`VoiceRoomTokens`, `DiscoverBackground`, `0xFF0E0524` zemin) ve admin seed katalogu bu referansların yerine geçer.

---

## 1. Mevcut Flutter Mimarisi

| Katman | Konum | Durum |
|--------|-------|-------|
| Domain | `mobile/lib/core/site_animation/domain/` | `SiteAnimationType`, `SiteAnimationTier`, `SiteAnimationCommand`, `SiteAnimationLayout`, `SiteAnimationAsset` |
| Data | `mobile/lib/core/site_animation/data/` | Parser, Resolver, Catalog datasource, Repository, Asset registry, Cache |
| Application | `mobile/lib/core/site_animation/application/` | `SiteAnimationManager` — kuyruk, dedupe, preload |
| Presentation | `mobile/lib/core/site_animation/presentation/` | Riverpod provider, overlay host, card, media widgets |
| Admin | `mobile/lib/features/admin/presentation/pages/admin_site_animations_*` | Hub, kütüphane, defaults, assign, preview |
| Entegrasyon | `chat_room_providers_room_sync.dart` | SSE `room_event` → `_dispatchSiteAnimation` |
| Overlay host | `fx_voice_room_overlay_host.dart`, voice room pages | Sesli oda üzerinde overlay |

**Animasyon teknolojisi:** Flutter native (card slide/scale), Lottie (`assets/gifts/lottie/*.json`), video/SVGA/Rive altyapısı parser'da hazır. Yeni paket eklenmedi.

**Mimari hedef:** Repository + Riverpod — kılavuz §9.14 `SiteAnimationRepository` ile uyumlu.

---

## 2. Backend Mimarisi

| Katman | Konum | Durum |
|--------|-------|-------|
| Prisma | `SiteAnimation`, `SiteAnimationDefault`, `SiteAnimationUserAssignment` | Migration `20260908100000_site_animations` |
| Store | `api/src/lib/siteAnimationStore.ts` | Prisma + JSON fallback |
| Seed | `siteAnimationSeed.ts`, `siteAnimationBootstrap.ts` | ~32 kayıt, idempotent bootstrap |
| Resolver | `siteAnimationResolver.ts` | SSE payload enrichment |
| Emitter | `siteAnimationEmitter.ts` | Paylaşımlı `emitResolvedRoomAnimation` |
| Routes | `api/src/routes/site_animations.ts` | Admin CRUD + public `/active` |
| Chat rooms | `chat_rooms.ts`, `live_field.ts` | join/leave/seat/mic/owner SSE |

**Üretim:** canlifal.com Next.js — bu repo `api/` mirror'ı. Production deploy ayrı adım.

---

## 3. Realtime Sistemi

- **Protokol:** SSE (Socket.IO değil) — kılavuz §5
- **Oda olayı:** `GET /api/chat/rooms/{id}/stream` → `room_event`
- **Desteklenen event'ler:** `user_joined`, `user_left`, `seat_changed`, `mic_changed`, `owner_changed`
- **Zenginleştirme:** Sunucu `animationMetadata` ile giriş animasyon ID'si ekler
- **Oda izolasyonu:** `roomEventMatchesActiveRoom` — farklı oda görmez
- **Dedupe:** `FxDedupeStore` + `eventId`
- **Kuyruk:** `SiteAnimationManager` priority sıralı
- **Eksik:** Kendi giriş animasyonunu görmeme filtresi (bu oturumda eklendi)

---

## 4. Authentication

- JWT Bearer — `/api/auth/mobile-login`, `/api/auth/mobile-refresh`, `/api/me`
- Mobil: `authControllerProvider` → `id`, `realCid`/`gcid`
- Admin: `staffAccessProvider.canManageSiteAnimations`
- Kullanıcı anahtarı: `sub` değil, `realCid` / `gcid`

---

## 5. Membership Sistemi

| Uygulama (`VipTier`) | SiteAnimationTier | Spec eşlemesi |
|---------------------|-------------------|---------------|
| basic | normal | NORMAL |
| premium | premium | SILVER / PLATINUM |
| gold | gold | GOLD |
| diamond | diamond | DIAMOND |
| svip | svip | SVIP / EMPEROR |
| — | vip | VIP (ayrı membership string) |
| staff admin/founder | admin | ADMIN |
| host/owner | host | HOST |

**Varsayılan giriş eşlemesi (admin değiştirilebilir):**

| Tier | Animasyon |
|------|-----------|
| normal | Basic Fade |
| gold | Golden Crown |
| premium | Golden Spotlight |
| diamond | Diamond Burst |
| vip | Royal Gate |
| svip | Galaxy VIP |
| admin | Admin Galaxy |
| host | Host Seat Crown |

Admin özel atama (`ADMIN_CUSTOM` priority 110) resolver'da `priorityOverride` ile uygulanır.

---

## 6. Profile Sistemi

- Profil ekranı mevcut avatar boyutu/konumu korunmalı
- `AdminSiteAnimationSlot.profileFrame`, `.profile`, `.avatar` tanımlı
- **Eksik (Faz 2+):** Profil açılış animasyonu renderer, frame widget entegrasyonu
- **Bu oturum:** 12 profil çerçevesi seed kataloga eklendi

---

## 7. Voice Room Sistemi

- SSE sync: `chat_room_providers_room_sync.dart`
- Overlay: `SiteAnimationOverlayHost` voice room stack'inde
- Giriş kartı: 4 fazlı animasyon (~520ms giriş + hold + çıkış)
- Koltuk glow: `seat_rank_glow` join'de koltuk varsa
- Süre: 2.5–4 sn clamp
- **Çalışıyor:** Gold/Diamond/VIP entrance, queue, dedupe

---

## 8. Live Sistemi

- PK battle SSE: `_tryApplyPkRoomEvent`
- `live_field.ts` + `video_streams.ts` join/leave → SSE `userJoined` / `userLeft`
- `LiveBroadcastRoomPage` → `SiteAnimationContextHost(liveStream)`
- Büyük hediye → `ctx_gift` site animasyon köprüsü

---

## 9. Social Sistemi

- `SocialPage` → `SiteAnimationContextHost(social)` overlay host
- Admin preview: çoklu ekran mock (Sosyal/Profil/Fal/Voice)

---

## 10. Admin Paneli

- Giriş: `/admin/site-animations` hub
- Alt sayfalar: kütüphane, ekle, defaults, user-assign, bulk-assign, preview
- Yetki: `canManageSiteAnimations`
- API fallback: SharedPreferences + seed
- **Bu oturum:** 16 kategori navigasyonu, çoklu ekran önizleme

---

## Boşluk Matrisi (Spec vs Mevcut)

| Özellik | Durum |
|---------|-------|
| 12 giriş animasyonu | ✅ Seed genişletildi |
| 12 profil çerçevesi | ✅ Seed eklendi |
| 16 admin kategori | ✅ Hub navigasyonu |
| Çoklu ekran preview | ✅ Sosyal/Profil/Fal/Voice |
| Kendi girişini görmeme | ✅ Provider filtresi |
| Priority spec (110 admin) | ✅ Tier güncellendi |
| Profil frame + avatar efekt | ✅ Runtime entegrasyon |
| Live / Fal / Gift overlay | ✅ ctx_live, ctx_fal_tarot, ctx_gift |
| Oyun overlay host | ✅ ctx_game (hub + oda) |
| Hediye katalog seed | ✅ gift kategorisi (4 tier) |
| Sosyal entrance SSE hook | ⏳ Üretim SSE sözleşmesi bekliyor |
| Production deploy | ⏳ canlifal.com ayrı |

---

## Mimari Plan

```
┌─────────────────┐     GET /active      ┌──────────────────┐
│  Admin Panel    │ ───────────────────► │ SiteAnimation    │
│  (Flutter)      │     CRUD/assign      │ API (api/)       │
└────────┬────────┘                      └────────┬─────────┘
         │ seed fallback                         │ Prisma
         ▼                                         ▼
┌─────────────────┐     SSE room_event   ┌──────────────────┐
│ SiteAnimation   │ ◄─────────────────── │ Chat Room API    │
│ CatalogProvider │                      │ + Resolver       │
└────────┬────────┘                      └──────────────────┘
         │
         ▼
┌─────────────────┐
│ SiteAnimation   │  queue + dedupe + self-filter
│ Manager         │
└────────┬────────┘
         ▼
┌─────────────────┐
│ Overlay Host    │  voice / (future: live, social, profile)
└─────────────────┘
```

---

## Database / Model Planı

Mevcut Prisma modelleri spec alanlarının çoğunu karşılar:

- `id`, `name`, `category`, `membership`, `animationType`, `assetUrl`
- `durationMs`, `priority`, `rarity`, `context`, `anchor`, `scale`
- `cooldownMs`, `isActive`, `previewMp4Key`, `description`
- `SiteAnimationDefault` — tier → animationId
- `SiteAnimationUserAssignment` — userId, slot, animationId, expiresAt

---

## Backend Event Planı

`ROOM_JOINED` / `user_joined` payload:

```json
{
  "event": "user_joined",
  "roomId": "...",
  "userId": "...",
  "name": "...",
  "avatarUrl": "...",
  "membershipLevel": "gold",
  "entranceAnimationId": "anim_entrance_gold_crown",
  "animation": { "anchor": "TOP_LEFT", "durationMs": 3000, "priority": 110 },
  "eventId": "room:user:ts",
  "timestamp": 1690000000
}
```

Sunucu: `buildSiteAnimationRoomEvent` → membership default veya user assignment → emit.

---

## Uygulama Sırası (Kalan)

1. ✅ Analiz (bu belge)
2. ✅ Seed genişletme
3. ✅ Self-filter + priority
4. ✅ Admin hub + preview
5. ✅ Profil frame + avatar efekt renderer
6. ✅ Live / Gift / Fal / Game overlay host
7. ⏳ Sosyal feed entrance SSE (üretim sözleşmesi)
8. ⏳ Production deploy + PR merge

---

## Tasarım Dili (Referans)

- Zemin: `#0A0814` – `#0E0524` – `#151126`
- Mor neon: `#6D2CE8`, `#8B4DFF`
- Magenta: `#C026D3`
- Cyan: `#00D9D9`
- Altın: `#FFD45A`
- Glassmorphism, glow, yuvarlak avatar, mor aktif nav

Mevcut UI yeniden tasarlanmaz; overlay'ler bu palete uyumlu native/Lottie fallback kullanır.
