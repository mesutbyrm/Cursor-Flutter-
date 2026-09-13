# BÖLÜM 22 — Multi-Guest · PK/Battle · Hediye Kutusu · Flutter API Sözleşmesi

Sürüm: 2026-09-12 · Durum: backend tamamlandı, 29/29 kabul senaryosu geçti.
Bu doküman **backend kodunu okumadan** Flutter tarafını yazabilmen için hazırlandı.
Mevcut `ENDPOINTS.md`, `AUTHENTICATION.md`, `REALTIME.md` dosyalarını **tamamlar**, değiştirmez.

> Bu bölümdeki uçların **web arayüzü tüketicisi yoktur**; yalnızca mobil istemci içindir.

---

## 1. Kimlik doğrulama

Tüm uçlar oturum çerezi (NextAuth) ile korunur. Mobil istemci giriş akışını mevcut
`AUTHENTICATION.md` dosyasındaki `credentials` akışıyla yapar ve dönen çerezi **tüm** isteklerde
(`Cookie` başlığı) ve SSE bağlantısında gönderir. Bearer token bu uçlarda **çalışmaz**.

Oturumsuz istek: `401` + `{"error": "...", "code": "UNAUTHORIZED"}`.

### Hata gövdesi (ortak sözleşme)
```json
{ "error": "Kullanıcıya gösterilecek Türkçe mesaj", "code": "MAKINE_KODU", "...ek alanlar": "..." }
```
`code` alanı **her zaman** vardır ve istemci mantığı buna göre yazılmalıdır; `error` yalnızca gösterim içindir.

### Hız limiti
`429` + `{"code": "RATE_LIMITED", "retryAfterSec": n}`.
Limitler: misafir işlemleri 6/dk, hediye kutusu oluşturma 5/dk, kutuya katılma 20/dk.

---

## 2. Multi-Guest (canlı yayında çoklu misafir)

Tek uç: **`POST /api/live/guest`** — gövdedeki `action` alanı işlemi belirler.
Liste: **`GET /api/live/guest/list?streamId=...`**

### 2.1 Action tablosu

| action | Kim çağırır | Zorunlu alanlar | Sonuç |
|---|---|---|---|
| `request` | İzleyici | `streamId` | Yayıncıya misafirlik talebi |
| `cancel_request` | Talep sahibi | `streamId` | Kendi talebini geri çeker |
| `approve` | Host/moderatör | `streamId`, `requestId` | Talebi kabul eder, slot atar |
| `reject` | Host/moderatör | `streamId`, `requestId` | Talebi reddeder |
| `invite` | Host/moderatör | `streamId`, `userId` | Kullanıcıyı davet eder |
| `respond` | Davet edilen | `streamId`, `inviteId`, `accept` | Daveti kabul/ret |
| `cancel` | Host | `streamId`, `inviteId` | Daveti iptal eder |
| `join` | Onaylı misafir | `streamId` | Misafir alanına çıkar |
| `leave` | Misafir | `streamId` | Misafirlikten ayrılır |
| `kick` / `remove` | Host/moderatör | `streamId`, `guestId` | Misafiri çıkarır (cooldown başlar) |
| `mute` | Host/moderatör **veya** misafirin kendisi | `streamId`, `muted`, (host ise `guestId`) | Mikrofon |
| `camera` | aynı | `streamId`, `videoOff`, (host ise `guestId`) | Kamera |
| `move` | Host/moderatör | `streamId`, `guestId`, `slot` | Belirli slota taşı |
| `move_up` / `move_down` | Host/moderatör | `streamId`, `guestId` | Sırayı bir kaydır |

**Yetki kuralı (§31):** host bir misafiri susturduğunda `mutedByHost=true` olur ve misafir
kendi kendine açamaz → `403 GUEST_NOT_AUTHORIZED`. Kamera için `videoOffByHost` aynı şekilde çalışır.
Misafir kendi kapatıp kendi açabilir; host kapattıysa yalnızca host açar.

### 2.2 Guest state modeli

