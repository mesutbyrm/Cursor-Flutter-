# BACKEND PROMPT — Admin / Yönetim Merkezi uyumu (canlifal.com, `full-source`)

> Hedef repo: `mesutbyrm/canlifal` · dal: `full-source` · klasör: `nextjs_space/`
> Üreten: mobil Yönetim Merkezi / Kullanıcı Yönetimi / Yayın İstatistikleri yenilemesi (mobil 1.0.701+754)
> Kurallar: şema bozulmasın, mevcut web (NextAuth cookie) davranışı aynen çalışsın, JWT yapısı DEĞİŞMESİN, yeni güvenlik açığı oluşmasın. Önce kod oku, sonra uygula; tahmin etme.

Bu prompt'u backend ajanına olduğu gibi ver. Mobil taraf bu uçları hâlihazırda çağırıyor / çağıracak şekilde hazır; backend eksikleri yüzünden aşağıdaki özellikler mobilde ya çalışmıyor ya sınırlı çalışıyor.

---

## 1) [ÖNCELİK: YÜKSEK] Mobil JWT (Bearer) birçok admin ucunda kabul edilmiyor

**Sorun:** `middleware.ts` yalnızca sayfa rotalarını korur; API rotaları "kendi auth'unu yapar" (`middleware.ts` ~satır 97). Aşağıdaki **110** admin rotası yalnızca `getServerSession(authOptions)` (NextAuth çerezi) kullanıyor; `authenticateRequest` / `requirePermission` YOK. Mobil uygulama `Authorization: Bearer <JWT>` gönderdiği için bu uçlar mobilde **401 "Oturum açmanız gerekiyor"** döner.

En kritik örnekler (mobil Kullanıcı Yönetimi / komuta merkezi bunları çağırır):
- `GET/PATCH/DELETE /api/admin/users/{userId}` (satır 14, 101, 294: yalnızca `getServerSession`)
- `GET /api/admin/users/search`
- `POST /api/admin/users/withdrawal-limit`
- `GET /api/admin/audit-logs`, `GET /api/admin/moderation`, `GET /api/admin/visitor-stats`

**Yapılacak:** Her birinde mevcut yetki kontrolünü KORUYARAK çift auth ekle. Önerilen tek yardımcı (örn. `lib/admin-auth.ts`):

```ts
// Session cookie VEYA Bearer JWT → { userId, role } ; yoksa 401
export async function resolveStaff(req: NextRequest) {
  const session = await getServerSession(authOptions)
  if (session?.user) return { id: (session.user as any).id, role: (session.user as any).role }
  const m = await authenticateRequest(req)          // lib/mobile-auth.ts
  return m ? { id: m.id, role: m.role } : null
}
```
Sonra her rotada: `const staff = await resolveStaff(req); if (!staff) 401; if (!(await staffCan(staff.role, staff.id, '<mevcut izin>', [<mevcut roller>]))) 403`. Yetki anahtarlarını/rol listelerini DEĞİŞTİRME; yalnızca kimliğin geldiği yeri genişlet. (`/api/admin/users/route.ts` GET zaten bu kalıbı kullanıyor — örnek al.)

Etkilenen 110 rota:

