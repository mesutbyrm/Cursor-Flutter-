# gifts_coins_wallet_api.md — Hediye, Jeton, CFC, Gold ve Cüzdan

> Kaynak: üretim kodu taraması (2026-09-12).

## 1. Para birimleri (kaynakta doğrulanmış)

| Birim | Alan | Anlam |
|---|---|---|
| **Jeton** | `User.jetonBalance` | Satın alınan / hediye ile kazanılan, **çekilebilir** birim |
| **CFC** | `User.credits` (API'de `cfcBalance` olarak da döner) | Ödül/etkinlik birimi, **nakde çevrilemez** |
| **Gold üyelik** | `User.membership` + `User.membershipExpiresAt` | `basic` · `gold` · `diamond` |

## 2. Cüzdan

**`GET /api/wallet`** — yalnız mobil JWT (`authenticateRequest`)
```json
{ "coins": 0, "jetonBalance": 0, "cfcBalance": 55, "credits": 55 }
```
Hatalar: `401`, `404`, `500`.

Alternatif: `GET /api/user/wallet` (web oturumu). Jeton fiyatı: `GET /api/public/jeton-price`.

## 3. Jeton uçları

**`GET /api/jeton`**
```json
{
  "jetonBalance": 0,
  "streak": { "currentStreak": 0, "longestStreak": 0, "totalFortunes": 0 },
  "todayTasks": ["daily_login"],
  "recentHistory": [],
  "loginBonusAvailable": true
}
```

**`POST /api/jeton`** gövde `{ "action": "daily_login" }` → tek bir interaktif transaction içinde **+5 CFC**; `creditTransaction` + `dailyTask` kaydı + `recordLedger(category:'daily_bonus', currency:'cfc')`.
Yarış durumu koruması: unique ihlali (P2002) → `400` `{ "error": "Günlük bonus zaten alındı", "alreadyClaimed": true }`.

İlgili: `GET /api/daily-login`, `GET /api/daily-missions`, `GET /api/referral`, `GET /api/credit-packages`.

## 4. Hediye gönderimi

**`POST /api/gifts/send`** — mobil JWT · rate limitli · **idempotent**
Gövde alanları (kaynaktan): `type`, `giftTypeId`, `jetonAmount`, `recipientUsername`.

İki dal vardır:

**a) Hediye dalı**
```json
{
  "success": true,
  "message": "<giftName> hediyesi <recipient> kişisine gönderildi! 🎁",
  "bigGift": { "senderName": "...", "recipientName": "...", "giftIcon": "...", "giftType": "...", "amount": 0 }
}
```
`bigGift` eşik altındaki hediyelerde `null` döner.

**b) Jeton transfer dalı** (`type === "jeton"` + `jetonAmount`)
```json
{ "success": true, "message": "<n> jeton <recipient> kişisine gönderildi!",
  "bigGift": { "giftIcon": "🪙", "giftType": "Jeton", "...": "..." } }
```
Komisyon: `jeton_transfer_commission` platform ayarı (varsayılan %0). Personel (`isStaff`) bakiye kontrolünü atlar.

Hatalar: `401` · `429` · `400 "Yetersiz jeton"` · `400 "Invalid jeton amount"` · `400 "Invalid request type"` · `403` (`error`+`message`) · `404` · `500 "Bir hata oluştu"`.

### Idempotency
`Idempotency-Key` (veya `X-Idempotency-Key`) başlığı gönderin. TTL **24 saat** (`lib/idempotency.ts`). Başlık yoksa koruma devre dışıdır — **Flutter'da zorunlu tutun**: ağ kopmasında aynı anahtarla tekrar deneyin, çift harcama olmaz.

## 5. Hediye kataloğu ve ek hediye sistemleri