```dart
class GuestSession {
  String userId, name, username;
  String? image;
  int slot;              // 1..maxGuests
  String status;         // pending | active | left | removed
  bool isMuted;          // efektif mikrofon durumu
  bool mutedByHost;      // true ise misafir kendisi açamaz
  bool isVideoOff;
  bool videoOffByHost;
}
```

Durum geçişleri:
```
(yok) --request--> pending --approve--> active --leave--> left
                     |                     |
                  reject                  kick
                     v                     v
                 (silinir)              removed --(cooldown)--> request tekrar
```

### 2.3 Liste yanıtı — `GET /api/live/guest/list?streamId=...`
```json
{
  "guests": [ /* GuestSession[] */ ],
  "count": 3,
  "maxGuests": 8,
  "gridSlots": 4,
  "pendingCount": 1,
  "pendingRequests": [ { "id": "...", "userId": "...", "name": "...", "createdAt": "..." } ],
  "me": { "status": "active", "slot": 2, "isMuted": false }
}
```
`gridSlots` backend tarafından hesaplanır (1/2/4/6/8-lik ızgara) — istemci **kendi hesaplamamalıdır**.

### 2.4 Hata kodları (Multi-Guest)

| Kod | HTTP | Anlamı |
|---|---|---|
| `GUEST_REQUEST_EXPIRED` | 409 | Talep süresi doldu |
| `GUEST_REQUEST_NOT_FOUND` | 404 | Talep/davet yok |
| `GUEST_REQUEST_ALREADY_RESOLVED` | 409 | Zaten kabul/ret edilmiş |
| `GUEST_ALREADY_JOINED` | 409 | Zaten misafir |
| `GUEST_ALREADY_REQUESTED` | 409 | Bekleyen talebi var |
| `GUEST_SLOT_FULL` | 409 | Kontenjan dolu |
| `GUEST_SLOT_TAKEN` | 409 | Hedef slot dolu |
| `GUEST_NOT_AUTHORIZED` | 403 | Yetki yok (host kilidi dahil) |
| `GUEST_NOT_APPROVED` | 403 | Onay almadan `join` denendi |
| `GUEST_NOT_FOUND` | 404 | Misafir kaydı yok |
| `GUEST_DISABLED` | 403 | Bu yayında misafirlik kapalı |
| `GUEST_REMOVED_COOLDOWN` | 429 | Çıkarıldı; `retryAfterSec` kadar bekle |
| `GUEST_BANNED` | 403 | Hesap banlı |
| `GUEST_ACCOUNT_INACTIVE` | 403 | Hesap dondurulmuş |
| `STREAM_NOT_FOUND` / `STREAM_ENDED` | 404 / 409 | Yayın yok/bitti |
| `VALIDATION_ERROR` | 400 | Eksik/hatalı alan |

---

## 3. PK / Battle

İki ayrı uç vardır:

* **Yayın ↔ yayın PK:** `POST /api/video-streams/pk` · `GET /api/video-streams/pk?streamId=...`
* **Oda içi PK:** `POST /api/chat/rooms/{roomId}/pk` · `GET /api/chat/rooms/{roomId}/pk`

### 3.1 Action tablosu

| action | Uç | Alanlar | Not |
|---|---|---|---|
| `create` | her ikisi | `streamId`/`targetStreamId` veya `targetRoomId`, `duration` | Davet üretir (`pending`) |
| `create_user` | yalnız oda | `side1UserIds[]`, `side2UserIds[]`, `duration`, `countdownSec` (0-30) | Aynı oda içinde kullanıcı-vs-kullanıcı; onay gerekmez, `starting`→`active` |
| `accept` | her ikisi | `battleId` | Yalnız karşı taraf; `active` yapar |
| `reject` / `cancel` | her ikisi | `battleId` | |
| `start` | her ikisi | `battleId` | Geri sayımı bitirip başlatır |
| `pause` / `resume` | her ikisi | `battleId` | `resume` bitiş saatini duraklama kadar öteler |
| `end` | her ikisi | `battleId` | Kazananı **backend** belirler |
| `participants` | yayın PK | `battleId` | Taraf listesi |

`duration` backend'de admin limitlerine göre kırpılır (varsayılan 180 sn, 60–600).