- `/api/admin/activity-feed`
- `/api/admin/ad-networks`
- `/api/admin/announcement-sections`
- `/api/admin/audit-logs`
- `/api/admin/awards`
- `/api/admin/backup`
- `/api/admin/badges`
- `/api/admin/bana-ozel`
- `/api/admin/blog/[postId]`
- `/api/admin/blog/analytics`
- `/api/admin/blog/bulk-category`
- `/api/admin/blog/bulk-delete`
- `/api/admin/blog/bulk-generate`
- `/api/admin/blog/bulk-import`
- `/api/admin/blog/bulk-publish`
- `/api/admin/blog/categories`
- `/api/admin/blog/comments`
- `/api/admin/blog/generate`
- `/api/admin/blog/import`
- `/api/admin/blog`
- `/api/admin/blog/schedule-publish`
- `/api/admin/bots`
- `/api/admin/bots/simulate-fortune`
- `/api/admin/bots/simulate-master`
- `/api/admin/bots/simulate-social`
- `/api/admin/bots/simulate`
- `/api/admin/broadcast-images`
- `/api/admin/button-order`
- `/api/admin/cache`
- `/api/admin/cfc-settings`
- `/api/admin/chat-rooms`
- `/api/admin/contests`
- `/api/admin/credit-packages/[packageId]`
- `/api/admin/credit-packages`
- `/api/admin/credits`
- `/api/admin/currency-config`
- `/api/admin/currency-settings`
- `/api/admin/dreams/bulk-category`
- `/api/admin/dreams/bulk-delete`
- `/api/admin/dreams/bulk-import`
- `/api/admin/dreams/bulk-publish`
- `/api/admin/dreams/generate`
- `/api/admin/dreams`
- `/api/admin/feature-flags/[flagId]`
- `/api/admin/feature-flags`
- `/api/admin/finance`
- `/api/admin/fortune-request-types`
- `/api/admin/fortunes`
- `/api/admin/games/rooms`
- `/api/admin/games`
- `/api/admin/games/settings`
- `/api/admin/gift-collections`
- `/api/admin/gift-upload`
- `/api/admin/gifts/[giftId]`
- `/api/admin/gifts`
- `/api/admin/gifts/stats`
- `/api/admin/homepage-buttons`
- `/api/admin/homepage-fortune-cards`
- `/api/admin/ledger`
- `/api/admin/live-tellers/[tellerId]/approve`
- `/api/admin/live-tellers/[tellerId]/ban`
- `/api/admin/live-tellers/[tellerId]/bonus`
- `/api/admin/live-tellers/[tellerId]/freeze`
- `/api/admin/live-tellers/[tellerId]/permissions`
- `/api/admin/live-tellers/[tellerId]`
- `/api/admin/live-tellers/[tellerId]/warning`
- `/api/admin/live-tellers`
- `/api/admin/membership-badges`
- `/api/admin/memberships/purchases`
- `/api/admin/memberships`
- `/api/admin/moderation`
- `/api/admin/notifications`
- `/api/admin/online-fal/buttons`
- `/api/admin/online-fal/sections`
- `/api/admin/payment-methods`
- `/api/admin/pending-counts`
- `/api/admin/popups`
- `/api/admin/profile-frames/assign`
- `/api/admin/profile-frames`
- `/api/admin/referral-commission`
- `/api/admin/referral-commission/settings`
- `/api/admin/refunds`
- `/api/admin/remote-config/[configId]`
- `/api/admin/remote-config`
- `/api/admin/roles/[roleId]`
- `/api/admin/roles`
- `/api/admin/room-themes/backgrounds`
- `/api/admin/rooms`
- `/api/admin/seo-settings`
- `/api/admin/settings`
- `/api/admin/site-pages`
- `/api/admin/statistics`
- `/api/admin/teller-levels`
- `/api/admin/teller-performance`
- `/api/admin/teller-verification`
- `/api/admin/ticker-messages/[messageId]`
- `/api/admin/ticker-messages`
- `/api/admin/tiktok-categories`
- `/api/admin/tiktok-videos`
- `/api/admin/topup-bonus-tiers/[id]`
- `/api/admin/topup-bonus-tiers`
- `/api/admin/trend-videos`
- `/api/admin/trend-videos/youtube`
- `/api/admin/trends`
- `/api/admin/users/[userId]`
- `/api/admin/users/search`
- `/api/admin/users/withdrawal-limit`
- `/api/admin/video-streams`
- `/api/admin/visitor-stats`
- `/api/admin/withdrawals`

**Kabul kriteri:** (a) Bearer ile staff → 200; (b) Bearer ile normal kullanıcı → 403; (c) kimlik yok → 401; (d) web cookie akışı değişmeden çalışır. Birkaç rota için entegrasyon testi ekle (users/[userId], users/search, audit-logs).

---

## 2) [ÖNCELİK: YÜKSEK] Auth kontrolü tespit edilemeyen 30 admin rotası — doğrula

Aşağıdaki dosyalarda `getServerSession`, `authenticateRequest`, `requirePermission`, 401/403 veya rol kontrolü **bulunamadı** (bazıları `createCosmeticAdminHandlers` gibi bir yardımcı içinde koruyor olabilir — **hepsini tek tek doğrula**). Koruması yoksa admin yetkisi ekle (401/403):

- `/api/admin/ad-placements/[id]`
- `/api/admin/ad-placements`
- `/api/admin/ad-placements/stats`
- `/api/admin/animations/[id]`
- `/api/admin/animations/assignments`
- `/api/admin/animations/membership-defaults`
- `/api/admin/animations`
- `/api/admin/animations/stats`
- `/api/admin/avatar-accessories`
- `/api/admin/chat-bubbles`
- `/api/admin/emoji-packs`
- `/api/admin/entrance-effects`
- `/api/admin/integrations/apple`
- `/api/admin/integrations/google-play`
- `/api/admin/integrations/sms/[providerKey]`
- `/api/admin/integrations/sms/[providerKey]/test`
- `/api/admin/integrations/sms`
- `/api/admin/membership-features`
- `/api/admin/mic-frames`
- `/api/admin/name-effects`
- `/api/admin/room-themes`
- `/api/admin/site-animations/[id]`
- `/api/admin/site-animations/assign`
- `/api/admin/site-animations/bulk-assign`
- `/api/admin/site-animations/defaults`
- `/api/admin/site-animations/exit-defaults`
- `/api/admin/site-animations`
- `/api/admin/site-animations/stats`
- `/api/admin/site-animations/user/[userId]`
- `/api/admin/voice-room-backgrounds`

**Kabul kriteri:** Her biri için kimliksiz istek 401, yetkisiz kullanıcı 403 döner (otomatik test: tüm `app/api/admin/**/route.ts` dosyalarını tarayıp korumasız olanı başarısız eden bir CI testi ekle).

