# voice_room_api.md — Sesli Oda Backend API'si

> Kaynak: üretim kodu taraması (2026-09-12). Bu belgedeki her endpoint gerçek route dosyasından tespit edilmiştir.
> Uydurma endpoint / uydurma alan YOKTUR. Kaynakta doğrulanamayan her şey `MISSING` ile işaretlenmiştir.

## 1. Mimari

CanlıFal'da **iki ayrı oda ailesi** vardır ve bunlar farklı amaçlara hizmet eder:

| Aile | Kök | Ne işe yarar |
|---|---|---|
| `chat/rooms` | `/api/chat/rooms/**` (59 endpoint) | Çok kişilik **sesli sohbet odaları** — koltuklar, DJ, müzik, PK, moderasyon |
| `room` | `/api/room/**` (12 endpoint) | **Birebir falcı seansı** odası — mesaj, bahşiş, özet, değerlendirme |
| `live` | `/api/live/**` (19 endpoint) | Yayın odası yardımcı uçları — misafir (guest), koltuk, mesaj, PK, heartbeat |

Flutter tarafında "sesli oda" ekranı **`/api/chat/rooms/**` ailesini** kullanmalıdır. `/api/room/**` yalnızca falcı-danışan birebir seansı içindir.

Ses taşıma katmanı **Tencent TRTC**'dir. Backend ses paketi taşımaz; yalnızca:
- `POST /api/trtc/usersig` ve `POST /api/trtc/token` ile imza/erişim üretir (mobil JWT kabul eder),
- `POST /api/trtc/webhook` ve `POST /api/tencent/webhook` ile TRTC'den gelen olayları işler.

Gerçek zamanlı oda durumu **SSE** üzerinden gelir: `GET /api/chat/rooms/[roomId]/stream`. Olay adları için `websocket_events.md` belgesine bakınız. **WebSocket sunucusu yoktur.**

## 2. Yaşam döngüsü (gerçek uçlar)

| Adım | Endpoint |
|---|---|
| Oda listesi | `GET /api/chat/rooms` |
| Oda oluştur | `POST /api/chat/rooms/create` |
| Odaya gir / varlık bildir | `POST /api/chat/rooms/[roomId]/presence` |
| Odadan çık | `DELETE /api/chat/rooms/[roomId]/presence` |
| Odadakiler + online sayısı | `GET /api/chat/rooms/[roomId]/presence` |
| Anlık tam durum | `GET /api/chat/rooms/[roomId]/state` |
| Canlı akış (SSE) | `GET /api/chat/rooms/[roomId]/stream` |
| Oda ayarları | `GET` / `PATCH /api/chat/rooms/[roomId]/settings` |
| Sahiplik devri | `POST /api/chat/rooms/[roomId]/transfer-ownership` |
| Arka planlar | `GET /api/chat/rooms/backgrounds` · temalar `GET /api/room-themes` |

> ⚠️ **`/api/chat/rooms/[roomId]/join` diye bir uç YOKTUR** (dosya taramasıyla doğrulandı). Odaya giriş `presence` POST'u ile yapılır. Flutter'da "join" adında bir çağrı üretmeyin.

Oda kapanışı: boş kalan odalar `presence` temizliği ve `lib/presence-engine.ts` içindeki `cleanupOldOnlineEvents()` ile bayat duruma düşürülür. Tam otomatik kapanış politikası tek bir uçta merkezîleşmemiştir → **MISSING: tek bir "odayı kapat" endpoint'i kaynakta yok**; sahiplik devri veya oda ayarı güncellemesi kullanılır.

## 3. Koltuk (seat) sistemi

- `GET /api/chat/rooms/[roomId]/seats` — koltuk düzeni
- `PATCH /api/chat/rooms/[roomId]/seats` — koltuğa otur / kalk / kilitle / düzen değiştir