### 3.2 PK state modeli

```dart
class PkBattle {
  String id, status;        // pending|starting|active|paused|completed|cancelled|rejected|expired
  String mode;              // "1v1" | "1v2" | "2v2" ...
  String scope;             // stream | room | room_user
  String? scopeRoomId, stream1Id, stream2Id, user1Id, user2Id, winnerId;
  int score1, score2, duration, pausedMs;
  DateTime? startedAt, endsAt, pausedAt, acceptedAt, endedAt;
  List<PkParticipant> participants; // userId, side(1|2), points, isCaptain, seatNumber
  String serverNow;         // saat farkı düzeltmesi için
}
```

Geçişler:
```
pending ──accept──> active ──pause──> paused ──resume──> active ──end──> completed
   │  └─reject/cancel/expire──> rejected|cancelled|expired
starting ──(countdown)──> active
```
Kalan süre hesabı: `endsAt - serverNow` (cihaz saatini kullanma).

### 3.3 Skor

* PK sırasında gelen **her hediye** otomatik olarak alıcının tarafına puan yazar (`source: "gift"`).
* Hediye **kutusu** ödülleri PK skoru **üretmez** (`source: gift_box|bonus_reward` hariç tutulur).
* Manuel skor müdahalesi yalnız admin/superadmin: `POST /api/chat/rooms/{roomId}/pk/score`
  veya `POST /api/live/pk/score` — `{battleId, amount, side}`; `amount` admin limitine (varsayılan 10) kırpılır.
* Kazanan yalnız `end` sırasında backend tarafından yazılır; istemci hesaplamaz.

### 3.4 PK hata kodları

| Kod | HTTP | Anlamı |
|---|---|---|
| `PK_ALREADY_ACTIVE` | 409 | Bu yayında/odada zaten açık PK var |
| `PK_NOT_FOUND` | 404 | PK yok |
| `PK_REQUEST_EXPIRED` | 409 | Davet süresi doldu |
| `PK_NOT_ALLOWED` | 403 | PK bu kapsamda kapalı ya da yetki yok |
| `PK_INVALID_STATUS` | 409 | Mevcut durumdan bu geçiş yapılamaz |
| `VALIDATION_ERROR` | 400 | Eksik/hatalı alan |
| `UNAUTHORIZED` | 401 | Oturum yok |

---

## 4. Hediye Kutusu (Gift Box)

| Uç | Metot | Açıklama |
|---|---|---|
| `/api/gift-box?streamId=...` veya `?roomId=...` | GET | Aktif kutular + `me` + `limits` |
| `/api/gift-box` | POST `action:"create"` | Kutu açar (jeton **emanete** alınır) |
| `/api/gift-box` | POST `action:"cancel"` | Yalnız sahibi; kullanılmayan jeton iade |
| `/api/gift-box/{boxId}` | GET | Tek kutu + kazanan listesi (yeniden senkron) |
| `/api/gift-box/{boxId}/join` | POST (boş gövde) | Göreve bakar, kazananı belirler, ödülü öder |
| `/api/gift-box/share` | POST | `{scope, targetId, channel}` — paylaşım görevi kaydı |

### 4.1 Oluşturma gövdesi
```json
{
  "action": "create",
  "streamId": "...",            // veya "roomId"
  "totalAmount": 100,           // min/max admin ayarı (varsayılan 10 – 100000)
  "winnerCount": 10,            // max 100
  "durationSec": 60,            // izinli değerler: 5,10,15,30,60,120
  "taskType": "none",           // none | follow_creator | follow_broadcaster | follow_user | share
  "taskTargetUserId": "..."     // yalnız follow_user
}
```
Paylar backend'de hesaplanır (`splits`): taban pay + kalan ilk kişilere +1 → **toplam daima `totalAmount`**.

