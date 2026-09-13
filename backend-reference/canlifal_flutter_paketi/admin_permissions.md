# admin_permissions.md — Admin, Moderatör ve Yetki Sistemi

> Kaynak: üretim kodu taraması (2026-09-12).

## 1. Roller

`User.role` alanı (kaynaktan doğrulanmış değerler):

| Rol | Açıklama |
|---|---|
| `user` | Standart kullanıcı |
| `fortune_teller` | Falcı |
| `agency` | Ajans yöneticisi |
| `moderator` | Moderatör |
| `finans` | Finans yetkilisi |
| `yonetici` | Yönetici |
| `admin` | Tam yetkili admin |

Üyelik seviyesi ayrı bir eksendir: `basic` · `gold` · `diamond` (+ `membershipExpiresAt`).

## 2. Guard fonksiyonları (gerçek kaynak)

| Guard | Dosya | Kullanım |
|---|---|---|
| `resolveUser()` | `lib/rbac.ts` | Hem mobil JWT hem web oturumunu çözer — **çift kimlik doğrulama deseninin çekirdeği** |
| `requireAuth()` | `lib/rbac.ts` | Oturum zorunlu |
| `requireAdmin()` | `lib/rbac.ts` | Admin/yönetici |
| `requireFullAdmin()` | `lib/rbac.ts` | Yalnız tam admin |
| `requireRole(role)` | `lib/rbac.ts` | Belirli rol |
| `requireOwnerOrAdmin()` | `lib/rbac.ts` | Kaynak sahibi veya admin |
| `isAdmin()` | `lib/cosmetics.ts` | Kozmetik yönetimi |
| `requireAnimationAdmin()` | `lib/animation-admin.ts` | Animasyon paneli |
| `requireAdAdmin()` | `lib/ad-placements.ts` | Reklam paneli |
| `getServerSession(authOptions)` | next-auth | Yalnız web panelinde |

> ⚠️ `resolveUser()` dönüşünde `username` / `name` **yoktur** — yalnız `id`, `role` vb. Kullanıcı adı gerekiyorsa ayrı sorgu gerekir.

## 3. Admin yüzeyi

- **366** endpoint admin korumalıdır (852 uçtan).
- Tamamı `/api/admin/**` altında veya yukarıdaki guard'lardan biriyle korunur.
- `middleware.ts` admin **sayfa** yollarında rol kontrolü yapar; **API rotaları middleware kimlik doğrulamasının dışındadır** — her rota kendi guard'ını çalıştırır.

Başlıca admin grupları: kullanıcı yönetimi, ödemeler, çekimler, hediyeler, liderlik tabloları, turnuvalar, canlı falcılar, destek, moderasyon, içerik/CMS, reklam, animasyon, kozmetik, ayarlar, raporlar.

## 4. Denetim kaydı (audit)

Kod tabanında **90+ `recordAudit()` çağrısı** vardır. Tüm kritik finansal ve moderasyon işlemleri (ödeme onay/red, manuel yükleme, çekim, ödül dağıtımı, yasaklama, rol değişikliği) denetim kaydına yazılır.

## 5. Kritik işlem onayı (§88)

`lib/critical-confirm.ts`:
```
CRITICAL_THRESHOLDS = { jeton: 1000, cfc: 5000, amountTl: 2000 }
```
Guard'lı rotalar: `/api/admin/users/[userId]/manage`, `/api/admin/payments`, `/api/admin/leaderboards`, `/api/admin/tournaments`.

Eşik aşıldığında **409**:
```json
{ "requiresConfirmation": true, "confirmationMessage": "...", "action": "jeton_adjust" }
```
İstemci aynı gövdeyi `"confirm": true` ile tekrar gönderir.

## 6. Moderasyon yüzeyleri

| Alan | Endpoint |
|---|---|
| Oda moderasyonu | `GET` · `POST /api/chat/rooms/[roomId]/moderation`, `DELETE .../messages` |
| Söz isteği engelleme | `.../speak-requests/[targetUserId]/block` / `reject` |
| Yayın moderatörleri | `/api/video-streams/[streamId]/moderators` |
| Yayın susturma / yasaklama | `/api/video-streams/[streamId]/mute`, `/ban` |
| Kullanıcı engelleme (kullanıcı düzeyi) | `POST /api/user/block`, `GET /api/user/blocked` |
| Şikâyet | `POST /api/user/report` (rate limitli) → `{ success, message, reportId }` |
| Platform falcı yasağı | `/api/admin/live-tellers/[tellerId]/ban` |
| Destek talepleri | `/api/admin/support` (ödeme itirazları `relatedPayment` ile gelir) |

## 7. Flutter için kritik notlar

1. Flutter'da **admin paneli gerekmez**; ama moderatör rolündeki kullanıcılar için oda/yayın moderasyon uçları kullanılabilir.
2. Yetki kararını **asla** istemcide vermeyin. UI'ı gizlemek için rol bilgisini kullanabilirsiniz; gerçek karar sunucunun `403` yanıtıdır.
3. `403` yanıtları bazı rotalarda `{ error }`, bazılarında `{ error, message }` veya `{ error, code }` biçimindedir — savunmacı ayrıştırma yapın.
4. 366 admin ucunun büyük kısmı **web panel odaklıdır**; Flutter'dan çağrılacak her admin ucu tek tek mobil JWT kabul edip etmediği yönünden doğrulanmalıdır.

## 8. Tam endpoint tablosu (admin korumalı uçlar)

> Toplam **359** uç (path+method), **175** rota dosyası. Kaynak: üretim kodu taraması, 2026-09-12 (BÖLÜM 22 dahil).