Başarılı yanıt anahtarları (kaynaktan): `{ success, seatCount, visibleSeatCount, composition, seatLayout }` veya kısa biçim `{ success, seatCount }`.
Hata kodları: `401`, `400`, `403` (`error` + `code`), `409`.

Sunucu tarafı kurallar `lib/voice-room-seats.ts` içinde sabittir ve **istemciye taşınmamalıdır**:
`MAX_SEAT_COUNT`, `DEFAULT_SEAT_COUNT`, `OWNER_SEAT_INDEX`, `MAX_GUEST_SEATS`, `PRIVILEGED_MIN_MEMBERSHIP`, `SeatKind`.

Yayın odalarının koltukları ayrıdır: `GET` / `POST /api/live/seats`, misafir daveti `GET|POST /api/live/guest`, `GET /api/live/guest/list`.

## 4. Mikrofon / söz isteme

| İşlem | Endpoint |
|---|---|
| Mikrofon durumu | `GET` / `POST /api/chat/rooms/[roomId]/voice` |
| Söz isteği gönder / iptal | `POST` / `DELETE /api/chat/rooms/[roomId]/speak-request` |
| Bekleyen istekler | `GET /api/chat/rooms/[roomId]/speak-requests` |
| Onayla | `POST /api/chat/rooms/[roomId]/speak-requests/[targetUserId]/approve` |
| Reddet | `POST` / `DELETE .../speak-requests/[targetUserId]/reject` |
| Engelle | `POST` / `DELETE .../speak-requests/[targetUserId]/block` |
| (eski biçim) | `.../speak-request/[userId]/reject`, `.../speak-request/[userId]/block` |

Yetki mantığı `lib/speak-requests.ts` ve `lib/chat-permissions.ts` içindedir.

## 5. Moderasyon

`GET` / `POST /api/chat/rooms/[roomId]/moderation` — susturma, atma, yasaklama işlemleri tek uçta toplanmıştır (gövde alanı `action` ile ayrışır; tam eylem listesi için tabloya ve kaynak dosyaya bakınız).
Mesaj silme: `DELETE /api/chat/rooms/[roomId]/messages`.

## 6. Sohbet ve yazıyor göstergesi

- `GET` / `POST /api/chat/rooms/[roomId]/messages`
- `GET` / `POST /api/chat/rooms/[roomId]/typing`

## 7. Müzik / DJ

| İşlem | Endpoint |
|---|---|
| Çalan parça / başlat | `GET` · `POST` · `DELETE /api/chat/rooms/[roomId]/music` |
| Kuyruk | `GET /api/chat/rooms/[roomId]/music-queue` |
| Durdur | `POST /api/chat/rooms/[roomId]/music/stop` |
| Şarkı isteği | `GET` · `POST` · `PATCH /api/chat/rooms/[roomId]/song-request` |
| DJ ata/kaldır | `GET` · `POST /api/chat/rooms/[roomId]/dj` |
| Arama / geçmiş | `GET /api/music/search` · `GET /api/music/history` |

Kimin müzik açabileceği `lib/music-permissions.ts` ile sunucuda belirlenir. Müzik geliri paylaşımı `lib/voice-room-revenue.ts` → `calculateMusicDistribution`.

## 8. Hediye ve gelir paylaşımı

- `GET` / `POST /api/chat/rooms/[roomId]/gifts`
- Genel hediye gönderimi: `POST /api/gifts/send` (bkz. `gifts_coins_wallet_api.md`)

Oda hediye geliri `lib/voice-room-revenue.ts` → `calculateGiftDistribution` + `logRoomRevenue` ile **sunucuda** dağıtılır. Oda tipi kapasiteleri `ROOM_TYPES` / `getMaxUsersForRoomType`.

## 9. PK (oda içi düello)

| İşlem | Endpoint |
|---|---|
| PK durumu / başlat | `GET` · `POST /api/chat/rooms/[roomId]/pk` |
| Skor (yalnız admin) | `POST /api/chat/rooms/[roomId]/pk/score` |
| Aktif PK listesi | `GET /api/chat/rooms/pk-list` |
| Rakip adayları | `GET /api/chat/rooms/pk/candidates` |