| İşlem | Endpoint | Auth |
|---|---|---|
| Katalog | `GET /api/gifts/catalog` | mobil + web |
| Tipler | `GET /api/gifts/types` | public |
| Katalog sürümü (cache invalidation) | `GET /api/gifts/version` | public |
| Son büyük hediyeler | `GET /api/gifts/recent-big` | public |
| Şanslı hediye | `GET /api/gifts/lucky/config`, `POST /api/gifts/lucky/send`, `GET /api/gifts/lucky/history` | mobil + web |
| Hediye savaşları | `GET` · `POST /api/gifts/battles`, `GET /api/gifts/battles/[battleId]` | |
| Hediye hedefleri | `GET` · `POST /api/gifts/goals` | |
| Görevler | `GET /api/gifts/missions`, `GET /api/gifts/missions/me`, `POST /api/gifts/missions/[missionId]/claim` | |
| İçgörüler | `/api/gifts/insights/*` (album, badge, collection, feed, first-gifter, leaderboard, map, me/*) | çoğu public |
| Karşılıklılık kontrolü | `POST /api/gifts/check-reciprocal` (gövde `recipientId`) | mobil JWT |

Bağlama özel hediye uçları: `POST /api/chat/rooms/[roomId]/gifts`, `POST /api/video-streams/[streamId]/gifts`, `POST /api/live/gift/send`.

## 6. Gold / üyelik

| İşlem | Endpoint | Auth |
|---|---|---|
| Planlar | `GET /api/membership/plans`, `GET /api/memberships`, `GET /api/memberships/packages` | public |
| Satın al | `POST /api/memberships/purchase` (gövde `planId`, `paymentMethod`) | mobil JWT |
| Rozetler | `GET /api/membership-badges` | public |

Satın alma **idempotent** (`membership_purchase` kategorisi). Süre ve ayrıcalık hesabı **tamamen sunucuda**; `membershipExpiresAt` sunucu tarafından yazılır. Gold kullanıcılar için giriş animasyonu olayları `websocket_events.md` içindedir.

## 7. Ödeme bildirimi ve itiraz

| İşlem | Endpoint |
|---|---|
| Ödeme yöntemleri / ayarları | `GET /api/payments/methods`, `GET /api/payments/settings` (public), `GET /api/payments/config` |
| Bildirim gönder / geçmiş | `POST` · `GET /api/payments/notify` |
| Talepler | `GET` · `POST /api/payments/requests` |
| İtiraz | `GET` · `POST /api/payments/notifications/[notificationId]/dispute` |

`POST /api/payments/notify` gövdesi: `productType` (`jeton` \| `cfc` \| `gold`), `requestedAmount`, `requestedGoldDays` (1–3650), `requestedGoldType`, `proofUrl`, `transactionId`, `notes`.
`GET /api/payments/notify` **düz dizi** döner (geriye dönük uyumluluk için) — her kayıtta `statusLabel`, `productLabel`, `requestedSummary`, `loadedSummary`, `adminMessage`, `canDispute`, `disputeTicketId`, `disputeStatus`.

İtiraz, mevcut destek talebi (SupportTicket) sistemini kullanır: `category='payment'`, `priority='high'`. Beklemedeki ödemeye itiraz `400`, aynı ödeme için açık itiraz varsa `409`.

Onaylanan ödemede kredi yükleme **idempotent**tir (`creditApplied` bayrağı).

## 8. Çekim (withdrawal)

`GET` · `POST /api/withdrawals` — gövde: `amount`, `currency`, `method`, `accountDetails`.
Sunucu koruması: bakiye kontrolü, minimum tutar, günlük limit, bekleyen talep kontrolü, rate limit, idempotency. **CFC çekilemez, yalnız jeton.**

## 9. Ledger (çift taraflı muhasebe)

`lib/ledger.ts` → `recordLedger`, `recordMultiLeg`, `getAccountLedger`, `getTransaction`.
`LedgerCategory` 23 değer içerir; bunlar arasında `daily_bonus`, `tournament_reward`, `leaderboard_reward` de vardır. Her finansal hareket borç/alacak çifti olarak yazılır. Flutter bu tabloyu **yalnızca okur** (geçmiş ekranı), yazmaz.

## 10. Kritik işlem onayı (409)

`lib/critical-confirm.ts` → `CRITICAL_THRESHOLDS = { jeton: 1000, cfc: 5000, amountTl: 2000 }`.
Eşik aşıldığında sunucu **409** döner:
```json
{ "requiresConfirmation": true,
  "confirmationMessage": "5.000 jeton yüklemek istediğinize emin misiniz? (Ad Soyad)",
  "action": "jeton_adjust" }
```
İstemci onay diyaloğunu gösterir ve **aynı gövdeyi `"confirm": true` ekleyerek** yeniden gönderir. Flutter'da bu davranış genel bir HTTP interceptor olarak uygulanmalıdır.

## 11. Flutter için kritik notlar

- Bakiye **asla** istemcide hesaplanmaz; her işlemden sonra `GET /api/wallet` ile tazeleyin.
- Hediye/satın alma/çekim çağrılarında `Idempotency-Key` zorunlu tutun.
- `409 requiresConfirmation` akışını global olarak ele alın.
- İade (refund) için **genel bir kullanıcı ucu YOKTUR → MISSING**; iade yalnızca admin paneli üzerinden yapılır.
- Google Play / App Store içi satın alma doğrulama ucu **YOKTUR → MISSING** (mağaza içi satın alma kullanılacaksa yeni bir uç gerekir).

## 12. Tam endpoint tablosu (hediye + cüzdan + ödeme + üyelik)

> Toplam **61** endpoint (path+method). Kaynak: üretim kodu taraması, 2026-09-12.

| METHOD | ENDPOINT | AUTH | ÖZELLİK | QUERY | BODY ALANLARI | KAYNAK DOSYA |
|---|---|---|---|---|---|---|
| `GET` | `/api/credit-packages` | public | — | — | — | `app/api/credit-packages/route.ts` |
| `GET` | `/api/currency-branding` | public | — | — | — | `app/api/currency-branding/route.ts` |
| `GET` | `/api/daily-login` | mobil JWT | — | — | — | `app/api/daily-login/route.ts` |
| `POST` | `/api/daily-login` | mobil JWT | — | — | — | `app/api/daily-login/route.ts` |
| `GET` | `/api/daily-missions` | mobil JWT | — | — | taskType | `app/api/daily-missions/route.ts` |
| `POST` | `/api/daily-missions` | mobil JWT | — | — | taskType | `app/api/daily-missions/route.ts` |
| `POST` | `/api/gift-engine/finish` | mobil JWT + web oturum | — | — | — | `app/api/gift-engine/finish/route.ts` |
| `GET` | `/api/gift-engine/gifts` | public | — | collectionId, context | — | `app/api/gift-engine/gifts/route.ts` |
| `GET` | `/api/gift-engine/queue` | public | — | contextId | — | `app/api/gift-engine/queue/route.ts` |
| `GET` | `/api/gifts/battles` | mobil JWT + web oturum | — | — | — | `app/api/gifts/battles/route.ts` |
| `POST` | `/api/gifts/battles` | mobil JWT + web oturum | — | — | — | `app/api/gifts/battles/route.ts` |
| `GET` | `/api/gifts/battles/[battleId]` | public | — | — | — | `app/api/gifts/battles/[battleId]/route.ts` |
| `GET` | `/api/gifts/catalog` | mobil JWT + web oturum | — | context, sinceVersion | — | `app/api/gifts/catalog/route.ts` |
| `POST` | `/api/gifts/check-reciprocal` | mobil JWT | — | — | recipientId | `app/api/gifts/check-reciprocal/route.ts` |
| `GET` | `/api/gifts/goals` | mobil JWT + web oturum | — | — | — | `app/api/gifts/goals/route.ts` |
| `POST` | `/api/gifts/goals` | mobil JWT + web oturum | — | — | — | `app/api/gifts/goals/route.ts` |
| `GET` | `/api/gifts/insights/album/[userId]` | public | — | — | — | `app/api/gifts/insights/album/[userId]/route.ts` |
| `GET` | `/api/gifts/insights/badge/[userId]` | public | — | — | — | `app/api/gifts/insights/badge/[userId]/route.ts` |
| `GET` | `/api/gifts/insights/collection/[userId]` | public | — | — | — | `app/api/gifts/insights/collection/[userId]/route.ts` |
| `GET` | `/api/gifts/insights/feed` | public | — | context, contextId, limit | — | `app/api/gifts/insights/feed/route.ts` |
| `GET` | `/api/gifts/insights/first-gifter/[context]/[contextId]` | public | — | — | — | `app/api/gifts/insights/first-gifter/[context]/[contextId]/route.ts` |
| `GET` | `/api/gifts/insights/leaderboard` | public | — | context, limit, period, scope, type | — | `app/api/gifts/insights/leaderboard/route.ts` |
| `GET` | `/api/gifts/insights/map` | public | — | context, period, scope | — | `app/api/gifts/insights/map/route.ts` |
| `GET` | `/api/gifts/insights/me/badge` | mobil JWT + web oturum | — | — | — | `app/api/gifts/insights/me/badge/route.ts` |
| `GET` | `/api/gifts/insights/me/history` | mobil JWT + web oturum | — | direction, limit, page, status | — | `app/api/gifts/insights/me/history/route.ts` |
| `GET` | `/api/gifts/insights/me/recommendations` | mobil JWT + web oturum | — | context, limit | — | `app/api/gifts/insights/me/recommendations/route.ts` |
| `GET` | `/api/gifts/lucky/config` | mobil JWT + web oturum | — | — | — | `app/api/gifts/lucky/config/route.ts` |
| `GET` | `/api/gifts/lucky/history` | mobil JWT + web oturum | — | limit, scope | — | `app/api/gifts/lucky/history/route.ts` |
| `POST` | `/api/gifts/lucky/send` | mobil JWT + web oturum | RL | — | — | `app/api/gifts/lucky/send/route.ts` |
| `GET` | `/api/gifts/missions` | public | — | — | — | `app/api/gifts/missions/route.ts` |
| `POST` | `/api/gifts/missions/[missionId]/claim` | mobil JWT + web oturum | IDEM | — | — | `app/api/gifts/missions/[missionId]/claim/route.ts` |
| `GET` | `/api/gifts/missions/me` | mobil JWT + web oturum | — | — | — | `app/api/gifts/missions/me/route.ts` |
| `GET` | `/api/gifts/recent-big` | public | — | — | — | `app/api/gifts/recent-big/route.ts` |
| `POST` | `/api/gifts/send` | mobil JWT | ADMIN, RL, IDEM, LEDGER | — | giftTypeId, jetonAmount, recipientUsername, type | `app/api/gifts/send/route.ts` |
| `GET` | `/api/gifts/types` | public | — | — | — | `app/api/gifts/types/route.ts` |
| `GET` | `/api/gifts/version` | public | — | — | — | `app/api/gifts/version/route.ts` |
| `GET` | `/api/jeton` | mobil JWT | LEDGER | — | action | `app/api/jeton/route.ts` |
| `POST` | `/api/jeton` | mobil JWT | LEDGER | — | action | `app/api/jeton/route.ts` |
| `GET` | `/api/membership-badges` | public | — | — | — | `app/api/membership-badges/route.ts` |
| `GET` | `/api/membership/plans` | public | — | — | — | `app/api/membership/plans/route.ts` |
| `POST` | `/api/membership/purchase` | public | — | — | — | `app/api/membership/purchase/route.ts` |
| `GET` | `/api/memberships` | public | — | — | — | `app/api/memberships/route.ts` |
| `GET` | `/api/memberships/packages` | public | — | — | — | `app/api/memberships/packages/route.ts` |
| `POST` | `/api/memberships/purchase` | mobil JWT | ADMIN, RL, IDEM, LEDGER | — | paymentMethod, planId | `app/api/memberships/purchase/route.ts` |
| `GET` | `/api/payments/config` | mobil JWT | — | — | — | `app/api/payments/config/route.ts` |
| `GET` | `/api/payments/methods` | public | — | — | — | `app/api/payments/methods/route.ts` |
| `GET` | `/api/payments/notifications/[notificationId]/dispute` | web oturum | RL | — | — | `app/api/payments/notifications/[notificationId]/dispute/route.ts` |
| `POST` | `/api/payments/notifications/[notificationId]/dispute` | web oturum | RL | — | — | `app/api/payments/notifications/[notificationId]/dispute/route.ts` |
| `GET` | `/api/payments/notify` | mobil JWT + web oturum | — | limit, page, status | — | `app/api/payments/notify/route.ts` |
| `POST` | `/api/payments/notify` | mobil JWT + web oturum | — | limit, page, status | — | `app/api/payments/notify/route.ts` |
| `GET` | `/api/payments/requests` | mobil JWT | RL, IDEM | — | — | `app/api/payments/requests/route.ts` |
| `POST` | `/api/payments/requests` | mobil JWT | RL, IDEM | — | — | `app/api/payments/requests/route.ts` |
| `GET` | `/api/payments/settings` | public | — | — | — | `app/api/payments/settings/route.ts` |
| `GET` | `/api/public/jeton-price` | public | — | — | — | `app/api/public/jeton-price/route.ts` |
| `GET` | `/api/referral` | mobil JWT + web oturum | — | — | — | `app/api/referral/route.ts` |
| `GET` | `/api/referral/validate` | public | — | code | — | `app/api/referral/validate/route.ts` |
| `GET` | `/api/user/credits` | mobil JWT | — | — | — | `app/api/user/credits/route.ts` |
| `GET` | `/api/user/wallet` | mobil JWT + web oturum | — | currency, limit, offset | — | `app/api/user/wallet/route.ts` |
| `GET` | `/api/wallet` | mobil JWT | — | — | — | `app/api/wallet/route.ts` |
| `GET` | `/api/withdrawals` | mobil JWT + web oturum | RL, IDEM, LEDGER | — | accountDetails, amount, currency, method | `app/api/withdrawals/route.ts` |
| `POST` | `/api/withdrawals` | mobil JWT + web oturum | RL, IDEM, LEDGER | — | accountDetails, amount, currency, method | `app/api/withdrawals/route.ts` |

---

## GÜNCELLEME 2026-09-12 — Negatif Bakiye Koruması ve Mağaza Satın Alma Doğrulaması (GERÇEK KOD)

### 1. Atomik bakiye düşümü
`lib/balance-guard.ts` eklendi: `atomicDebitJeton` / `atomicDebitCredits` / `atomicDebitOp`.
Koşullu tek SQL güncellemesi kullanır (`UPDATE ... WHERE id = $1 AND "jetonBalance" >= $2`); yetersiz bakiyede hata fırlatır ve **tüm işlem geri alınır**.

**Harcama yapan 25 noktanın tamamı** (jeton ve CFC) bu yönteme geçirildi: hediye gönderimi (doğrudan/oda/yayın/canlı), jeton transferi, oyun bahisleri (room/sos), oda oluşturma, şarkı isteği, rüya yorumu, falcı seansı, oda süre uzatma, bahşiş, yayın fal talebi, üyelik satın alma, "bana özel" içerik açma ve `lib/fortune-access.ts` CFC düşümü. Artık `SELECT` + `UPDATE` arası yarış koşulu yoktur; yetersiz bakiyede düşüm hiç gerçekleşmez.

### 1b. Yardımcı SQL'deki sabit katlama (constant folding) düzeltmesi

İlk sürümde yetersiz bakiye hatası `ELSE CAST('INSUFFICIENT_BALANCE' AS int)` ile fırlatılıyordu. PostgreSQL planlayıcısı bu **sabit** dönüşümü plan aşamasında değerlendirdiği için, bakiye yeterli olsa bile her düşüm `22P02 invalid input syntax for type integer` hatası veriyordu. Hata yayına alınmadan yakalandı ve düzeltildi; ELSE dalı bir toplama fonksiyonuna bağlanarak çalışma zamanına taşındı:

```sql
WITH upd AS (
  UPDATE "users" SET "<alan>" = "<alan>" - $1::int
  WHERE "id" = $2 AND "<alan>" >= $1::int
  RETURNING "id"
)
SELECT CASE WHEN count(*) = 1
            THEN 1
            ELSE CAST(coalesce(max("id"), 'INSUFFICIENT_BALANCE') AS int) END
FROM upd
```

Satır güncellendiyse ELSE dalı hiç değerlendirilmez. Doğrulandı: normal düşüm uygulanır, yetersiz bakiyede hata fırlar ve bakiye değişmez, `$transaction` (dizi ve interaktif) tamamen geri alınır, uçtan uca istek yeterli bakiyede `200` / yetersiz bakiyede `400` döner.

> **Not:** `atomicDebit*` fonksiyonları tutar `<= 0` ise `INVALID_DEBIT_AMOUNT` fırlatır. Ücretsiz/sıfır maliyetli yollarda çağrı `if (cost > 0)` ile korunmalıdır.

### 2. Veritabanı düzeyinde güvenlik ağı
```sql
ALTER TABLE "users" ADD CONSTRAINT "users_jetonBalance_nonneg" CHECK ("jetonBalance" >= 0) NOT VALID;
ALTER TABLE "users" ADD CONSTRAINT "users_credits_nonneg"      CHECK ("credits" >= 0)      NOT VALID;
```
`NOT VALID` seçilmiştir: mevcut satırlar doğrulanmaz (geriye dönük veri bozulmaz), ancak **bundan sonraki her yazma** zorlanır. Böylece harcama yapan 25 uç noktasının tamamı sessizce negatife düşemez.

### 3. Hata kodu
Yetersiz bakiye artık şu uçlarda `400` + `{ "error": "...", "code": "INSUFFICIENT_BALANCE" }` döner:
`/api/live/gift/send`, `/api/gifts/send`, `/api/chat/rooms/[roomId]/gifts`, `/api/chat/rooms/[roomId]/song-request`, `/api/chat/rooms/create`, `/api/video-streams/[streamId]/gifts`, `/api/video-streams/[streamId]/fortune-requests`, `/api/games/room`, `/api/games/room/[roomId]`, `/api/games/sos`, `/api/games/sos/[gameId]`, `/api/dreams/interpret`, `/api/fortune-tellers/session`, `/api/fortune-tellers/[tellerId]/session`, `/api/room/[sessionId]`, `/api/room/[sessionId]/tip`, `/api/memberships/purchase`, `/api/bana-ozel/open`.

`lib/fortune-access.ts` üzerinden geçen fal uçlarında karşılığı `reason: "needs_cfc"` olarak döner.

### 4. Google Play satın alma doğrulaması
`POST /api/billing/google-play/verify`

Gövde: `{ purchaseToken, productId, orderId? }`

| Durum | Anlam |
|---|---|
| `200` | Doğrulandı ve bakiye yüklendi (veya zaten yüklenmişti) |
| `402` | Play tarafında satın alma geçerli değil |
| `409` | Aynı `purchaseToken` başka bir kullanıcıya ait |
| `503` | Sunucuda Play kimlik bilgileri yapılandırılmamış |

- Sunucu, Google hizmet hesabı ile RS256 JWT üretip `androidpublisher v3` üzerinden satın almayı doğrular. **İstemciden gelen fiyat/ürün bilgisine asla güvenilmez**; ürün → jeton/Gold eşlemesi sunucudaki `store_products_map` ayarından okunur.
- Tekillik: `StorePurchase` tablosunda `@@unique([provider, purchaseToken])`. Aynı fiş ikinci kez gönderilirse yeniden yükleme yapılmaz.
- Yükleme `transaction` içinde yapılır ve `recordLedger(category: 'purchase')` ile çift taraflı deftere işlenir.
- Başarıdan sonra satın alma Play tarafında `acknowledge` edilir (aksi halde Google 3 gün sonra iade eder).

**Gereken yapılandırma (henüz ayarlanmadı):** `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`, `GOOGLE_PLAY_PACKAGE_NAME` ortam değişkenleri ve `store_products_map` ayar kaydı. Bunlar girilene kadar uç `503` döner ve hiçbir bakiye yüklemez.

### 5. Kullanıcı tarafı iade talebi (BÖLÜM 17)

| Metot | Yol | Auth | Açıklama |
|---|---|---|---|
| POST | `/api/refunds` | mobil JWT / web oturumu | İade talebi oluşturur. Gövde `{ reason, paymentId? , storePurchaseId? }`. `reason` ≥ 5 karakter. İlgili ödeme/satın alım kullanıcıya ait değilse `404`. Aynı kayda bekleyen talep varsa mükerrer engellenir. |
| GET | `/api/refunds` | mobil JWT / web oturumu | Kullanıcının kendi iade taleplerini listeler. |

#### Yönetici tarafı

| Metot | Yol | Auth | Açıklama |
|---|---|---|---|
| GET | `/api/admin/refunds?status=...` | admin/yonetici/finans | İade taleplerini listeler (duruma göre filtre). |
| PATCH | `/api/admin/refunds` | admin/yonetici/finans | Gövde `{ id, action, adminNote? }`. `action`: `approve` \| `reject` \| `process`. `process` (processed) durumunda bağlı `Payment`/`StorePurchase` kaydı `refunded` yapılır. Her işlem `recordAudit('refund_<action>')` ile denetime yazılır. |

- İade kayıtları `refund_requests` tablosunda tutulur (`status`: pending → approved/rejected/processed).
- Bu uç **para iadesini fiilen banka/mağaza üzerinden yapmaz**; talep ve karar akışını + kayıt tutarını yönetir. Mağaza tarafı iade (Google/Apple) ilgili konsoldan yapılır.

### 6. Apple App Store satın alma doğrulaması (BÖLÜM 17)

| Metot | Yol | Auth |
|---|---|---|
| POST | `/api/billing/app-store/verify` | mobil JWT / web oturumu |

Gövde: `{ productId, receiptData }` (base64 makbuz).

| Durum | Anlamı |
|---|---|
| `200` | Doğrulandı ve ürün tanımlandı (veya zaten tanımlıydı) |
| `402` | Apple tarafında makbuz geçerli değil |
| `409` | Aynı `transactionId` başka bir kullanıcıya ait |
| `503` | `APPLE_IAP_SHARED_SECRET` yapılandırılmamış |

- Sunucu Apple `verifyReceipt` uç noktasını kullanır; production `21007` dönerse otomatik sandbox'a düşer.
- **İstemciden gelen ürün/fiyat bilgisine güvenilmez**; ürün → jeton/cfc/üyelik eşlemesi Google Play ile **ortak** `store_products_map` ayarından okunur (`lib/store-grant.ts`).
- Tekillik: `StorePurchase` `@@unique([provider, purchaseToken])`, `provider='app_store'`, `purchaseToken=transactionId`. Aynı makbuz ikinci kez yükleme yapmaz.
- Yükleme `transaction` içinde `recordLedger(category: 'purchase')` ile deftere işlenir + `recordAudit`.

### 7. Hâlâ olmayan
- StoreKit 2 `signedTransaction` (JWS) doğrulaması yok; yalnız klasik `verifyReceipt` makbuzu desteklenir.
- Apple Server-to-Server bildirimleri (iade/iptal webhook'u) yok.