| METHOD | ENDPOINT | AUTH | ÖZELLİK | QUERY | BODY ALANLARI | KAYNAK DOSYA |
|---|---|---|---|---|---|---|
| `GET` | `/api/admin/activity-feed` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/activity-feed/route.ts` |
| `POST` | `/api/admin/activity-feed` | mobil JWT + web oturum | ADMIN | — | isEnabled, maxItems, specificUserIds, visibleToAdmin, visibleToBasic, visibleToDiamond, visibleToGold, visibleToGuests, visibleToModerator, visibleToPremium | `app/api/admin/activity-feed/route.ts` |
| `DELETE` | `/api/admin/ad-networks` | mobil JWT + web oturum | ADMIN | id | adCode, adUnitId, appId, id, isActive, name, provider, sortOrder | `app/api/admin/ad-networks/route.ts` |
| `GET` | `/api/admin/ad-networks` | mobil JWT + web oturum | ADMIN | id | — | `app/api/admin/ad-networks/route.ts` |
| `POST` | `/api/admin/ad-networks` | mobil JWT + web oturum | ADMIN | id | adCode, adUnitId, appId, id, isActive, name, provider, sortOrder | `app/api/admin/ad-networks/route.ts` |
| `GET` | `/api/admin/ad-placements` | public | ADMIN | — | — | `app/api/admin/ad-placements/route.ts` |
| `POST` | `/api/admin/ad-placements` | public | ADMIN | — | action, adNetworkId, customCode, description, frequencyCap, position, sortOrder | `app/api/admin/ad-placements/route.ts` |
| `DELETE` | `/api/admin/ad-placements/[id]` | public | ADMIN | — | adNetworkId, adType, customCode, description, frequencyCap, isActive, name, platform, position, resetStats, sortOrder, targeting | `app/api/admin/ad-placements/[id]/route.ts` |
| `GET` | `/api/admin/ad-placements/[id]` | public | ADMIN | — | — | `app/api/admin/ad-placements/[id]/route.ts` |
| `PATCH` | `/api/admin/ad-placements/[id]` | public | ADMIN | — | adNetworkId, adType, customCode, description, frequencyCap, isActive, name, platform, position, resetStats, sortOrder, targeting | `app/api/admin/ad-placements/[id]/route.ts` |
| `GET` | `/api/admin/ad-placements/stats` | public | ADMIN | — | — | `app/api/admin/ad-placements/stats/route.ts` |
| `DELETE` | `/api/admin/agencies` | public | ADMIN, AUDIT | — | action, agencyId, commissionRate, contactEmail, contactPhone, description, fromAgencyId, logoUrl, name, newOwnerId, ownerId, ownerName, role, toAgencyId, userId | `app/api/admin/agencies/route.ts` |
| `GET` | `/api/admin/agencies` | public | ADMIN, AUDIT | — | — | `app/api/admin/agencies/route.ts` |
| `PATCH` | `/api/admin/agencies` | public | ADMIN, AUDIT | — | action, agencyId, commissionRate, contactEmail, contactPhone, description, fromAgencyId, logoUrl, name, newOwnerId, ownerId, ownerName, role, toAgencyId, userId | `app/api/admin/agencies/route.ts` |
| `POST` | `/api/admin/agencies` | public | ADMIN, AUDIT | — | action, agencyId, commissionRate, contactEmail, contactPhone, description, fromAgencyId, logoUrl, name, newOwnerId, ownerId, ownerName, role, toAgencyId, userId | `app/api/admin/agencies/route.ts` |
| `GET` | `/api/admin/agencies/[agencyId]/commission` | public | ADMIN, AUDIT | — | — | `app/api/admin/agencies/[agencyId]/commission/route.ts` |
| `PUT` | `/api/admin/agencies/[agencyId]/commission` | public | ADMIN, AUDIT | — | baseCommissionRate, rules | `app/api/admin/agencies/[agencyId]/commission/route.ts` |
| `GET` | `/api/admin/agencies/[agencyId]/wallet` | public | ADMIN, IDEM, AUDIT, CONFIRM | limit, page, type | — | `app/api/admin/agencies/[agencyId]/wallet/route.ts` |
| `POST` | `/api/admin/agencies/[agencyId]/wallet` | public | ADMIN, IDEM, AUDIT, CONFIRM | limit, page, type | action, amount, confirm, idempotencyKey, jetonAmount, level, reason, tlAmount | `app/api/admin/agencies/[agencyId]/wallet/route.ts` |
| `GET` | `/api/admin/agency-applicant-config` | public | ADMIN, AUDIT | — | — | `app/api/admin/agency-applicant-config/route.ts` |
| `PUT` | `/api/admin/agency-applicant-config` | public | ADMIN, AUDIT | — | weights | `app/api/admin/agency-applicant-config/route.ts` |
| `GET` | `/api/admin/agency-finance` | public | ADMIN, AUDIT | — | — | `app/api/admin/agency-finance/route.ts` |
| `PUT` | `/api/admin/agency-finance` | public | ADMIN, AUDIT | — | bonus_rules, global_commission_rules, settings | `app/api/admin/agency-finance/route.ts` |
| `GET` | `/api/admin/animations` | public | ADMIN | category, limit, membership, offset, q, status | — | `app/api/admin/animations/route.ts` |
| `POST` | `/api/admin/animations` | public | ADMIN | category, limit, membership, offset, q, status | name, slug | `app/api/admin/animations/route.ts` |
| `DELETE` | `/api/admin/animations/[id]` | public | ADMIN | — | — | `app/api/admin/animations/[id]/route.ts` |
| `GET` | `/api/admin/animations/[id]` | public | ADMIN | — | — | `app/api/admin/animations/[id]/route.ts` |
| `PATCH` | `/api/admin/animations/[id]` | public | ADMIN | — | — | `app/api/admin/animations/[id]/route.ts` |
| `DELETE` | `/api/admin/animations/assignments` | public | ADMIN | animationId, category, id, onlyActive, userId | assignmentType, context, duration, endDate, isActive, note, priority, startDate | `app/api/admin/animations/assignments/route.ts` |
| `GET` | `/api/admin/animations/assignments` | public | ADMIN | animationId, category, id, onlyActive, userId | — | `app/api/admin/animations/assignments/route.ts` |
| `PATCH` | `/api/admin/animations/assignments` | public | ADMIN | animationId, category, id, onlyActive, userId | assignmentType, context, duration, endDate, isActive, note, priority, startDate | `app/api/admin/animations/assignments/route.ts` |
| `POST` | `/api/admin/animations/assignments` | public | ADMIN | animationId, category, id, onlyActive, userId | assignmentType, context, duration, endDate, isActive, note, priority, startDate | `app/api/admin/animations/assignments/route.ts` |
| `DELETE` | `/api/admin/animations/membership-defaults` | public | ADMIN | id | isActive | `app/api/admin/animations/membership-defaults/route.ts` |
| `GET` | `/api/admin/animations/membership-defaults` | public | ADMIN | id | — | `app/api/admin/animations/membership-defaults/route.ts` |
| `POST` | `/api/admin/animations/membership-defaults` | public | ADMIN | id | isActive | `app/api/admin/animations/membership-defaults/route.ts` |
| `GET` | `/api/admin/animations/stats` | public | ADMIN | — | — | `app/api/admin/animations/stats/route.ts` |
| `GET` | `/api/admin/announcement-sections` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/announcement-sections/route.ts` |
| `POST` | `/api/admin/announcement-sections` | mobil JWT + web oturum | ADMIN | — | categoryConfig, categoryKey, categorySettings, giftAnnouncementSettings | `app/api/admin/announcement-sections/route.ts` |
| `GET` | `/api/admin/audit-logs` | mobil JWT + web oturum | ADMIN | action, actorId, cursor, limit, targetType | — | `app/api/admin/audit-logs/route.ts` |
| `GET` | `/api/admin/avatar-accessories` | public | ADMIN | — | — | `app/api/admin/avatar-accessories/route.ts` |
| `DELETE` | `/api/admin/awards` | mobil JWT + web oturum | ADMIN | id | awardType, endDate, startDate, tellerId, title | `app/api/admin/awards/route.ts` |
| `GET` | `/api/admin/awards` | mobil JWT + web oturum | ADMIN | id | — | `app/api/admin/awards/route.ts` |
| `POST` | `/api/admin/awards` | mobil JWT + web oturum | ADMIN | id | awardType, endDate, startDate, tellerId, title | `app/api/admin/awards/route.ts` |
| `GET` | `/api/admin/backup` | mobil JWT + web oturum | ADMIN | table, type | — | `app/api/admin/backup/route.ts` |
| `DELETE` | `/api/admin/badges` | mobil JWT + web oturum | ADMIN | id | bgColor, color, description, icon, id, isActive, name, sortOrder, tier, userId | `app/api/admin/badges/route.ts` |
| `GET` | `/api/admin/badges` | mobil JWT + web oturum | ADMIN | id | — | `app/api/admin/badges/route.ts` |
| `POST` | `/api/admin/badges` | mobil JWT + web oturum | ADMIN | id | bgColor, color, description, icon, id, isActive, name, sortOrder, tier, userId | `app/api/admin/badges/route.ts` |
| `PUT` | `/api/admin/badges` | mobil JWT + web oturum | ADMIN | id | bgColor, color, description, icon, id, isActive, name, sortOrder, tier, userId | `app/api/admin/badges/route.ts` |
| `GET` | `/api/admin/bana-ozel` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/bana-ozel/route.ts` |
| `PATCH` | `/api/admin/bana-ozel` | mobil JWT + web oturum | ADMIN | — | category, icon, id, jetonCost, nameEn, nameTr, slug, sortOrder | `app/api/admin/bana-ozel/route.ts` |
| `POST` | `/api/admin/bana-ozel` | mobil JWT + web oturum | ADMIN | — | category, icon, id, jetonCost, nameEn, nameTr, slug, sortOrder | `app/api/admin/bana-ozel/route.ts` |
| `GET` | `/api/admin/blog` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/blog/route.ts` |
| `POST` | `/api/admin/blog` | mobil JWT + web oturum | ADMIN | — | authorName, category, contentEn, contentTr, coverImage, descEn, descTr, isAiGenerated, isEditorPick, isFeatured, isPremium, isPublished, isTrending, keywords, metaDescription, publishedAt, readTime, scheduledAt, slug, titleEn, titleTr, zodiacSign | `app/api/admin/blog/route.ts` |
| `DELETE` | `/api/admin/blog/[postId]` | mobil JWT + web oturum | ADMIN | — | authorName, category, contentEn, contentTr, coverImage, descEn, descTr, isAiGenerated, isEditorPick, isFeatured, isPremium, isPublished, isTrending, keywords, metaDescription, publishedAt, readTime, scheduledAt, slug, titleEn, titleTr, zodiacSign | `app/api/admin/blog/[postId]/route.ts` |
| `PATCH` | `/api/admin/blog/[postId]` | mobil JWT + web oturum | ADMIN | — | authorName, category, contentEn, contentTr, coverImage, descEn, descTr, isAiGenerated, isEditorPick, isFeatured, isPremium, isPublished, isTrending, keywords, metaDescription, publishedAt, readTime, scheduledAt, slug, titleEn, titleTr, zodiacSign | `app/api/admin/blog/[postId]/route.ts` |
| `PUT` | `/api/admin/blog/[postId]` | mobil JWT + web oturum | ADMIN | — | authorName, category, contentEn, contentTr, coverImage, descEn, descTr, isAiGenerated, isEditorPick, isFeatured, isPremium, isPublished, isTrending, keywords, metaDescription, publishedAt, readTime, scheduledAt, slug, titleEn, titleTr, zodiacSign | `app/api/admin/blog/[postId]/route.ts` |
| `GET` | `/api/admin/blog/analytics` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/blog/analytics/route.ts` |
| `PATCH` | `/api/admin/blog/bulk-category` | mobil JWT + web oturum | ADMIN | — | category, postIds | `app/api/admin/blog/bulk-category/route.ts` |
| `POST` | `/api/admin/blog/bulk-delete` | mobil JWT + web oturum | ADMIN | — | postIds | `app/api/admin/blog/bulk-delete/route.ts` |
| `POST` | `/api/admin/blog/bulk-generate` | mobil JWT + web oturum | ADMIN | — | autoPublish, category, topics, zodiacSign | `app/api/admin/blog/bulk-generate/route.ts` |
| `POST` | `/api/admin/blog/bulk-import` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/blog/bulk-import/route.ts` |
| `PATCH` | `/api/admin/blog/bulk-publish` | mobil JWT + web oturum | ADMIN | — | isPublished, postIds | `app/api/admin/blog/bulk-publish/route.ts` |
| `DELETE` | `/api/admin/blog/categories` | mobil JWT + web oturum | ADMIN | id | nameEn, nameTr, slug | `app/api/admin/blog/categories/route.ts` |
| `GET` | `/api/admin/blog/categories` | mobil JWT + web oturum | ADMIN | id | — | `app/api/admin/blog/categories/route.ts` |
| `POST` | `/api/admin/blog/categories` | mobil JWT + web oturum | ADMIN | id | nameEn, nameTr, slug | `app/api/admin/blog/categories/route.ts` |
| `GET` | `/api/admin/blog/comments` | mobil JWT + web oturum | ADMIN | limit, page, status | — | `app/api/admin/blog/comments/route.ts` |
| `PATCH` | `/api/admin/blog/comments` | mobil JWT + web oturum | ADMIN | limit, page, status | action, commentId | `app/api/admin/blog/comments/route.ts` |
| `POST` | `/api/admin/blog/generate` | mobil JWT + web oturum | ADMIN | — | keywords, mode, title | `app/api/admin/blog/generate/route.ts` |
| `POST` | `/api/admin/blog/import` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/blog/import/route.ts` |
| `POST` | `/api/admin/blog/schedule-publish` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/blog/schedule-publish/route.ts` |
| `GET` | `/api/admin/bots` | mobil JWT + web oturum | ADMIN | active, personality, search | — | `app/api/admin/bots/route.ts` |
| `PATCH` | `/api/admin/bots` | mobil JWT + web oturum | ADMIN | active, personality, search | action, activityLevel, botIds, isActive, personality | `app/api/admin/bots/route.ts` |
| `GET` | `/api/admin/bots/simulate` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/bots/simulate/route.ts` |
| `POST` | `/api/admin/bots/simulate` | mobil JWT + web oturum | ADMIN | — | action, roomId | `app/api/admin/bots/simulate/route.ts` |
| `GET` | `/api/admin/bots/simulate-fortune` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/bots/simulate-fortune/route.ts` |
| `POST` | `/api/admin/bots/simulate-fortune` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/bots/simulate-fortune/route.ts` |
| `GET` | `/api/admin/bots/simulate-master` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/bots/simulate-master/route.ts` |
| `POST` | `/api/admin/bots/simulate-master` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/bots/simulate-master/route.ts` |
| `GET` | `/api/admin/bots/simulate-social` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/bots/simulate-social/route.ts` |
| `POST` | `/api/admin/bots/simulate-social` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/bots/simulate-social/route.ts` |
| `DELETE` | `/api/admin/broadcast-images` | mobil JWT + web oturum | ADMIN | id | id, imageUrl, isActive, name, sortOrder | `app/api/admin/broadcast-images/route.ts` |
| `GET` | `/api/admin/broadcast-images` | mobil JWT + web oturum | ADMIN | id | — | `app/api/admin/broadcast-images/route.ts` |
| `PATCH` | `/api/admin/broadcast-images` | mobil JWT + web oturum | ADMIN | id | id, imageUrl, isActive, name, sortOrder | `app/api/admin/broadcast-images/route.ts` |
| `POST` | `/api/admin/broadcast-images` | mobil JWT + web oturum | ADMIN | id | id, imageUrl, isActive, name, sortOrder | `app/api/admin/broadcast-images/route.ts` |
| `GET` | `/api/admin/button-order` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/button-order/route.ts` |
| `POST` | `/api/admin/button-order` | mobil JWT + web oturum | ADMIN | — | order | `app/api/admin/button-order/route.ts` |
| `DELETE` | `/api/admin/cache` | mobil JWT + web oturum | ADMIN | key, prefix | — | `app/api/admin/cache/route.ts` |
| `GET` | `/api/admin/cache` | mobil JWT + web oturum | ADMIN | key, prefix | — | `app/api/admin/cache/route.ts` |
| `GET` | `/api/admin/cfc-arena` | public | ADMIN, AUDIT | — | — | `app/api/admin/cfc-arena/route.ts` |
| `POST` | `/api/admin/cfc-arena` | public | ADMIN, AUDIT | — | action, agencyId, badgeEmoji, bannerImage, captainId, color, commissionRate, contestId, description, displayName, endsAt, entryRequirements, isActive, isFeatured, isPublic, maxParticipants, minParticipants, name, participantId, registrationEndsAt, rewards, roomId, rules, scope, scoringMetrics, seasonId, startsAt, teamId, type, userId | `app/api/admin/cfc-arena/route.ts` |
| `GET` | `/api/admin/cfc-arena/[contestId]` | public | ADMIN | — | — | `app/api/admin/cfc-arena/[contestId]/route.ts` |
| `GET` | `/api/admin/cfc-payment-requests` | public | ADMIN, AUDIT | limit, page, status | — | `app/api/admin/cfc-payment-requests/route.ts` |
| `PATCH` | `/api/admin/cfc-payment-requests` | public | ADMIN, AUDIT | limit, page, status | action, requestId, reviewNote | `app/api/admin/cfc-payment-requests/route.ts` |
| `GET` | `/api/admin/cfc-settings` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/cfc-settings/route.ts` |
| `POST` | `/api/admin/cfc-settings` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/cfc-settings/route.ts` |
| `GET` | `/api/admin/chat-bubbles` | public | ADMIN | — | — | `app/api/admin/chat-bubbles/route.ts` |
| `DELETE` | `/api/admin/chat-rooms` | mobil JWT + web oturum | ADMIN | roomId | backgroundImage, descEn, descTr, description, giftCommissionPercent, icon, isActive, isMuted, name, nameEn, nameTr, ownerId, roomId, roomType | `app/api/admin/chat-rooms/route.ts` |
| `GET` | `/api/admin/chat-rooms` | mobil JWT + web oturum | ADMIN | roomId | — | `app/api/admin/chat-rooms/route.ts` |
| `POST` | `/api/admin/chat-rooms` | mobil JWT + web oturum | ADMIN | roomId | backgroundImage, descEn, descTr, description, giftCommissionPercent, icon, isActive, isMuted, name, nameEn, nameTr, ownerId, roomId, roomType | `app/api/admin/chat-rooms/route.ts` |
| `PUT` | `/api/admin/chat-rooms` | mobil JWT + web oturum | ADMIN | roomId | backgroundImage, descEn, descTr, description, giftCommissionPercent, icon, isActive, isMuted, name, nameEn, nameTr, ownerId, roomId, roomType | `app/api/admin/chat-rooms/route.ts` |
| `DELETE` | `/api/admin/contests` | mobil JWT + web oturum | ADMIN | id | description, dreamPrompt, endDate, id, isActive, startDate, title | `app/api/admin/contests/route.ts` |
| `GET` | `/api/admin/contests` | mobil JWT + web oturum | ADMIN | id | — | `app/api/admin/contests/route.ts` |
| `PATCH` | `/api/admin/contests` | mobil JWT + web oturum | ADMIN | id | description, dreamPrompt, endDate, id, isActive, startDate, title | `app/api/admin/contests/route.ts` |
| `POST` | `/api/admin/contests` | mobil JWT + web oturum | ADMIN | id | description, dreamPrompt, endDate, id, isActive, startDate, title | `app/api/admin/contests/route.ts` |
| `GET` | `/api/admin/credit-packages` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/credit-packages/route.ts` |
| `POST` | `/api/admin/credit-packages` | mobil JWT + web oturum | ADMIN | — | bonusCredits, credits, currency, isFeatured, name, nameEn, price, sortOrder | `app/api/admin/credit-packages/route.ts` |
| `DELETE` | `/api/admin/credit-packages/[packageId]` | mobil JWT + web oturum | ADMIN | — | bonusCredits, credits, currency, isActive, isFeatured, name, nameEn, price, sortOrder | `app/api/admin/credit-packages/[packageId]/route.ts` |
| `PATCH` | `/api/admin/credit-packages/[packageId]` | mobil JWT + web oturum | ADMIN | — | bonusCredits, credits, currency, isActive, isFeatured, name, nameEn, price, sortOrder | `app/api/admin/credit-packages/[packageId]/route.ts` |
| `POST` | `/api/admin/credits` | mobil JWT + web oturum | ADMIN, AUDIT, LEDGER | — | amount, currency, userId | `app/api/admin/credits/route.ts` |
| `GET` | `/api/admin/currency-config` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/currency-config/route.ts` |
| `POST` | `/api/admin/currency-config` | mobil JWT + web oturum | ADMIN | — | area, areaName, configs, cost, currencyType, id, isActive | `app/api/admin/currency-config/route.ts` |
| `PUT` | `/api/admin/currency-config` | mobil JWT + web oturum | ADMIN | — | area, areaName, configs, cost, currencyType, id, isActive | `app/api/admin/currency-config/route.ts` |
| `GET` | `/api/admin/currency-settings` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/currency-settings/route.ts` |
| `PATCH` | `/api/admin/currency-settings` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/currency-settings/route.ts` |
| `DELETE` | `/api/admin/dreams` | mobil JWT + web oturum | ADMIN | category, id, limit, page, publish, search | category, content, id, isPublished, keywords, metaDescription, summary, title | `app/api/admin/dreams/route.ts` |
| `GET` | `/api/admin/dreams` | mobil JWT + web oturum | ADMIN | category, id, limit, page, publish, search | — | `app/api/admin/dreams/route.ts` |
| `POST` | `/api/admin/dreams` | mobil JWT + web oturum | ADMIN | category, id, limit, page, publish, search | category, content, id, isPublished, keywords, metaDescription, summary, title | `app/api/admin/dreams/route.ts` |
| `PUT` | `/api/admin/dreams` | mobil JWT + web oturum | ADMIN | category, id, limit, page, publish, search | category, content, id, isPublished, keywords, metaDescription, summary, title | `app/api/admin/dreams/route.ts` |
| `PATCH` | `/api/admin/dreams/bulk-category` | mobil JWT + web oturum | ADMIN | — | category, dreamIds | `app/api/admin/dreams/bulk-category/route.ts` |
| `POST` | `/api/admin/dreams/bulk-delete` | mobil JWT + web oturum | ADMIN | — | dreamIds | `app/api/admin/dreams/bulk-delete/route.ts` |
| `POST` | `/api/admin/dreams/bulk-import` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/dreams/bulk-import/route.ts` |
| `PATCH` | `/api/admin/dreams/bulk-publish` | mobil JWT + web oturum | ADMIN | — | dreamIds, isPublished | `app/api/admin/dreams/bulk-publish/route.ts` |
| `POST` | `/api/admin/dreams/generate` | mobil JWT + web oturum | ADMIN | — | title | `app/api/admin/dreams/generate/route.ts` |
| `GET` | `/api/admin/effect-rules` | public | ADMIN, AUDIT | — | — | `app/api/admin/effect-rules/route.ts` |
| `POST` | `/api/admin/effect-rules` | public | ADMIN, AUDIT | — | conditionType, conditionValue, description, effectRefId, effectType, isActive, key, name, priority, threshold | `app/api/admin/effect-rules/route.ts` |
| `DELETE` | `/api/admin/effect-rules/[ruleId]` | public | ADMIN, AUDIT | — | conditionType, conditionValue, description, effectRefId, effectType, isActive, name, priority, threshold | `app/api/admin/effect-rules/[ruleId]/route.ts` |
| `PATCH` | `/api/admin/effect-rules/[ruleId]` | public | ADMIN, AUDIT | — | conditionType, conditionValue, description, effectRefId, effectType, isActive, name, priority, threshold | `app/api/admin/effect-rules/[ruleId]/route.ts` |
| `GET` | `/api/admin/emoji-packs` | public | ADMIN | — | — | `app/api/admin/emoji-packs/route.ts` |
| `GET` | `/api/admin/entrance-effects` | public | ADMIN | — | — | `app/api/admin/entrance-effects/route.ts` |
| `GET` | `/api/admin/feature-flags` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/feature-flags/route.ts` |
| `POST` | `/api/admin/feature-flags` | mobil JWT + web oturum | ADMIN | — | description, enabled, key, metadata, percentage, platform | `app/api/admin/feature-flags/route.ts` |
| `DELETE` | `/api/admin/feature-flags/[flagId]` | mobil JWT + web oturum | ADMIN, AUDIT | — | description, enabled, metadata, percentage, platform | `app/api/admin/feature-flags/[flagId]/route.ts` |
| `PATCH` | `/api/admin/feature-flags/[flagId]` | mobil JWT + web oturum | ADMIN, AUDIT | — | description, enabled, metadata, percentage, platform | `app/api/admin/feature-flags/[flagId]/route.ts` |
| `GET` | `/api/admin/finance` | mobil JWT + web oturum | ADMIN | from, page, period, section, to, userId | — | `app/api/admin/finance/route.ts` |
| `POST` | `/api/admin/finance` | mobil JWT + web oturum | ADMIN | from, page, period, section, to, userId | action, amount, currency, key, reason, userId, value | `app/api/admin/finance/route.ts` |
| `DELETE` | `/api/admin/fortune-request-types` | mobil JWT + web oturum | ADMIN | id | description, icon, id, isActive, jetonCost, name, nameEn, sortOrder | `app/api/admin/fortune-request-types/route.ts` |
| `GET` | `/api/admin/fortune-request-types` | mobil JWT + web oturum | ADMIN | id | — | `app/api/admin/fortune-request-types/route.ts` |
| `PATCH` | `/api/admin/fortune-request-types` | mobil JWT + web oturum | ADMIN | id | description, icon, id, isActive, jetonCost, name, nameEn, sortOrder | `app/api/admin/fortune-request-types/route.ts` |
| `POST` | `/api/admin/fortune-request-types` | mobil JWT + web oturum | ADMIN | id | description, icon, id, isActive, jetonCost, name, nameEn, sortOrder | `app/api/admin/fortune-request-types/route.ts` |
| `GET` | `/api/admin/fortunes` | mobil JWT + web oturum | ADMIN | type, userId | — | `app/api/admin/fortunes/route.ts` |
| `DELETE` | `/api/admin/games` | mobil JWT + web oturum | ADMIN | — | config, description, entryFee, icon, id, isActive, maxReward, minReward, slug, sortOrder, title | `app/api/admin/games/route.ts` |
| `GET` | `/api/admin/games` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/games/route.ts` |
| `POST` | `/api/admin/games` | mobil JWT + web oturum | ADMIN | — | config, description, entryFee, icon, id, isActive, maxReward, minReward, slug, sortOrder, title | `app/api/admin/games/route.ts` |
| `PUT` | `/api/admin/games` | mobil JWT + web oturum | ADMIN | — | config, description, entryFee, icon, id, isActive, maxReward, minReward, slug, sortOrder, title | `app/api/admin/games/route.ts` |
| `DELETE` | `/api/admin/games/rooms` | mobil JWT + web oturum | ADMIN | gameType, limit, page, status | roomId | `app/api/admin/games/rooms/route.ts` |
| `GET` | `/api/admin/games/rooms` | mobil JWT + web oturum | ADMIN | gameType, limit, page, status | — | `app/api/admin/games/rooms/route.ts` |
| `GET` | `/api/admin/games/settings` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/games/settings/route.ts` |
| `PUT` | `/api/admin/games/settings` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/games/settings/route.ts` |
| `GET` | `/api/admin/gift-collections` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/gift-collections/route.ts` |
| `PATCH` | `/api/admin/gift-collections` | mobil JWT + web oturum | ADMIN | — | description, iconCloudPath, iconEmoji, iconUrl, id, isActive, name, nameEn, slug, sortOrder | `app/api/admin/gift-collections/route.ts` |
| `POST` | `/api/admin/gift-collections` | mobil JWT + web oturum | ADMIN | — | description, iconCloudPath, iconEmoji, iconUrl, id, isActive, name, nameEn, slug, sortOrder | `app/api/admin/gift-collections/route.ts` |
| `POST` | `/api/admin/gift-upload` | mobil JWT + web oturum | ADMIN | — | contentType, fileName, purpose | `app/api/admin/gift-upload/route.ts` |
| `GET` | `/api/admin/gifts` | mobil JWT + web oturum | ADMIN, AUDIT | category, collectionId, displayType, isActive, limit, maxPrice, minPrice, page, search, sortBy, sortDir | — | `app/api/admin/gifts/route.ts` |
| `POST` | `/api/admin/gifts` | mobil JWT + web oturum | ADMIN, AUDIT | category, collectionId, displayType, isActive, limit, maxPrice, minPrice, page, search, sortBy, sortDir | animEndPoint, animStartPoint, animation, animationDurationMs, animationType, assetDurationMs, assetHeight, assetMimeType, assetType, assetUrl, assetWidth, campaignEnd, campaignStart, category, cloudStoragePath, collectionId, comboEnabled, comboWindowMs, dailySendLimit, description, displayArea, displayDurationMs, displayType, effectColor, eventOnly, hasColorChange, hasVibration, icon, iconImageCloudPath, iconImageUrl, isActive, isFeatured, isFullscreen, isHidden, isLucky, isNew, isPopular, isPremium, isReusable, isSeasonal, isSpecialEvent, liveOnly, musicCloudPath, musicUrl, name, nameEn, newUserOnly, particleEffect, pkOnly, price, priority, repeatCount, requiresVip, screenPosition, seasonEnd, seasonStart, seatEffect, seatEffectEnabled, sortOrder, soundCloudPath, soundEffectEnabled, soundUrl, startDelayMs, thumbnailCloudPath, thumbnailUrl, tier, timedCampaign, visibleAsFullscreen, visibleAsMini, visibleInFortune, visibleInLiveStream, visibleInMessaging, visibleInNotification, visibleInPK, visibleInProfile, visibleInStories, visibleInTrend, visibleInVoiceRoom, voiceOnly, volume | `app/api/admin/gifts/route.ts` |
| `DELETE` | `/api/admin/gifts/[giftId]` | mobil JWT + web oturum | ADMIN, AUDIT | — | animationType, assetMimeType, assetType, assetUrl, cloudStoragePath, collectionId, iconImageCloudPath, iconImageUrl, musicCloudPath, musicUrl, soundCloudPath, soundUrl, thumbnailCloudPath, thumbnailUrl | `app/api/admin/gifts/[giftId]/route.ts` |
| `GET` | `/api/admin/gifts/[giftId]` | mobil JWT + web oturum | ADMIN, AUDIT | — | — | `app/api/admin/gifts/[giftId]/route.ts` |
| `PATCH` | `/api/admin/gifts/[giftId]` | mobil JWT + web oturum | ADMIN, AUDIT | — | animationType, assetMimeType, assetType, assetUrl, cloudStoragePath, collectionId, iconImageCloudPath, iconImageUrl, musicCloudPath, musicUrl, soundCloudPath, soundUrl, thumbnailCloudPath, thumbnailUrl | `app/api/admin/gifts/[giftId]/route.ts` |
| `GET` | `/api/admin/gifts/stats` | mobil JWT + web oturum | ADMIN | giftId | — | `app/api/admin/gifts/stats/route.ts` |
| `GET` | `/api/admin/global-search` | public | ADMIN | — | — | `app/api/admin/global-search/route.ts` |
| `DELETE` | `/api/admin/homepage-buttons` | mobil JWT + web oturum | ADMIN | id | href, icon, id, isVisible, label, reorder, sortOrder, specialBehavior | `app/api/admin/homepage-buttons/route.ts` |
| `GET` | `/api/admin/homepage-buttons` | mobil JWT + web oturum | ADMIN | id | — | `app/api/admin/homepage-buttons/route.ts` |
| `PATCH` | `/api/admin/homepage-buttons` | mobil JWT + web oturum | ADMIN | id | href, icon, id, isVisible, label, reorder, sortOrder, specialBehavior | `app/api/admin/homepage-buttons/route.ts` |
| `POST` | `/api/admin/homepage-buttons` | mobil JWT + web oturum | ADMIN | id | href, icon, id, isVisible, label, reorder, sortOrder, specialBehavior | `app/api/admin/homepage-buttons/route.ts` |
| `DELETE` | `/api/admin/homepage-fortune-cards` | mobil JWT + web oturum | ADMIN | id | href, icon, id, image, isActive, key, name, settings, sortOrder, value | `app/api/admin/homepage-fortune-cards/route.ts` |
| `GET` | `/api/admin/homepage-fortune-cards` | mobil JWT + web oturum | ADMIN | id | — | `app/api/admin/homepage-fortune-cards/route.ts` |
| `PATCH` | `/api/admin/homepage-fortune-cards` | mobil JWT + web oturum | ADMIN | id | href, icon, id, image, isActive, key, name, settings, sortOrder, value | `app/api/admin/homepage-fortune-cards/route.ts` |
| `POST` | `/api/admin/homepage-fortune-cards` | mobil JWT + web oturum | ADMIN | id | href, icon, id, image, isActive, key, name, settings, sortOrder, value | `app/api/admin/homepage-fortune-cards/route.ts` |
| `PUT` | `/api/admin/homepage-fortune-cards` | mobil JWT + web oturum | ADMIN | id | href, icon, id, image, isActive, key, name, settings, sortOrder, value | `app/api/admin/homepage-fortune-cards/route.ts` |
| `DELETE` | `/api/admin/integrations/apple` | public | ADMIN, RL, AUDIT | confirm | — | `app/api/admin/integrations/apple/route.ts` |
| `GET` | `/api/admin/integrations/apple` | public | ADMIN, RL, AUDIT | confirm | — | `app/api/admin/integrations/apple/route.ts` |
| `PUT` | `/api/admin/integrations/apple` | public | ADMIN, RL, AUDIT | confirm | — | `app/api/admin/integrations/apple/route.ts` |
| `DELETE` | `/api/admin/integrations/google-play` | public | ADMIN, RL, AUDIT | confirm, field | — | `app/api/admin/integrations/google-play/route.ts` |
| `GET` | `/api/admin/integrations/google-play` | public | ADMIN, RL, AUDIT | confirm, field | — | `app/api/admin/integrations/google-play/route.ts` |
| `PUT` | `/api/admin/integrations/google-play` | public | ADMIN, RL, AUDIT | confirm, field | — | `app/api/admin/integrations/google-play/route.ts` |
| `GET` | `/api/admin/integrations/sms` | public | ADMIN, RL, AUDIT | — | — | `app/api/admin/integrations/sms/route.ts` |
| `PATCH` | `/api/admin/integrations/sms` | public | ADMIN, RL, AUDIT | — | — | `app/api/admin/integrations/sms/route.ts` |
| `DELETE` | `/api/admin/integrations/sms/[providerKey]` | public | ADMIN, RL, AUDIT | confirm, field | enabled, fields, priority | `app/api/admin/integrations/sms/[providerKey]/route.ts` |
| `PATCH` | `/api/admin/integrations/sms/[providerKey]` | public | ADMIN, RL, AUDIT | confirm, field | enabled, fields, priority | `app/api/admin/integrations/sms/[providerKey]/route.ts` |
| `PUT` | `/api/admin/integrations/sms/[providerKey]` | public | ADMIN, RL, AUDIT | confirm, field | enabled, fields, priority | `app/api/admin/integrations/sms/[providerKey]/route.ts` |
| `POST` | `/api/admin/integrations/sms/[providerKey]/test` | public | ADMIN, RL, AUDIT | — | — | `app/api/admin/integrations/sms/[providerKey]/test/route.ts` |
| `GET` | `/api/admin/leaderboards` | mobil JWT + web oturum | ADMIN, AUDIT, CONFIRM | limit, page, periodId, periodType, scope, status, view | — | `app/api/admin/leaderboards/route.ts` |
| `POST` | `/api/admin/leaderboards` | mobil JWT + web oturum | ADMIN, AUDIT, CONFIRM | limit, page, periodId, periodType, scope, status, view | action, configId, confirm, isEnabled, periodId, periodType, rewardConfig, scope, scoringRules, topN | `app/api/admin/leaderboards/route.ts` |
| `GET` | `/api/admin/ledger` | mobil JWT + web oturum | ADMIN, LEDGER | accountId, category, cursor, limit, transactionId | — | `app/api/admin/ledger/route.ts` |
| `GET` | `/api/admin/live-tellers` | mobil JWT + web oturum | ADMIN | banned, frozen, status | — | `app/api/admin/live-tellers/route.ts` |
| `POST` | `/api/admin/live-tellers` | mobil JWT + web oturum | ADMIN | banned, frozen, status | bio, displayName, isVerified, pricePerSession, specialties, userId | `app/api/admin/live-tellers/route.ts` |
| `DELETE` | `/api/admin/live-tellers/[tellerId]` | mobil JWT + web oturum | ADMIN | — | bio, displayName, isActive, isVerified, pricePerSession, specialties | `app/api/admin/live-tellers/[tellerId]/route.ts` |
| `GET` | `/api/admin/live-tellers/[tellerId]` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/live-tellers/[tellerId]/route.ts` |
| `PUT` | `/api/admin/live-tellers/[tellerId]` | mobil JWT + web oturum | ADMIN | — | bio, displayName, isActive, isVerified, pricePerSession, specialties | `app/api/admin/live-tellers/[tellerId]/route.ts` |
| `POST` | `/api/admin/live-tellers/[tellerId]/approve` | mobil JWT + web oturum | ADMIN, AUDIT | — | action, note | `app/api/admin/live-tellers/[tellerId]/approve/route.ts` |
| `POST` | `/api/admin/live-tellers/[tellerId]/ban` | mobil JWT + web oturum | ADMIN, AUDIT | — | action, reason | `app/api/admin/live-tellers/[tellerId]/ban/route.ts` |
| `POST` | `/api/admin/live-tellers/[tellerId]/bonus` | mobil JWT + web oturum | ADMIN, AUDIT | — | amount, reason | `app/api/admin/live-tellers/[tellerId]/bonus/route.ts` |
| `POST` | `/api/admin/live-tellers/[tellerId]/freeze` | mobil JWT + web oturum | ADMIN, AUDIT | — | action, reason | `app/api/admin/live-tellers/[tellerId]/freeze/route.ts` |
| `PUT` | `/api/admin/live-tellers/[tellerId]/permissions` | mobil JWT + web oturum | ADMIN, AUDIT | — | adminNotes, canChat, canEditProfile, canGoOnline, canSetPrice, canStartSession, canViewEarnings, canWithdraw, commissionRate, maxSessionsPerDay | `app/api/admin/live-tellers/[tellerId]/permissions/route.ts` |
| `DELETE` | `/api/admin/live-tellers/[tellerId]/warning` | mobil JWT + web oturum | ADMIN, AUDIT | warningId | reason | `app/api/admin/live-tellers/[tellerId]/warning/route.ts` |
| `POST` | `/api/admin/live-tellers/[tellerId]/warning` | mobil JWT + web oturum | ADMIN, AUDIT | warningId | reason | `app/api/admin/live-tellers/[tellerId]/warning/route.ts` |
| `DELETE` | `/api/admin/lucky-gifts/tiers` | mobil JWT + web oturum | ADMIN | id | color, icon, id, isActive, isJackpot, multiplier, name, nameEn, sortOrder, weight | `app/api/admin/lucky-gifts/tiers/route.ts` |
| `GET` | `/api/admin/lucky-gifts/tiers` | mobil JWT + web oturum | ADMIN | id | — | `app/api/admin/lucky-gifts/tiers/route.ts` |
| `PATCH` | `/api/admin/lucky-gifts/tiers` | mobil JWT + web oturum | ADMIN | id | color, icon, id, isActive, isJackpot, multiplier, name, nameEn, sortOrder, weight | `app/api/admin/lucky-gifts/tiers/route.ts` |
| `POST` | `/api/admin/lucky-gifts/tiers` | mobil JWT + web oturum | ADMIN | id | color, icon, id, isActive, isJackpot, multiplier, name, nameEn, sortOrder, weight | `app/api/admin/lucky-gifts/tiers/route.ts` |
| `DELETE` | `/api/admin/membership-badges` | mobil JWT + web oturum | ADMIN | id | id, imageUrl, isActive, name, sortOrder, tier | `app/api/admin/membership-badges/route.ts` |
| `GET` | `/api/admin/membership-badges` | mobil JWT + web oturum | ADMIN | id | — | `app/api/admin/membership-badges/route.ts` |
| `PATCH` | `/api/admin/membership-badges` | mobil JWT + web oturum | ADMIN | id | id, imageUrl, isActive, name, sortOrder, tier | `app/api/admin/membership-badges/route.ts` |
| `POST` | `/api/admin/membership-badges` | mobil JWT + web oturum | ADMIN | id | id, imageUrl, isActive, name, sortOrder, tier | `app/api/admin/membership-badges/route.ts` |
| `DELETE` | `/api/admin/membership-events` | public | ADMIN, AUDIT | confirm, id | allowedTiers, bannerUrl, ctaUrl, description, endsAt, isActive, minTierKey, priority, startsAt, title | `app/api/admin/membership-events/route.ts` |
| `GET` | `/api/admin/membership-events` | public | ADMIN, AUDIT | confirm, id | — | `app/api/admin/membership-events/route.ts` |
| `POST` | `/api/admin/membership-events` | public | ADMIN, AUDIT | confirm, id | allowedTiers, bannerUrl, ctaUrl, description, endsAt, isActive, minTierKey, priority, startsAt, title | `app/api/admin/membership-events/route.ts` |
| `PUT` | `/api/admin/membership-events` | public | ADMIN, AUDIT | confirm, id | allowedTiers, bannerUrl, ctaUrl, description, endsAt, isActive, minTierKey, priority, startsAt, title | `app/api/admin/membership-events/route.ts` |
| `DELETE` | `/api/admin/membership-features` | public | ADMIN, RL, AUDIT | confirm, featureKey, tierKey | cells, description, feature, sortOrder, unit, valueType | `app/api/admin/membership-features/route.ts` |
| `GET` | `/api/admin/membership-features` | public | ADMIN, RL, AUDIT | confirm, featureKey, tierKey | — | `app/api/admin/membership-features/route.ts` |
| `POST` | `/api/admin/membership-features` | public | ADMIN, RL, AUDIT | confirm, featureKey, tierKey | cells, description, feature, sortOrder, unit, valueType | `app/api/admin/membership-features/route.ts` |
| `PUT` | `/api/admin/membership-features` | public | ADMIN, RL, AUDIT | confirm, featureKey, tierKey | cells, description, feature, sortOrder, unit, valueType | `app/api/admin/membership-features/route.ts` |
| `DELETE` | `/api/admin/membership-grants` | public | ADMIN, RL, AUDIT | confirm, limit, source, status, tierKey, userId | durationDays, giverId, note, source, transactionId | `app/api/admin/membership-grants/route.ts` |
| `GET` | `/api/admin/membership-grants` | public | ADMIN, RL, AUDIT | confirm, limit, source, status, tierKey, userId | — | `app/api/admin/membership-grants/route.ts` |
| `POST` | `/api/admin/membership-grants` | public | ADMIN, RL, AUDIT | confirm, limit, source, status, tierKey, userId | durationDays, giverId, note, source, transactionId | `app/api/admin/membership-grants/route.ts` |
| `GET` | `/api/admin/membership-reports` | public | ADMIN | — | — | `app/api/admin/membership-reports/route.ts` |
| `DELETE` | `/api/admin/membership-tiers` | public | ADMIN, RL, AUDIT | confirm, key | badgeUrl, color, description, discoveryWeight, frameUrl, gradient, icon, isActive, name, nameEn, rank, sortOrder | `app/api/admin/membership-tiers/route.ts` |
| `GET` | `/api/admin/membership-tiers` | public | ADMIN, RL, AUDIT | confirm, key | — | `app/api/admin/membership-tiers/route.ts` |
| `POST` | `/api/admin/membership-tiers` | public | ADMIN, RL, AUDIT | confirm, key | badgeUrl, color, description, discoveryWeight, frameUrl, gradient, icon, isActive, name, nameEn, rank, sortOrder | `app/api/admin/membership-tiers/route.ts` |
| `PUT` | `/api/admin/membership-tiers` | public | ADMIN, RL, AUDIT | confirm, key | badgeUrl, color, description, discoveryWeight, frameUrl, gradient, icon, isActive, name, nameEn, rank, sortOrder | `app/api/admin/membership-tiers/route.ts` |
| `DELETE` | `/api/admin/memberships` | mobil JWT + web oturum | ADMIN | id | bonusJetons, currency, description, descriptionEn, discountPercent, durationDays, exclusiveBadge, features, id, isActive, isFeatured, name, nameEn, price, priceType, prioritySupport, sortOrder, tier | `app/api/admin/memberships/route.ts` |
| `GET` | `/api/admin/memberships` | mobil JWT + web oturum | ADMIN | id | — | `app/api/admin/memberships/route.ts` |
| `POST` | `/api/admin/memberships` | mobil JWT + web oturum | ADMIN | id | bonusJetons, currency, description, descriptionEn, discountPercent, durationDays, exclusiveBadge, features, id, isActive, isFeatured, name, nameEn, price, priceType, prioritySupport, sortOrder, tier | `app/api/admin/memberships/route.ts` |
| `PUT` | `/api/admin/memberships` | mobil JWT + web oturum | ADMIN | id | bonusJetons, currency, description, descriptionEn, discountPercent, durationDays, exclusiveBadge, features, id, isActive, isFeatured, name, nameEn, price, priceType, prioritySupport, sortOrder, tier | `app/api/admin/memberships/route.ts` |
| `GET` | `/api/admin/memberships/purchases` | mobil JWT + web oturum | ADMIN | limit, status, userId | — | `app/api/admin/memberships/purchases/route.ts` |
| `PATCH` | `/api/admin/memberships/purchases` | mobil JWT + web oturum | ADMIN | limit, status, userId | action, customTier, durationDays, extendDays, freeGrant, planId, purchaseId, userId | `app/api/admin/memberships/purchases/route.ts` |
| `POST` | `/api/admin/memberships/purchases` | mobil JWT + web oturum | ADMIN | limit, status, userId | action, customTier, durationDays, extendDays, freeGrant, planId, purchaseId, userId | `app/api/admin/memberships/purchases/route.ts` |
| `GET` | `/api/admin/mic-frames` | public | ADMIN | — | — | `app/api/admin/mic-frames/route.ts` |
| `GET` | `/api/admin/moderation` | mobil JWT + web oturum | ADMIN, AUDIT | — | — | `app/api/admin/moderation/route.ts` |
| `POST` | `/api/admin/moderation` | mobil JWT + web oturum | ADMIN, AUDIT | — | action, reason, targetId | `app/api/admin/moderation/route.ts` |
| `GET` | `/api/admin/name-effects` | public | ADMIN | — | — | `app/api/admin/name-effects/route.ts` |
| `DELETE` | `/api/admin/notifications` | mobil JWT + web oturum | ADMIN | action, id, limit, page | imageUrl, message, scheduledAt, targetType, targetValue, title, url | `app/api/admin/notifications/route.ts` |
| `GET` | `/api/admin/notifications` | mobil JWT + web oturum | ADMIN | action, id, limit, page | — | `app/api/admin/notifications/route.ts` |
| `POST` | `/api/admin/notifications` | mobil JWT + web oturum | ADMIN | action, id, limit, page | imageUrl, message, scheduledAt, targetType, targetValue, title, url | `app/api/admin/notifications/route.ts` |
| `DELETE` | `/api/admin/online-fal/buttons` | mobil JWT + web oturum | ADMIN | id | bgColor, borderColor, href, icon, id, isVisible, label, sortOrder, textColor | `app/api/admin/online-fal/buttons/route.ts` |
| `GET` | `/api/admin/online-fal/buttons` | mobil JWT + web oturum | ADMIN | id | — | `app/api/admin/online-fal/buttons/route.ts` |
| `PATCH` | `/api/admin/online-fal/buttons` | mobil JWT + web oturum | ADMIN | id | bgColor, borderColor, href, icon, id, isVisible, label, sortOrder, textColor | `app/api/admin/online-fal/buttons/route.ts` |
| `POST` | `/api/admin/online-fal/buttons` | mobil JWT + web oturum | ADMIN | id | bgColor, borderColor, href, icon, id, isVisible, label, sortOrder, textColor | `app/api/admin/online-fal/buttons/route.ts` |
| `GET` | `/api/admin/online-fal/sections` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/online-fal/sections/route.ts` |
| `PATCH` | `/api/admin/online-fal/sections` | mobil JWT + web oturum | ADMIN | — | icon, id, isVisible, order, sortOrder, title | `app/api/admin/online-fal/sections/route.ts` |
| `POST` | `/api/admin/online-fal/sections` | mobil JWT + web oturum | ADMIN | — | icon, id, isVisible, order, sortOrder, title | `app/api/admin/online-fal/sections/route.ts` |
| `GET` | `/api/admin/payment-methods` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/payment-methods/route.ts` |
| `POST` | `/api/admin/payment-methods` | mobil JWT + web oturum | ADMIN | — | config, description, descriptionEn, isActive, name, nameEn, sortOrder, type | `app/api/admin/payment-methods/route.ts` |
| `GET` | `/api/admin/payments` | public | ADMIN, IDEM, AUDIT, LEDGER, CONFIRM | id, limit, page, productType, sortBy, sortDir, status, userId, view | — | `app/api/admin/payments/route.ts` |
| `POST` | `/api/admin/payments` | public | ADMIN, IDEM, AUDIT, LEDGER, CONFIRM | id, limit, page, productType, sortBy, sortDir, status, userId, view | action, adminNote, amount, confirm, correctedAmount, correctionReason, loadAmount, notificationId, productType, reason, userId | `app/api/admin/payments/route.ts` |
| `GET` | `/api/admin/pending-counts` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/pending-counts/route.ts` |
| `GET` | `/api/admin/platform-analytics` | public | ADMIN | — | — | `app/api/admin/platform-analytics/route.ts` |
| `DELETE` | `/api/admin/popups` | mobil JWT + web oturum | ADMIN | id | action, buttons, id, isActive, maxShowCount, message, popupType, priority, showDelaySeconds, showOnRefresh, showTo, title | `app/api/admin/popups/route.ts` |
| `GET` | `/api/admin/popups` | mobil JWT + web oturum | ADMIN | id | — | `app/api/admin/popups/route.ts` |
| `POST` | `/api/admin/popups` | mobil JWT + web oturum | ADMIN | id | action, buttons, id, isActive, maxShowCount, message, popupType, priority, showDelaySeconds, showOnRefresh, showTo, title | `app/api/admin/popups/route.ts` |
| `PUT` | `/api/admin/popups` | mobil JWT + web oturum | ADMIN | id | action, buttons, id, isActive, maxShowCount, message, popupType, priority, showDelaySeconds, showOnRefresh, showTo, title | `app/api/admin/popups/route.ts` |
| `GET` | `/api/admin/premium-entrance` | public | ADMIN, AUDIT | enabled, limit, page, search | — | `app/api/admin/premium-entrance/route.ts` |
| `POST` | `/api/admin/premium-entrance` | public | ADMIN, AUDIT | enabled, limit, page, search | action, animationType, durationMs, effectId, enabled, requireGold, userId | `app/api/admin/premium-entrance/route.ts` |
| `DELETE` | `/api/admin/profile-frames` | mobil JWT + web oturum | ADMIN | id | id, imageUrl, isActive, name, sortOrder, tier | `app/api/admin/profile-frames/route.ts` |
| `GET` | `/api/admin/profile-frames` | mobil JWT + web oturum | ADMIN | id | — | `app/api/admin/profile-frames/route.ts` |
| `POST` | `/api/admin/profile-frames` | mobil JWT + web oturum | ADMIN | id | id, imageUrl, isActive, name, sortOrder, tier | `app/api/admin/profile-frames/route.ts` |
| `POST` | `/api/admin/profile-frames/assign` | mobil JWT + web oturum | ADMIN | — | frameId, userId | `app/api/admin/profile-frames/assign/route.ts` |
| `GET` | `/api/admin/referral-commission` | mobil JWT + web oturum | ADMIN | from, limit, offset, q, to, type | — | `app/api/admin/referral-commission/route.ts` |
| `GET` | `/api/admin/referral-commission/settings` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/referral-commission/settings/route.ts` |
| `PATCH` | `/api/admin/referral-commission/settings` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/referral-commission/settings/route.ts` |
| `GET` | `/api/admin/refunds` | mobil JWT + web oturum | ADMIN, AUDIT | status | — | `app/api/admin/refunds/route.ts` |
| `PATCH` | `/api/admin/refunds` | mobil JWT + web oturum | ADMIN, AUDIT | status | adminNote | `app/api/admin/refunds/route.ts` |
| `GET` | `/api/admin/remote-config` | mobil JWT + web oturum | ADMIN | group | — | `app/api/admin/remote-config/route.ts` |
| `POST` | `/api/admin/remote-config` | mobil JWT + web oturum | ADMIN | group | description, group, key, platform, value, valueType | `app/api/admin/remote-config/route.ts` |
| `DELETE` | `/api/admin/remote-config/[configId]` | mobil JWT + web oturum | ADMIN | — | description, group, platform, value, valueType | `app/api/admin/remote-config/[configId]/route.ts` |
| `PATCH` | `/api/admin/remote-config/[configId]` | mobil JWT + web oturum | ADMIN | — | description, group, platform, value, valueType | `app/api/admin/remote-config/[configId]/route.ts` |
| `GET` | `/api/admin/risk-events` | public | ADMIN | category, level, limit, page, reviewed, userId | — | `app/api/admin/risk-events/route.ts` |
| `PATCH` | `/api/admin/risk-events/[eventId]` | public | ADMIN, AUDIT | — | reviewNote, reviewed | `app/api/admin/risk-events/[eventId]/route.ts` |
| `GET` | `/api/admin/roles` | mobil JWT + web oturum | ADMIN, AUDIT | — | — | `app/api/admin/roles/route.ts` |
| `POST` | `/api/admin/roles` | mobil JWT + web oturum | ADMIN, AUDIT | — | description, key, level, name | `app/api/admin/roles/route.ts` |
| `DELETE` | `/api/admin/roles/[roleId]` | mobil JWT + web oturum | ADMIN, AUDIT | — | description, level, name, permissions | `app/api/admin/roles/[roleId]/route.ts` |
| `PATCH` | `/api/admin/roles/[roleId]` | mobil JWT + web oturum | ADMIN, AUDIT | — | description, level, name, permissions | `app/api/admin/roles/[roleId]/route.ts` |
| `GET` | `/api/admin/room-themes` | public | ADMIN | — | — | `app/api/admin/room-themes/route.ts` |
| `GET` | `/api/admin/room-themes/backgrounds` | mobil JWT + web oturum | ADMIN | category, isActive, tier | — | `app/api/admin/room-themes/backgrounds/route.ts` |
| `PATCH` | `/api/admin/room-themes/backgrounds` | mobil JWT + web oturum | ADMIN | category, isActive, tier | activeFrom, activeTo, animationSpeed, assetType, backgroundUrl, blurAmount, category, cloudStoragePath, description, hasParallax, hasZoom, id, isActive, isEventOnly, isPremium, isVipOnly, name, nameEn, opacity, sortOrder, soundCloudPath, soundUrl, soundVolume, thumbnailCloudPath, thumbnailUrl, tier, videoLoop | `app/api/admin/room-themes/backgrounds/route.ts` |
| `POST` | `/api/admin/room-themes/backgrounds` | mobil JWT + web oturum | ADMIN | category, isActive, tier | activeFrom, activeTo, animationSpeed, assetType, backgroundUrl, blurAmount, category, cloudStoragePath, description, hasParallax, hasZoom, id, isActive, isEventOnly, isPremium, isVipOnly, name, nameEn, opacity, sortOrder, soundCloudPath, soundUrl, soundVolume, thumbnailCloudPath, thumbnailUrl, tier, videoLoop | `app/api/admin/room-themes/backgrounds/route.ts` |
| `GET` | `/api/admin/rooms` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/rooms/route.ts` |
| `PATCH` | `/api/admin/rooms` | mobil JWT + web oturum | ADMIN | — | giftBeneficiaryId, giftCommissionPercent, roomId | `app/api/admin/rooms/route.ts` |
| `GET` | `/api/admin/rtc-telemetry` | public | ADMIN | context, contextId, hours, level, limit, page, platform, userId | — | `app/api/admin/rtc-telemetry/route.ts` |
| `GET` | `/api/admin/seo-settings` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/seo-settings/route.ts` |
| `POST` | `/api/admin/seo-settings` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/seo-settings/route.ts` |
| `GET` | `/api/admin/settings` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/settings/route.ts` |
| `POST` | `/api/admin/settings` | mobil JWT + web oturum | ADMIN | — | description, key, value | `app/api/admin/settings/route.ts` |
| `DELETE` | `/api/admin/site-pages` | mobil JWT + web oturum | ADMIN | admin, id | content, contentEn, id, isPublished, items, reorder, showInFooter, showInHeader, slug, sortOrder, title, titleEn | `app/api/admin/site-pages/route.ts` |
| `GET` | `/api/admin/site-pages` | mobil JWT + web oturum | ADMIN | admin, id | — | `app/api/admin/site-pages/route.ts` |
| `POST` | `/api/admin/site-pages` | mobil JWT + web oturum | ADMIN | admin, id | content, contentEn, id, isPublished, items, reorder, showInFooter, showInHeader, slug, sortOrder, title, titleEn | `app/api/admin/site-pages/route.ts` |
| `PUT` | `/api/admin/site-pages` | mobil JWT + web oturum | ADMIN | admin, id | content, contentEn, id, isPublished, items, reorder, showInFooter, showInHeader, slug, sortOrder, title, titleEn | `app/api/admin/site-pages/route.ts` |
| `GET` | `/api/admin/statistics` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/statistics/route.ts` |
| `GET` | `/api/admin/support` | public | ADMIN | category, page, pageSize, status | — | `app/api/admin/support/route.ts` |
| `GET` | `/api/admin/system-stats` | public | ADMIN, AUDIT | — | — | `app/api/admin/system-stats/route.ts` |
| `POST` | `/api/admin/teller-levels` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/teller-levels/route.ts` |
| `GET` | `/api/admin/teller-performance` | mobil JWT + web oturum | ADMIN | level, q, sortBy, sortDir | — | `app/api/admin/teller-performance/route.ts` |
| `GET` | `/api/admin/teller-verification` | mobil JWT + web oturum | ADMIN | status | — | `app/api/admin/teller-verification/route.ts` |
| `POST` | `/api/admin/teller-verification` | mobil JWT + web oturum | ADMIN | status | action, note, tellerId | `app/api/admin/teller-verification/route.ts` |
| `GET` | `/api/admin/ticker-messages` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/ticker-messages/route.ts` |
| `POST` | `/api/admin/ticker-messages` | mobil JWT + web oturum | ADMIN | — | icon, text | `app/api/admin/ticker-messages/route.ts` |
| `DELETE` | `/api/admin/ticker-messages/[messageId]` | mobil JWT + web oturum | ADMIN | — | icon, isActive, sortOrder, text | `app/api/admin/ticker-messages/[messageId]/route.ts` |
| `PATCH` | `/api/admin/ticker-messages/[messageId]` | mobil JWT + web oturum | ADMIN | — | icon, isActive, sortOrder, text | `app/api/admin/ticker-messages/[messageId]/route.ts` |
| `DELETE` | `/api/admin/tiktok-categories` | mobil JWT + web oturum | ADMIN | id | description, id, isActive, sortOrder, title | `app/api/admin/tiktok-categories/route.ts` |
| `GET` | `/api/admin/tiktok-categories` | mobil JWT + web oturum | ADMIN | id | — | `app/api/admin/tiktok-categories/route.ts` |
| `PATCH` | `/api/admin/tiktok-categories` | mobil JWT + web oturum | ADMIN | id | description, id, isActive, sortOrder, title | `app/api/admin/tiktok-categories/route.ts` |
| `POST` | `/api/admin/tiktok-categories` | mobil JWT + web oturum | ADMIN | id | description, id, isActive, sortOrder, title | `app/api/admin/tiktok-categories/route.ts` |
| `DELETE` | `/api/admin/tiktok-videos` | mobil JWT + web oturum | ADMIN | categoryId, id, search | categoryId, id, isActive, sortOrder, tiktokUrl, tiktokUrls, title | `app/api/admin/tiktok-videos/route.ts` |
| `GET` | `/api/admin/tiktok-videos` | mobil JWT + web oturum | ADMIN | categoryId, id, search | — | `app/api/admin/tiktok-videos/route.ts` |
| `PATCH` | `/api/admin/tiktok-videos` | mobil JWT + web oturum | ADMIN | categoryId, id, search | categoryId, id, isActive, sortOrder, tiktokUrl, tiktokUrls, title | `app/api/admin/tiktok-videos/route.ts` |
| `POST` | `/api/admin/tiktok-videos` | mobil JWT + web oturum | ADMIN | categoryId, id, search | categoryId, id, isActive, sortOrder, tiktokUrl, tiktokUrls, title | `app/api/admin/tiktok-videos/route.ts` |
| `PUT` | `/api/admin/tiktok-videos` | mobil JWT + web oturum | ADMIN | categoryId, id, search | categoryId, id, isActive, sortOrder, tiktokUrl, tiktokUrls, title | `app/api/admin/tiktok-videos/route.ts` |
| `GET` | `/api/admin/topup-bonus-tiers` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/topup-bonus-tiers/route.ts` |
| `POST` | `/api/admin/topup-bonus-tiers` | mobil JWT + web oturum | ADMIN | — | currency, label, sourceType | `app/api/admin/topup-bonus-tiers/route.ts` |
| `DELETE` | `/api/admin/topup-bonus-tiers/[id]` | mobil JWT + web oturum | ADMIN | — | bonusPercent, currency, isActive, label, maxBonus, minAmount, sortOrder, sourceType | `app/api/admin/topup-bonus-tiers/[id]/route.ts` |
| `PATCH` | `/api/admin/topup-bonus-tiers/[id]` | mobil JWT + web oturum | ADMIN | — | bonusPercent, currency, isActive, label, maxBonus, minAmount, sortOrder, sourceType | `app/api/admin/topup-bonus-tiers/[id]/route.ts` |
| `GET` | `/api/admin/tournaments` | mobil JWT + web oturum | ADMIN, AUDIT, LEDGER, CONFIRM | category, limit, page, status | — | `app/api/admin/tournaments/route.ts` |
| `POST` | `/api/admin/tournaments` | mobil JWT + web oturum | ADMIN, AUDIT, LEDGER, CONFIRM | category, limit, page, status | action, category, confirm, coverImage, description, eliminationType, endDate, endedAt, id, matchId, maxParticipants, minParticipants, name, newStatus, notes, pkBattleId, registrationEnd, registrationStart, rewards, roundCount, roundId, scoringType, side1Id, side1Name, side1Score, side2Id, side2Name, side2Score, stage, startDate, startedAt, status, title, type, visibility, weekEnd, weekStart, winnerId | `app/api/admin/tournaments/route.ts` |
| `GET` | `/api/admin/trend-videos` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/trend-videos/route.ts` |
| `POST` | `/api/admin/trend-videos` | mobil JWT + web oturum | ADMIN | — | action, categoryId, channelName, description, duration, id, isActive, sortOrder, thumbnailUrl, title, videos, youtubeId | `app/api/admin/trend-videos/route.ts` |
| `POST` | `/api/admin/trend-videos/youtube` | mobil JWT + web oturum | ADMIN | — | action, maxResults, query, urls | `app/api/admin/trend-videos/youtube/route.ts` |
| `DELETE` | `/api/admin/trends` | mobil JWT + web oturum | ADMIN | category, id | id | `app/api/admin/trends/route.ts` |
| `GET` | `/api/admin/trends` | mobil JWT + web oturum | ADMIN | category, id | — | `app/api/admin/trends/route.ts` |
| `POST` | `/api/admin/trends` | mobil JWT + web oturum | ADMIN | category, id | id | `app/api/admin/trends/route.ts` |
| `GET` | `/api/admin/users` | mobil JWT + web oturum | ADMIN | adv, limit, membership, page, role, search, segment, sortBy, sortDir | — | `app/api/admin/users/route.ts` |
| `DELETE` | `/api/admin/users/[userId]` | mobil JWT + web oturum | ADMIN | — | action, amount, banReason, credits, email, image, membership, membershipExpiresAt, name, newPassword, phone, profileEffect, role, specialBadges, streamBanReason, username | `app/api/admin/users/[userId]/route.ts` |
| `GET` | `/api/admin/users/[userId]` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/users/[userId]/route.ts` |
| `PATCH` | `/api/admin/users/[userId]` | mobil JWT + web oturum | ADMIN | — | action, amount, banReason, credits, email, image, membership, membershipExpiresAt, name, newPassword, phone, profileEffect, role, specialBadges, streamBanReason, username | `app/api/admin/users/[userId]/route.ts` |
| `GET` | `/api/admin/users/[userId]/360` | public | ADMIN | limit, page, range, section | — | `app/api/admin/users/[userId]/360/route.ts` |
| `GET` | `/api/admin/users/[userId]/manage` | public | ADMIN, AUDIT, LEDGER, CONFIRM | — | — | `app/api/admin/users/[userId]/manage/route.ts` |
| `POST` | `/api/admin/users/[userId]/manage` | public | ADMIN, AUDIT, LEDGER, CONFIRM | — | action, granted, permissionKey | `app/api/admin/users/[userId]/manage/route.ts` |
| `GET` | `/api/admin/users/search` | mobil JWT + web oturum | ADMIN | limit, q | — | `app/api/admin/users/search/route.ts` |
| `POST` | `/api/admin/users/withdrawal-limit` | mobil JWT + web oturum | ADMIN | — | limit, userId | `app/api/admin/users/withdrawal-limit/route.ts` |
| `GET` | `/api/admin/verification` | public | ADMIN, AUDIT | page, pageSize, status, type | — | `app/api/admin/verification/route.ts` |
| `PATCH` | `/api/admin/verification` | public | ADMIN, AUDIT | page, pageSize, status, type | action, id, reviewNote | `app/api/admin/verification/route.ts` |
| `DELETE` | `/api/admin/video-streams` | mobil JWT + web oturum | ADMIN | status | action, streamId | `app/api/admin/video-streams/route.ts` |
| `GET` | `/api/admin/video-streams` | mobil JWT + web oturum | ADMIN | status | — | `app/api/admin/video-streams/route.ts` |
| `PATCH` | `/api/admin/video-streams` | mobil JWT + web oturum | ADMIN | status | action, streamId | `app/api/admin/video-streams/route.ts` |
| `GET` | `/api/admin/visitor-stats` | mobil JWT + web oturum | ADMIN | — | — | `app/api/admin/visitor-stats/route.ts` |
| `GET` | `/api/admin/withdrawals` | mobil JWT + web oturum | ADMIN, AUDIT | status | — | `app/api/admin/withdrawals/route.ts` |
| `POST` | `/api/admin/withdrawals` | mobil JWT + web oturum | ADMIN, AUDIT | status | action, adminNote, requestId | `app/api/admin/withdrawals/route.ts` |
| `GET` | `/api/announcements` | public | ADMIN | — | — | `app/api/announcements/route.ts` |
| `POST` | `/api/announcements` | public | ADMIN | — | path, section | `app/api/announcements/route.ts` |
| `POST` | `/api/announcements/event` | public | ADMIN | — | details, eventType | `app/api/announcements/event/route.ts` |
| `GET` | `/api/chat/rooms/[roomId]/dj` | mobil JWT + web oturum | ADMIN | — | — | `app/api/chat/rooms/[roomId]/dj/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/dj` | mobil JWT + web oturum | ADMIN | — | action, userId | `app/api/chat/rooms/[roomId]/dj/route.ts` |
| `GET` | `/api/chat/rooms/[roomId]/pk` | mobil JWT + web oturum | ADMIN, RL, IDEM, AUDIT | — | — | `app/api/chat/rooms/[roomId]/pk/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/pk` | mobil JWT + web oturum | ADMIN, RL, IDEM, AUDIT | — | opponentUserId, side1UserIds, side2UserIds | `app/api/chat/rooms/[roomId]/pk/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/pk/score` | mobil JWT + web oturum | ADMIN, AUDIT | — | amount, battleId, side | `app/api/chat/rooms/[roomId]/pk/score/route.ts` |
| `DELETE` | `/api/chat/rooms/[roomId]/presence` | mobil JWT + web oturum | ADMIN | _delete, leave | nickname, password, seatIndex | `app/api/chat/rooms/[roomId]/presence/route.ts` |
| `GET` | `/api/chat/rooms/[roomId]/presence` | mobil JWT + web oturum | ADMIN | _delete, leave | — | `app/api/chat/rooms/[roomId]/presence/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/presence` | mobil JWT + web oturum | ADMIN | _delete, leave | nickname, password, seatIndex | `app/api/chat/rooms/[roomId]/presence/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/transfer-ownership` | mobil JWT + web oturum | ADMIN | — | newOwnerId | `app/api/chat/rooms/[roomId]/transfer-ownership/route.ts` |
| `DELETE` | `/api/dreams/[slug]/comments` | public | ADMIN, RL | page, type | commentId, content, didComeTrue, experienceType | `app/api/dreams/[slug]/comments/route.ts` |
| `GET` | `/api/dreams/[slug]/comments` | public | ADMIN, RL | page, type | — | `app/api/dreams/[slug]/comments/route.ts` |
| `POST` | `/api/dreams/[slug]/comments` | public | ADMIN, RL | page, type | commentId, content, didComeTrue, experienceType | `app/api/dreams/[slug]/comments/route.ts` |
| `GET` | `/api/fortune-tellers/[tellerId]` | mobil JWT + web oturum | ADMIN | — | — | `app/api/fortune-tellers/[tellerId]/route.ts` |
| `PATCH` | `/api/fortune-tellers/[tellerId]` | mobil JWT + web oturum | ADMIN | — | avatar, bio, displayName, isActive, isOnline, isVerified, pricePerSession, specialties | `app/api/fortune-tellers/[tellerId]/route.ts` |
| `POST` | `/api/live/pk/score` | public | ADMIN, AUDIT | — | amount, battleId, roomId, side | `app/api/live/pk/score/route.ts` |
| `DELETE` | `/api/short-videos/[id]/comments/[commentId]` | public | ADMIN | — | — | `app/api/short-videos/[id]/comments/[commentId]/route.ts` |
| `GET` | `/api/video-streams/[streamId]` | mobil JWT + web oturum | ADMIN | — | — | `app/api/video-streams/[streamId]/route.ts` |
| `PATCH` | `/api/video-streams/[streamId]` | mobil JWT + web oturum | ADMIN | — | backgroundUrl, broadcastImage, description, isImageMode, status, title | `app/api/video-streams/[streamId]/route.ts` |
| `POST` | `/api/video-streams/[streamId]/end` | public | ADMIN | — | — | `app/api/video-streams/[streamId]/end/route.ts` |
| `GET` | `/api/video-streams/pk` | mobil JWT + web oturum | ADMIN, RL, IDEM, AUDIT | streamId | — | `app/api/video-streams/pk/route.ts` |
| `POST` | `/api/video-streams/pk` | mobil JWT + web oturum | ADMIN, RL, IDEM, AUDIT | streamId | action, battleId, duration, opponentVoiceRoomId, streamId, targetStreamId | `app/api/video-streams/pk/route.ts` |