---

## 3) [ÖNCELİK: ORTA] Kullanıcı listesi: ban / susturma durumu ve «Banlı» filtresi

`GET /api/admin/users` (`app/api/admin/users/route.ts`) şu an:
- `select` içinde **`isBanned`, `bannedUntil`, `banReason`, `canChat`, `canBroadcast`, `canCreateRoom` yok** (şemada `User` modelinde var — `prisma/schema.prisma` ~satır 172-180). Mobil satırda «Banlı» rozeti ve filtre bu alanlara ihtiyaç duyuyor.
- `segment` yalnızca `active|passive|vip|new|spender`; **`banned` yok**.

**Yapılacak:**
1. `select`'e `isBanned, bannedUntil, banReason, canChat, canBroadcast, canCreateRoom` ekle (+ yanıta `isOnline` türet: `lastActiveAt >= now-5dk`).
2. `segment=banned` (`isBanned: true`) ve `segment=muted` (`canChat: false`) ekle; `segmentCounts`'a `banned`, `muted` sayıları ekle.
3. Mobil `Yayıncı` filtresi `adv=broadcasting` (şu an canlı yayında olanlar) kullanıyor; ayrıca `adv=broadcaster` (en az bir yayını olan / `canBroadcast` olan) desteği düşün ve ayrım belgele.

**Kabul kriteri:** `GET /api/admin/users?segment=banned` yalnız banlı kullanıcıları döner; yanıt kullanıcıları `isBanned/isOnline` alanlarını içerir; mevcut sorgular geriye dönük uyumlu.

---

## 4) [ÖNCELİK: ORTA] Admin canlı yayın istatistikleri — zaman serisi ucu

Mobil «Canlı Yayın İstatistikleri» ekranı (4 kart + son 7 gün grafiği) için sunucuda uygun uç yok:
- `GET /api/admin/statistics` yalnızca toplamları verir (`streams.total/active/totalGiftsValue/totalLikes`).
- `GET /api/admin/platform-analytics` bugüne ait sayılar verir.
- **Gün bazlı seri, toplam izleyici ve dönem hediye geliri yok.**

**Yeni uç (önerilen):** `GET /api/admin/live-stats?days=7` (staff izni: mevcut `moderation`/rapor izni; **Bearer + session** çift auth)

```json
{
  "activeStreams": 156,
  "totalViewers": 24800,
  "giftRevenue": 12450,          // dönem içi StreamGift.totalPrice toplamı
  "activeBroadcasters": 328,
  "series": [ { "date": "2026-10-01", "viewers": 1200, "giftRevenue": 800, "streams": 40 } ]
}
```
Kaynaklar: `VideoStream` (status `live`, viewer sayaçları/`ViewerSession` benzeri tablo — mevcut şemaya bak), `StreamGift`. Sorgu performanslı olsun (günlük `groupBy`, indeksli alanlar). `days` 1–30 ile sınırla.

**Kabul kriteri:** Staff 200 + yukarıdaki şema; yetkisiz 403; `days` sınırı; boş günler 0 ile doldurulur.

---

## 5) [ÖNCELİK: DÜŞÜK] Profil «Hikâyeler» sekmesi için kullanıcıya göre hikâye ucu

Mobil profilde «Hikâyeler» sekmesi şimdilik yalnızca **kendi** aktif hikâyelerini hikâye halkalarından (`/api/social/stories` halkaları) gösteriyor. Başka bir kullanıcının profilinde hikâyeleri listelemek için `GET /api/users/{id}/stories` (aktif, gizlilik kurallarına uygun, Bearer destekli) ekle; yanıt `SocialStoryItem` şemasıyla (`id, mediaUrl, type, caption, createdAt, durationMs`) uyumlu olsun.

---

## 6) Dağıtım kontrol listesi (önceki PR'lar)

- `mesutbyrm/canlifal` **PR #7** (falcı isteği SSE, beğeni yayını, hediye/PK paralel) `full-source`'a merge edildi — **üretime deploy edildi mi doğrula**. Deploy edilmeden mobildeki falcı isteği gecikmesi ve canlı yayın beğeni senkronu düzelmez.
- Şema değişikliği yok; `prisma db push` gerekmiyor (yukarıdaki maddelerde de şema değişmiyor, yalnız `select/where`).
- Bellek içi olay deposu (`lib/stream-events.ts`, `lib/room-events.ts`) tek süreç varsayar; çok örnekli dağıtımda SSE olayları örnekler arasında paylaşılmaz → Redis/pub-sub veya yapışkan oturum gerekir. Mevcut dağıtım topolojisini kontrol et ve belgele.

---

## Teslim
Tek PR (`full-source` tabanlı), `tsc` temiz (yeni hata yok), eklenen testler geçer, yukarıdaki kabul kriterleri PR açıklamasında tek tek işaretli. Mobil taraf bu uçlar hazır olunca ek değişiklik gerektirmez (liste/filtre/seri alanları yukarıdaki adlarla okunur).