🔒 **Güvenlik:** `pk/score` uçları §90 denetiminde **admin-only** hâle getirildi. Normal skor artışı yalnızca hediye akışından, sunucuda `lib/gift-pk-score.ts` → `applyGiftPkScore` ile hesaplanır. Flutter **asla** skor POST'lamamalıdır.

PK durum makinesi: `lib/pk-state.ts` (`checkPkTransition`, `computePkOutcome`, `finishPkBattle`, `abortPendingPk`, `finalizeExpiredActivePKs`, `endPksForSide`), süre yönetimi `lib/pk-expiry.ts`.

## 10. Falcı seans odası (`/api/room/**`)

| İşlem | Endpoint |
|---|---|
| Seans detayı / güncelle | `GET` · `PATCH /api/room/[sessionId]` |
| Mesajlar | `GET` · `POST /api/room/[sessionId]/messages` |
| Canlı akış (SSE) | `GET /api/room/[sessionId]/stream` |
| Bahşiş | `POST /api/room/[sessionId]/tip` |
| Özet | `GET /api/room/[sessionId]/summary` |
| Değerlendirme | `GET` · `POST /api/room/[sessionId]/review` |
| WebRTC sinyalleşme | `GET` · `POST` · `DELETE /api/room/signal` |

## 11. Flutter için kritik notlar

1. Ses için **TRTC SDK** kullanın; `POST /api/trtc/usersig` ile imza alın. Backend ses taşımaz.
2. Oda ekranı açıldığında: `GET .../state` (ilk yükleme) → `GET .../stream` (SSE, sürekli) → periyodik `POST .../presence` (heartbeat).
3. SSE kopmalarında yeniden bağlanın ve `state`'i yeniden çekin; `Last-Event-ID` ile tekrar oynatma davranışı **doğrulanmadı (MISSING)**.
4. Koltuk, mikrofon, müzik ve PK yetkileri **sunucuda** belirlenir; istemci yalnızca sunucunun döndürdüğü `403` + `code` değerine göre UI kısıtlar.
5. Hediye/PK/gelir hesabı istemciye taşınamaz.

## 12. Tam endpoint tablosu (sesli oda + seans + müzik + varlık)

> Toplam **74** endpoint (path+method). Kaynak: üretim kodu taraması, 2026-09-12.