---

## GÜNCELLEME 2026-09-12 — Yetki Denetimi Doğrulaması

Statik tarama (`sec_scan`) 554 rota dosyasında yönetici uçlarını denetledi.

| Bulgu | Sonuç |
|---|---|
| Koruması görünmeyen 7 kozmetik yönetici ucu | **Yanlış pozitif** — koruma `lib/cosmetics.ts` içinde merkezî (`ADMIN_ROLES = ['admin','yonetici','moderator','finans']`) |
| `/api/chat/cleanup` | Korumalı — `CRON_SECRET` bearer denetimi |
| `/api/membership/purchase` | Yeniden dışa aktarım takma adı, hedef uç korumalı |
| Diğer 141 `ADMIN_ONLY` rotası | `resolveUser` + RBAC, `requireAnimationAdmin`, `requireAdAdmin`, `isAdmin` veya `getServerSession` ile korunuyor |

**İstemciden gelen `isAdmin` / `role` alanına hiçbir uçta güvenilmez**; rol her istekte veritabanından okunur. Flutter istemcisinde rol yalnız arayüz gizleme amaçlıdır, yetki değildir.

### Kritik işlem onayı
`lib/critical-confirm.ts`: eşikleri aşan işlemler (`jeton > 1000`, `cfc > 5000`, `amountTl > 2000`) önce `409` + `requiresConfirmation: true` döner; istemci `confirm: true` ile tekrar göndermelidir. Flutter tarafında bu iki adımlı akış uygulanmalıdır.