### 4.2 Kutu state modeli
```dart
class GiftBox {
  String id, scope, status;    // active | finished | expired | cancelled
  String? streamId, roomId;
  String creatorId;
  int totalAmount, winnerCount, durationSec;
  List<int> splits;
  String taskType; String? taskTargetUserId;
  DateTime startsAt, endsAt; DateTime? finishedAt, settledAt;
  int paidCount, paidAmount, refundedAmount;
  int remainingSec, remainingWinners, remainingAmount; // sunucudan gelir
}
```
```
active ──kontenjan dolunca──> finished
   ├──süre dolunca──> expired   (kullanılmayan jeton sahibine iade)
   └──sahibi iptal──> cancelled (kullanılmayan jeton sahibine iade)
```
Kapanış **tek seferliktir** (`settledAt` kilidi): çift iade/çift ödül imkânsız.

### 4.3 Katılma yanıtı
Başarılı: `200`
```json
{ "success": true, "isWinner": true, "rank": 3, "rewardAmount": 10, "remainingWinners": 7 }
```
Kazanan seçimi atomiktir: 12 kişi aynı anda katılsa bile tam `winnerCount` kadar kazanan olur,
dağıtılan toplam `totalAmount`'u asla aşmaz (kabul testiyle doğrulandı).

### 4.4 Kutu hata kodları

| Kod | HTTP | Anlamı |
|---|---|---|
| `GIFT_BOX_NOT_FOUND` | 404 | Kutu yok |
| `GIFT_BOX_NOT_ACTIVE` | 409 | Kapanmış kutu |
| `GIFT_BOX_EXPIRED` | 409 | Süresi dolmuş |
| `GIFT_BOX_FULL` | 409 | Kontenjan doldu |
| `GIFT_BOX_ALREADY_JOINED` | 409 | Zaten katıldı |
| `GIFT_BOX_TASK_INCOMPLETE` | 403 | Görev tamamlanmadı (`taskType`, `reason` alanları gelir) |
| `GIFT_BOX_OWNER_CANNOT_JOIN` | 403 | Sahibi katılamaz |
| `GIFT_BOX_ALREADY_OPEN` | 409 | Aynı yayında/odada açık kutusu var (`boxId` döner) |
| `GIFT_BOX_NOT_IN_ROOM` | 403 | Odada/yayında değil |
| `GIFT_BOX_BANNED` / `GIFT_BOX_ACCOUNT_INACTIVE` | 403 | Hesap uygun değil |
| `GIFT_BOX_NOT_AUTHORIZED` | 403 | Yalnız sahibi iptal edebilir |
| `INSUFFICIENT_BALANCE` | 400 | Bakiye yetersiz |
| `STREAM_NOT_FOUND` / `STREAM_ENDED` / `ROOM_NOT_FOUND` | 404/409 | Hedef yok |
| `VALIDATION_ERROR` | 400 | Eksik/hatalı alan |

---

## 5. Gerçek zamanlı olaylar (SSE)

Mevcut akışlar kullanılır — yeni bağlantı açmaya gerek yok:

* Yayın: `GET /api/video-streams/{streamId}/stream` (tüm olay tipleri geçer)
* Oda: `GET /api/chat/rooms/{roomId}/stream` (olaylar **tipe göre** filtrelenir; `gift_box` ve `pk` dahildir)

Her olay `{ "type": "...", ... }` gövdesiyle gelir.

### 5.1 Misafir olayları (`type: "guest"`)

`guest_request_created` · `guest_request_accepted` · `guest_request_rejected` · `guest_request_cancelled` ·
`guest_invited` · `guest_joined` · `guest_left` · `guest_removed` · `guest_muted` · `guest_camera_off` ·
`guest_position_changed` · `guest_updated` · `guest_grid_changed`

Liste değiştiren olaylar tam listeyi taşır:
```json
{
  "type": "guest", "event": "guest_joined", "streamId": "...",
  "count": 3, "maxGuests": 8, "gridSlots": 4,
  "guests": [ /* GuestSession[] */ ], "guestId": "..."
}
```
Talep olayları küçük yüklüdür (liste taşımaz):
```json
{ "type": "guest", "event": "guest_request_created", "streamId": "...", "requestId": "...", "userId": "...", "pendingCount": 2 }
```

### 5.2 PK olayları (`eventType`)