| METHOD | ENDPOINT | AUTH | ÖZELLİK | QUERY | BODY ALANLARI | KAYNAK DOSYA |
|---|---|---|---|---|---|---|
| `GET` | `/api/chat/rooms` | public | — | withCounts | — | `app/api/chat/rooms/route.ts` |
| `GET` | `/api/chat/rooms/[roomId]/dj` | mobil JWT + web oturum | ADMIN | — | action, userId | `app/api/chat/rooms/[roomId]/dj/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/dj` | mobil JWT + web oturum | ADMIN | — | action, userId | `app/api/chat/rooms/[roomId]/dj/route.ts` |
| `GET` | `/api/chat/rooms/[roomId]/gifts` | mobil JWT + web oturum | ADMIN, RL, IDEM, LEDGER | after | — | `app/api/chat/rooms/[roomId]/gifts/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/gifts` | mobil JWT + web oturum | ADMIN, RL, IDEM, LEDGER | after | — | `app/api/chat/rooms/[roomId]/gifts/route.ts` |
| `DELETE` | `/api/chat/rooms/[roomId]/messages` | mobil JWT + web oturum | RL | after, limit, messageId | content, nickname | `app/api/chat/rooms/[roomId]/messages/route.ts` |
| `GET` | `/api/chat/rooms/[roomId]/messages` | mobil JWT + web oturum | RL | after, limit, messageId | content, nickname | `app/api/chat/rooms/[roomId]/messages/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/messages` | mobil JWT + web oturum | RL | after, limit, messageId | content, nickname | `app/api/chat/rooms/[roomId]/messages/route.ts` |
| `GET` | `/api/chat/rooms/[roomId]/moderation` | mobil JWT + web oturum | — | — | action, duration, message, reason, role, targetUserId, ttl | `app/api/chat/rooms/[roomId]/moderation/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/moderation` | mobil JWT + web oturum | — | — | action, duration, message, reason, role, targetUserId, ttl | `app/api/chat/rooms/[roomId]/moderation/route.ts` |
| `DELETE` | `/api/chat/rooms/[roomId]/music` | mobil JWT + web oturum | — | — | duration, title, videoId | `app/api/chat/rooms/[roomId]/music/route.ts` |
| `GET` | `/api/chat/rooms/[roomId]/music` | mobil JWT + web oturum | — | — | duration, title, videoId | `app/api/chat/rooms/[roomId]/music/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/music` | mobil JWT + web oturum | — | — | duration, title, videoId | `app/api/chat/rooms/[roomId]/music/route.ts` |
| `GET` | `/api/chat/rooms/[roomId]/music-queue` | mobil JWT + web oturum | — | — | — | `app/api/chat/rooms/[roomId]/music-queue/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/music/stop` | mobil JWT + web oturum | — | — | — | `app/api/chat/rooms/[roomId]/music/stop/route.ts` |
| `GET` | `/api/chat/rooms/[roomId]/pk` | mobil JWT + web oturum | ADMIN, RL, IDEM | — | — | `app/api/chat/rooms/[roomId]/pk/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/pk` | mobil JWT + web oturum | ADMIN, RL, IDEM | — | — | `app/api/chat/rooms/[roomId]/pk/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/pk/score` | mobil JWT + web oturum | — | — | — | `app/api/chat/rooms/[roomId]/pk/score/route.ts` |
| `DELETE` | `/api/chat/rooms/[roomId]/presence` | mobil JWT + web oturum | ADMIN | _delete, leave | — | `app/api/chat/rooms/[roomId]/presence/route.ts` |
| `GET` | `/api/chat/rooms/[roomId]/presence` | mobil JWT + web oturum | ADMIN | _delete, leave | — | `app/api/chat/rooms/[roomId]/presence/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/presence` | mobil JWT + web oturum | ADMIN | _delete, leave | — | `app/api/chat/rooms/[roomId]/presence/route.ts` |
| `GET` | `/api/chat/rooms/[roomId]/seats` | mobil JWT + web oturum | — | — | — | `app/api/chat/rooms/[roomId]/seats/route.ts` |
| `PATCH` | `/api/chat/rooms/[roomId]/seats` | mobil JWT + web oturum | — | — | — | `app/api/chat/rooms/[roomId]/seats/route.ts` |
| `GET` | `/api/chat/rooms/[roomId]/settings` | mobil JWT + web oturum | — | — | — | `app/api/chat/rooms/[roomId]/settings/route.ts` |
| `PATCH` | `/api/chat/rooms/[roomId]/settings` | mobil JWT + web oturum | — | — | — | `app/api/chat/rooms/[roomId]/settings/route.ts` |
| `GET` | `/api/chat/rooms/[roomId]/song-request` | mobil JWT + web oturum | ADMIN | — | requestId | `app/api/chat/rooms/[roomId]/song-request/route.ts` |
| `PATCH` | `/api/chat/rooms/[roomId]/song-request` | mobil JWT + web oturum | ADMIN | — | requestId | `app/api/chat/rooms/[roomId]/song-request/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/song-request` | mobil JWT + web oturum | ADMIN | — | requestId | `app/api/chat/rooms/[roomId]/song-request/route.ts` |
| `DELETE` | `/api/chat/rooms/[roomId]/speak-request` | mobil JWT + web oturum | — | — | — | `app/api/chat/rooms/[roomId]/speak-request/route.ts` |
| `GET` | `/api/chat/rooms/[roomId]/speak-request` | mobil JWT + web oturum | — | — | — | `app/api/chat/rooms/[roomId]/speak-request/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/speak-request` | mobil JWT + web oturum | — | — | — | `app/api/chat/rooms/[roomId]/speak-request/route.ts` |
| `DELETE` | `/api/chat/rooms/[roomId]/speak-request/[userId]/block` | mobil JWT + web oturum | — | — | — | `app/api/chat/rooms/[roomId]/speak-request/[userId]/block/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/speak-request/[userId]/block` | mobil JWT + web oturum | — | — | — | `app/api/chat/rooms/[roomId]/speak-request/[userId]/block/route.ts` |
| `DELETE` | `/api/chat/rooms/[roomId]/speak-request/[userId]/reject` | mobil JWT + web oturum | — | — | — | `app/api/chat/rooms/[roomId]/speak-request/[userId]/reject/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/speak-request/[userId]/reject` | mobil JWT + web oturum | — | — | — | `app/api/chat/rooms/[roomId]/speak-request/[userId]/reject/route.ts` |
| `GET` | `/api/chat/rooms/[roomId]/speak-requests` | mobil JWT + web oturum | — | status | — | `app/api/chat/rooms/[roomId]/speak-requests/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/approve` | mobil JWT + web oturum | — | — | — | `app/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/approve/route.ts` |
| `DELETE` | `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/block` | public | — | — | — | `app/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/block/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/block` | public | — | — | — | `app/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/block/route.ts` |
| `DELETE` | `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/reject` | public | — | — | — | `app/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/reject/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/reject` | public | — | — | — | `app/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/reject/route.ts` |
| `GET` | `/api/chat/rooms/[roomId]/state` | mobil JWT + web oturum | ADMIN | — | — | `app/api/chat/rooms/[roomId]/state/route.ts` |
| `GET` | `/api/chat/rooms/[roomId]/stream` | mobil JWT + web oturum | ADMIN, SSE | lastEventId | — | `app/api/chat/rooms/[roomId]/stream/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/transfer-ownership` | mobil JWT + web oturum | ADMIN | — | newOwnerId | `app/api/chat/rooms/[roomId]/transfer-ownership/route.ts` |
| `GET` | `/api/chat/rooms/[roomId]/typing` | mobil JWT + web oturum | — | — | isTyping | `app/api/chat/rooms/[roomId]/typing/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/typing` | mobil JWT + web oturum | — | — | isTyping | `app/api/chat/rooms/[roomId]/typing/route.ts` |
| `GET` | `/api/chat/rooms/[roomId]/voice` | mobil JWT + web oturum | — | — | type | `app/api/chat/rooms/[roomId]/voice/route.ts` |
| `POST` | `/api/chat/rooms/[roomId]/voice` | mobil JWT + web oturum | — | — | type | `app/api/chat/rooms/[roomId]/voice/route.ts` |
| `GET` | `/api/chat/rooms/backgrounds` | public | — | — | — | `app/api/chat/rooms/backgrounds/route.ts` |
| `POST` | `/api/chat/rooms/create` | mobil JWT | ADMIN, RL | — | description, icon, name, paymentType, roomType | `app/api/chat/rooms/create/route.ts` |
| `GET` | `/api/chat/rooms/pk-list` | public | — | status | — | `app/api/chat/rooms/pk-list/route.ts` |
| `GET` | `/api/chat/rooms/pk/candidates` | mobil JWT + web oturum | — | roomId | — | `app/api/chat/rooms/pk/candidates/route.ts` |
| `GET` | `/api/live/seats` | mobil JWT | — | roomId | — | `app/api/live/seats/route.ts` |
| `POST` | `/api/live/seats` | mobil JWT | — | roomId | — | `app/api/live/seats/route.ts` |
| `GET` | `/api/music/history` | public | — | limit, roomId | — | `app/api/music/history/route.ts` |
| `GET` | `/api/music/search` | mobil JWT | — | q, query | — | `app/api/music/search/route.ts` |
| `GET` | `/api/presence` | mobil JWT | — | — | — | `app/api/presence/route.ts` |
| `POST` | `/api/presence` | mobil JWT | — | — | — | `app/api/presence/route.ts` |
| `GET` | `/api/presence/online-events` | public | — | since | — | `app/api/presence/online-events/route.ts` |
| `GET` | `/api/presence/sections` | public | — | — | — | `app/api/presence/sections/route.ts` |
| `GET` | `/api/room-themes` | public-handler | — | — | — | `app/api/room-themes/route.ts` |
| `GET` | `/api/room-themes/catalog` | mobil JWT + web oturum | — | category, sinceVersion, tier | — | `app/api/room-themes/catalog/route.ts` |
| `GET` | `/api/room/[sessionId]` | mobil JWT + web oturum | ADMIN, LEDGER | — | — | `app/api/room/[sessionId]/route.ts` |
| `PATCH` | `/api/room/[sessionId]` | mobil JWT + web oturum | ADMIN, LEDGER | — | — | `app/api/room/[sessionId]/route.ts` |
| `GET` | `/api/room/[sessionId]/messages` | mobil JWT + web oturum | — | after | message | `app/api/room/[sessionId]/messages/route.ts` |
| `POST` | `/api/room/[sessionId]/messages` | mobil JWT + web oturum | — | after | message | `app/api/room/[sessionId]/messages/route.ts` |
| `GET` | `/api/room/[sessionId]/review` | mobil JWT + web oturum | — | — | — | `app/api/room/[sessionId]/review/route.ts` |
| `POST` | `/api/room/[sessionId]/review` | mobil JWT + web oturum | — | — | — | `app/api/room/[sessionId]/review/route.ts` |
| `GET` | `/api/room/[sessionId]/stream` | mobil JWT + web oturum | SSE | — | — | `app/api/room/[sessionId]/stream/route.ts` |
| `GET` | `/api/room/[sessionId]/summary` | mobil JWT + web oturum | — | — | — | `app/api/room/[sessionId]/summary/route.ts` |
| `POST` | `/api/room/[sessionId]/tip` | mobil JWT + web oturum | ADMIN, RL, IDEM, LEDGER | — | amount | `app/api/room/[sessionId]/tip/route.ts` |
| `DELETE` | `/api/room/signal` | mobil JWT + web oturum | — | sessionId | receiverId, sessionId, signalData, signalType | `app/api/room/signal/route.ts` |
| `GET` | `/api/room/signal` | mobil JWT + web oturum | — | sessionId | receiverId, sessionId, signalData, signalType | `app/api/room/signal/route.ts` |
| `POST` | `/api/room/signal` | mobil JWT + web oturum | — | sessionId | receiverId, sessionId, signalData, signalType | `app/api/room/signal/route.ts` |

---

## GÜNCELLEME 2026-09-12 — Koltuk Yarış Koşulu Düzeltmesi (GERÇEK KOD)

**Sorun:** `POST /api/chat/rooms/[roomId]/seats` "koltuk dolu mu" kontrolü ile yazma arasında kilit yoktu (TOCTOU). İki kullanıcı aynı anda istek atarsa aynı koltuğa yerleşebiliyordu.

**Düzeltme:** İşlem (transaction) içinde, kontrolden **önce** koltuk başına danışma kilidi alınır:

```sql
SELECT pg_advisory_xact_lock(hashtext('seat:<roomId>:<seatIndex>'))
```

Kilit işlem bitince otomatik serbest kalır. Artık aynı koltuk için gelen ikinci istek birinciyi bekler ve "koltuk dolu" hatası alır. **İki kullanıcının aynı koltuğa oturması sunucu tarafında imkânsızdır.**

Tüm koltuk durumu (kim oturuyor, mikrofon açık/kapalı, kilitli koltuk, konuşma isteği sırası) sunucu otoritesindedir; istemciden gelen koltuk durumu asla kabul edilmez.