---

## GÜNCELLEME 2026-09-12 (2) — BÖLÜM 22 yönetici yüzeyi

BÖLÜM 22 (Multi-Guest + PK + Hediye Kutusu) ile eklenen yönetici/moderatör yetkileri:

| Uç | Yetki kontrolü | Not |
|---|---|---|
| `POST /api/chat/rooms/[roomId]/pk/score` | `staffCan(..., 'moderation.room.manage', ['admin','superadmin'])` | Manuel skor müdahalesi; `pk_max_manual_points` ile sınırlı, `PkScore(source:'manual')` olarak deftere yazılır ve audit'lenir |
| `POST /api/live/pk/score` | aynı | Yayın PK'sı manuel skor müdahalesi |
| `POST /api/live/guest` (mute / camera / remove / position) | Yayın sahibi veya moderatör | Host kilidi: kullanıcı kendi mikrofonunu geri açamaz |
| `POST /api/gift-box` (`cancel`) | Yalnız kutu sahibi | Admin iptali yok; iptal tam iade üretir |
| Admin paneli → Ayarlar | `PlatformSettings` | 19 yeni anahtar: 4 Multi-Guest, 8 PK, 7 Hediye Kutusu |

Audit noktaları: yayın PK'da 5 (create, accept, reject/cancel, end, start/pause/resume), oda PK'da 6 (+ create_user), manuel skorda 2, hediye kutusunda 2 (create, cancel).