`PK_STARTING` · `PK_STARTED` · `PK_SCORE` · `PK_PAUSED` · `PK_RESUMED` · `PK_ENDED` ·
`PK_REQUEST_REJECTED` · `PK_REQUEST_CANCELLED` · `PK_EXPIRED`

```json
{
  "eventType": "PK_STARTED", "battleId": "...",
  "room1Id": "...", "room2Id": "...", "user1Id": "...", "user2Id": "...",
  "score1": 0, "score2": 0, "duration": 180, "status": "active",
  "startedAt": "...", "endsAt": "...", "serverNow": "..."
}
```
```json
{ "eventType": "PK_SCORE", "battleId": "...", "score1": 120, "score2": 90, "side": 1, "points": 30, "source": "gift" }
```
Eski istemciler için bazı olaylarda ayrıca `action: "score_update"` alanı bulunur (geriye dönük uyum).

### 5.3 Hediye kutusu olayları (`type: "gift_box"`)

`gift_box_created` · `gift_box_started` · `gift_box_joined` · `gift_box_task_verified` ·
`gift_box_winner` · `gift_box_reward_distributed` · `gift_box_finished` · `gift_box_expired` · `gift_box_cancelled`

```json
{ "type": "gift_box", "event": "gift_box_winner", "boxId": "...", "scope": "stream",
  "userId": "...", "rank": 3, "rewardAmount": 10, "remainingWinners": 7 }
```
```json
{ "type": "gift_box", "event": "gift_box_expired", "boxId": "...", "scope": "room",
  "paidCount": 4, "paidAmount": 40, "refunded": 60 }
```

---

## 6. Yeniden bağlanma / senkronizasyon (§26)

Bağlantı koptuğunda **tek istek** ile tüm durumu tazele:

* `GET /api/video-streams/{streamId}/sync`
```json
{
  "stream": { "...": "...", "serverNow": "2026-09-12T22:40:00.000Z" },
  "guests": { "items": [ /* GuestSession[] */ ], "maxGuests": 8 },
  "pk": null,
  "giftBoxes": [ /* GiftBox[] */ ]
}
```
* `GET /api/chat/rooms/{roomId}/sync` → `{ "room": {...}, "pk": {...}, "giftBoxes": [...] }`

Önerilen akış: SSE `onDisconnect` → yeniden bağlan → `sync` çağır → yerel durumu **tamamen** değiştir.

---

## 7. Kapanış davranışı (§27)

Yayın veya oda kapandığında backend otomatik olarak:
aktif misafir oturumlarını kapatır, açık PK'ları sonlandırır ve açık hediye kutularını
kapatıp kullanılmayan jetonu sahibine iade eder. İstemcinin ek çağrı yapması gerekmez;
ilgili SSE olayları (`guest_left`, `PK_ENDED`, `gift_box_cancelled/expired`) gelir.

---

## 8. Admin tarafından ayarlanabilen limitler

İstemci bu değerleri **sabit kodlamamalı**; `GET /api/live/guest/list` (`maxGuests`) ve
`GET /api/gift-box` (`limits`) yanıtlarından okumalıdır.

| Grup | Anahtarlar |
|---|---|
| Multi-Guest | maks. misafir, cooldown, talep süresi, misafirlik açık/kapalı |
| PK | varsayılan/min/maks süre, cooldown, maks manuel puan, taraf başına maks katılımcı, yayın/oda PK açık-kapalı |
| Hediye kutusu | min/maks tutar, maks kazanan, min/maks süre, izinli süreler, ek görev tipleri |

---

## 9. Kabul testi

Backend tarafında 29 senaryoluk otomatik kabul testi bulunur ve **29/29 geçmektedir**:
misafir talep/onay/moderasyon akışı, 8'lik ızgara ve kontenjan koruması, yayın ve oda PK'sı,
duraklat/devam, hediye→skor akışı, 12 eşzamanlı katılımda tam kazanan sayısı,
görev doğrulama (takip/paylaşım), süre dolumu ve iptalde jeton iadesi, senkronizasyon uçları,
kapanış temizliği, jeton korunumu ve hediye kutusunun PK skoru üretmemesi.
