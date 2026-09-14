# CanlıFal — PK (Battle) Entegrasyon Sözleşmesi (Flutter)

Sürüm: 2026-09-14 · Backend: `https://canlifal.com`

Bu belge, **sesli sohbet odaları** ve **canlı yayınlar** için PK (kapışma) sisteminin tam API sözleşmesidir. BÖLÜM 22 (`BOLUM22_MULTIGUEST_PK_GIFTBOX.md`) belgesinin PK bölümünün güncellenmiş ve genişletilmiş hâlidir; çakışma olursa **bu belge geçerlidir**.

---

## 0. Bu sürümde değişenler (backend düzeltmesi)

| Konu | Eski davranış | Yeni davranış |
|---|---|---|
| Yayın kimliği | Sadece `VideoStream.id` kabul ediliyordu; `roomId` gönderilirse `"Aktif yayınınız bulunamadı"` | Hem `id` hem `roomId` kabul edilir, sunucu kanonik `id`'ye çözer |
| Hata ayrımı | Tüm hatalar tek mesaj | 5 ayrı kod: `STREAM_NOT_FOUND`, `NOT_STREAM_OWNER`, `STREAM_NOT_LIVE`, `TARGET_NOT_FOUND`, `TARGET_NOT_LIVE` |
| `/api/live/pk` | İki taraf da aynı türde olmak zorundaydı (ikisi oda veya ikisi yayın) | Her taraf **bağımsız** çözülür → oda↔oda, yayın↔yayın ve **karışık oda↔yayın** PK desteklenir |
| Web "yayına başla" | Dönen zarf (`{success,data}`) açılmıyordu → `broadcast/undefined` | Zarf açılıyor, doğru yayın kimliğine yönlendiriliyor |

> **Flutter tarafı için sonuç:** elinizde hangi kimlik varsa (`stream.id` veya `stream.roomId`) onu gönderebilirsiniz. Yine de **tercih edilen** `id` alanıdır.

---

## 1. Kimlik doğrulama

Tüm PK uçları mobil JWT ister:

```
Authorization: Bearer <accessToken>
Content-Type: application/json
```

401 → `UNAUTHORIZED`. Token yenileme akışı BÖLÜM 22 §1 ile aynıdır.

### Hız limiti
`pk_create` kovası. Aşılırsa **429**:
```json
{ "success": false, "error": { "code": "RATE_LIMITED", "message": "Çok fazla istek gönderdiniz, lütfen biraz bekleyin" } }
```
Flutter: 429 alınca butonu 30 sn kilitleyin, otomatik retry **yapmayın**.

### Özellik bayrağı
`PK_ENABLED` kapalıysa tüm PK uçları hata döner. Uygulama açılışında bir kez kontrol edip PK butonlarını gizleyebilirsiniz.

### Idempotency
`create` uçları idempotent koruma ile korunur. Aynı isteği tekrar göndermek yeni PK açmaz, önceki yanıtı döndürür.

---

## 2. Uç nokta haritası

| Amaç | Uç | Yöntem | Not |
|---|---|---|---|
| **Birleşik PK (önerilen mobil yol)** | `/api/live/pk` | GET, POST | Oda **ve** yayın; zarflı yanıt |
| Aktif PK listesi | `/api/live/pk/active` | GET | `?roomId=` / `?streamId=`, `?includePending=1` |
| Skor (yalnız admin) | `/api/live/pk/score` | POST | Hediyeler skoru otomatik işler; normal kullanıcı çağırmaz |
| Sesli oda PK | `/api/chat/rooms/{roomId}/pk` | GET, POST | `create_user`, `start/pause/resume` gibi ekstra action'lar burada |
| Sesli oda aday listesi | `/api/chat/rooms/pk/candidates?roomId=` | GET | |
| Yayın PK | `/api/video-streams/pk` | GET, POST | Web ile ortak; düz (zarfsız) yanıt |
| Yayın aday listesi | `/api/video-streams/pk/candidates?streamId=` | GET | |
| Yayın PK alias | `/api/video-streams/{streamId}/pk-battle` | GET, POST | Yalnız mobil JWT |

**Tavsiye:** Flutter'da tek bir `PkService` yazın ve **`/api/live/pk`** kullanın. Oda mı yayın mı olduğunu backend çözer. Yalnızca oda-içi kullanıcı-vs-kullanıcı PK (`create_user`) ve `pause/resume` için `/api/chat/rooms/{roomId}/pk` gerekir.

---

## 3. `/api/live/pk` — birleşik uç

### 3.1 GET — mevcut PK durumu

```
GET /api/live/pk?roomId=<oda veya yayın kimliği>
```

Başarı (PK yoksa):
```json
{ "success": true, "data": null }
```

Başarı (PK varsa):
```json
{
  "success": true,
  "data": {
    "id": "cmu1...",
    "status": "active",
    "room1Id": "cmop...",
    "room2Id": "cmtv...",
    "user1Id": "cmok...",
    "user2Id": "cmok...",
    "score1": 120,
    "score2": 80,
    "duration": 180,
    "startedAt": "2026-09-14T22:10:00.000Z",
    "endedAt": "",
    "winnerId": "",
    "createdAt": "2026-09-14T22:09:30.000Z",
    "user1": { "id": "...", "name": "Ada", "image": "https://www.oryan.com/wp-content/uploads/ADA-article.jpg" },
    "user2": { "id": "...", "name": "Mert", "image": "" }
  }
}
```

> Boş alanlar `null` değil **boş string / 0** döner. Dart modelinde `String` olarak karşılayın.
> Biten PK'lar bitişten sonra **5 dakika** daha bu uçta görünür (sonuç ekranı için).

Hatalar: `MISSING_ROOM_ID` (400), `INTERNAL_ERROR` (500).

### 3.2 POST — action tablosu

Ortak gövde alanı: `action`.

| action | Zorunlu alanlar | Kim çağırabilir | Başarı verisi |
|---|---|---|---|
| `create` | `roomId`, `targetRoomId`, (ops.) `duration` | Kaynak oda/yayın **sahibi** | `{id, status:'pending', room1Id, room2Id, duration}` |
| `accept` | `battleId` | `user2` veya hedef oda sahibi | `{id, status:'active', startedAt, endTime, score1, score2}` |
| `reject` | `battleId` | PK'nın iki tarafından biri | `{id, status:'rejected'}` |
| `cancel` | `battleId` | PK'nın iki tarafından biri | `{id, status:'cancelled'}` |
| `end` | `battleId` | PK'nın iki tarafından biri | `{id, status:'completed', score1, score2, winnerId}` |

#### create — istek
```json
{
  "action": "create",
  "roomId": "cmop292m2005vnv08mx81j1hn",
  "targetRoomId": "cmtvdbrsa0134oz08gkz238ae",
  "duration": 180
}
```
`roomId` / `targetRoomId` şunlardan biri olabilir:
- `ChatRoom.id` (sesli oda)
- `VideoStream.id` (canlı yayın)
- `VideoStream.roomId` (canlı yayının alternatif kimliği)

İki taraf **farklı türde** olabilir (oda ↔ yayın).

#### create — yanıt
```json
{ "success": true, "data": { "id": "cmu1sqbg2008l...", "status": "pending", "room1Id": "...", "room2Id": "...", "duration": 180 } }
```

#### create — hata kodları

| HTTP | code | Anlam | Flutter davranışı |
|---|---|---|---|
| 400 | `MISSING_PARAMS` | roomId/targetRoomId yok | geliştirici hatası |
| 404 | `ROOM_NOT_FOUND` | Kaynak oda/yayın hiç yok | Sayfayı yenile |
| 403 | `NOT_OWNER` | Sahibi değilsiniz | Butonu gizle (ör. misafir/co-host) |
| 400 | `ROOM_INACTIVE` | Odanız kapalı / yayınınız bitmiş | "Yayınınız kapanmış, tekrar başlatın" |
| 404 | `TARGET_NOT_FOUND` | Hedef yok | Aday listesini yenile |
| 400 | `TARGET_INACTIVE` | Hedef kapandı | Aday listesini yenile |
| 400 | `SELF_PK` | Kendinizle PK | Aday listesinden kendi odalarınızı filtreleyin |
| 409 | `PK_EXISTS` | Taraflardan biri zaten PK'da | "Zaten aktif bir PK var" |
| 429 | `RATE_LIMITED` | Hız limiti | Butonu kilitle |

#### accept / reject / cancel / end — hata kodları

| HTTP | code | Anlam |
|---|---|---|
| 400 | `MISSING_BATTLE_ID` | battleId yok |
| 404 | `PK_NOT_FOUND` | PK bulunamadı |
| 400 | `PK_NOT_PENDING` | Zaten kabul/red edilmiş |
| 400 | `PK_EXPIRED` | 60 sn davet süresi doldu |
| 403 | `NOT_AUTHORIZED` | Yetkisiz |
| 400 | `PK_NOT_ACTIVE` | `end` için PK aktif değil |
| 400 | `INVALID_ACTION` | Bilinmeyen action |

---

## 4. `/api/chat/rooms/{roomId}/pk` — sesli oda uçları

Yanıtlar **zarfsız**: başarıda doğrudan `PKBattle` nesnesi, hatada `{ "error": "..." }` (bazılarında ayrıca `code`).

### 4.1 GET
```
GET /api/chat/rooms/{roomId}/pk
```
Odaya ait canlı PK'yı, katılımcı listesini ve sunucu saatini döner. Zaman senkronu için `serverNow` alanını kullanın (cihaz saatine güvenmeyin).

### 4.2 POST action tablosu

| action | Zorunlu alanlar | Yetki | Açıklama |
|---|---|---|---|
| `create` | `targetRoomId`, (ops.) `duration` | oda sahibi | Oda ↔ oda daveti |
| `create_user` | `side1UserIds[]` + `side2UserIds[]` **veya** `opponentUserId`; (ops.) `countdownSec` (0–30, vars. 5), `duration` | oda sahibi / oda moderatörü-admini / platform moderatörü | **Aynı oda içinde** kullanıcı(lar) vs kullanıcı(lar). Taraf başına en fazla **4** kişi. Davet yok, geri sayımla direkt başlar |
| `accept` | `battleId` | `user2` veya hedef oda sahibi/moderatörü | |
| `reject` | `battleId` | yalnız davet edilen (`user2`) | |
| `cancel` | `battleId` | yalnız daveti gönderen (`user1`) | |
| `start` | `battleId` | taraflar / oda mod-admin / platform mod | `starting` → `active` |
| `pause` | `battleId` | aynı | `active` → `paused` |
| `resume` | `battleId` | aynı | `paused` → `active` |
| `end` | `battleId` | taraflar veya iki odanın mod/admin'i | Kazananı hesaplar, `completed` |

#### create_user gövdesi
```json
{
  "action": "create_user",
  "side1UserIds": ["u1", "u2"],
  "side2UserIds": ["u3", "u4"],
  "duration": 180,
  "countdownSec": 5
}
```
Kısayol (1'e 1, çağıran kişi 1. taraf):
```json
{ "action": "create_user", "opponentUserId": "u3" }
```

#### create_user kuralları
- Tüm katılımcılar **o anda odada** olmalı (aksi hâlde 400 + `missing: [userId...]`).
- Bir kullanıcı iki tarafta birden olamaz → 400.
- Taraf başına max 4 → 400.
- Odada veya katılımcılarda canlı PK varsa → **409**.
- Koltuk durumu **değiştirilmez**, yalnız okunur.
- Yanıt: `{...battle, participants, countdownSec}`; `mode` alanı `1v1`, `2v2` gibi otomatik türetilir; `scope: "room_user"`, `scopeRoomId: roomId`.

#### Oda PK'sı yaygın hata metinleri (zarfsız)
| HTTP | `error` | Anlam |
|---|---|---|
| 400 | `Oda aktif değil` | oda kapalı |
| 403 | `Oda içi PK başlatma yetkiniz yok` | yetki |
| 400 | `side1UserIds ve side2UserIds gerekli` | eksik gövde |
| 400 | `Bir tarafta en fazla 4 kullanıcı olabilir` | limit |
| 400 | `Bir kullanıcı aynı anda iki tarafta olamaz` | çakışma |
| 400 | `Bazı kullanıcılar odada bulunmuyor` | + `missing[]` |
| 400 | `Taraflardan biri zaten bir PK'da` | meşgul |
| 409 | `Bu odada veya katılımcılarda zaten aktif bir PK var` | meşgul |
| 400 | `PK isteği zaman aşımına uğradı (60 saniye)` | davet süresi doldu |
| 409 | `PK durumu değişti, tekrar deneyin` | iyimser kilit çakışması → GET ile durumu yenileyin |
| 400 | `Bu işlem yapılamaz: PK durumu "...", "..." olamaz` | geçersiz durum geçişi |
| 403 | `Yetkiniz yok` | yetki |
| 404 | `PK bulunamadı` | |

---

## 5. `/api/video-streams/pk` — yayın uçları (web ile ortak)

Zarfsız yanıt. `streamId` ve `targetStreamId` alanları hem `VideoStream.id` hem `VideoStream.roomId` kabul eder.

### create
```json
{ "action": "create", "streamId": "...", "targetStreamId": "...", "duration": 180 }
```
Başarı: doğrudan `PKBattle` nesnesi (`id`, `stream1Id`, `stream2Id`, `user1Id`, `user2Id`, `score1`, `score2`, `status: "pending"`, `duration`, ...).

### Hata kodları (yeni)
| HTTP | code | Mesaj |
|---|---|---|
| 404 | `STREAM_NOT_FOUND` | Yayınınız bulunamadı (geçersiz yayın kimliği). Sayfayı yenileyip tekrar deneyin. |
| 403 | `NOT_STREAM_OWNER` | Sadece yayın sahibi PK başlatabilir |
| 400 | `STREAM_NOT_LIVE` | Aktif yayınınız bulunamadı (yayın kapanmış) |
| 404 | `TARGET_NOT_FOUND` | Hedef yayın bulunamadı |
| 400 | `TARGET_NOT_LIVE` | Hedef yayın aktif değil |

Diğer action'lar: `accept`, `reject`, `cancel`, `start`, `pause`, `resume`, `end`, `participants`.

### Alias
`POST /api/video-streams/{streamId}/pk-battle` aynı `create/accept/...` action'larını kabul eder ve **yalnız mobil JWT** ile çalışır. Aynı kimlik çözümlemesi (id veya roomId) burada da geçerlidir.

---

## 6. Aday listeleri

### Yayın adayları
```
GET /api/video-streams/pk/candidates?streamId=<kendi yayınınız>
```
```json
{
  "candidates": [
    { "streamId": "...", "userId": "...", "name": "Mert", "image": "https://yt3.googleusercontent.com/fHMwKyk_Rv60QRps82bgtzwtLmpMNZ2xL9_jmqlEjMxuB2jFHVqqz2DC2Dwa-wHa-GoMqzXEtvk=s900-c-k-c0x00ffffff-no-rj",
      "title": "Akşam yayını", "viewers": 42, "startedAt": "2026-09-14T21:00:00.000Z" }
  ],
  "selfBusy": false,
  "total": 1
}
```
Sunucu garantileri: yalnız **canlı** yayınlar, kendi yayınınız hariç, PK'da olan yayın/kullanıcı hariç, yayıncı başına tek kayıt.

### Oda adayları
```
GET /api/chat/rooms/pk/candidates?roomId=<kendi odanız>
```
Yalnız **aktif** ve **sahibi olan** odalar; sahibi son **2 dakikada** odada görünmüş olmalı; PK'da olan oda/sahip hariç; sahip başına tek kayıt.

> `selfBusy: true` ise PK butonunu pasifleştirin.

---

## 7. PK durum makinesi

```
pending ──accept──▶ active ──pause──▶ paused ──resume──▶ active
   │                   │                              │
   │                   └──────── end / süre bitti ─────┴──▶ completed
   ├─ reject ─▶ rejected
   ├─ cancel ─▶ cancelled
   └─ 60 sn ──▶ expired

starting ──▶ active | cancelled | expired      (yalnız create_user akışı)
```

**İzinli geçişler (sunucu kanonik):**

| Mevcut | İzinli hedefler |
|---|---|
| `pending` | `starting`, `active`, `rejected`, `cancelled`, `expired` |
| `starting` | `active`, `cancelled`, `expired` |
| `active` | `paused`, `completed` |
| `paused` | `active`, `completed` |
| `completed` / `cancelled` / `rejected` / `expired` | — (terminal) |

Canlı sayılan durumlar: `pending`, `starting`, `active`, `paused`.

**Kritik:** `pending` bir PK'yı `end` ile bitiremezsiniz → `cancel` (davet eden) veya `reject` (davet edilen) kullanın. Yanlış action 400 döner.

### Zamanlamalar
| Sabit | Değer | Not |
|---|---|---|
| Davet zaman aşımı | **60 sn** | Süre dolunca `expired`; sunucu otomatik kapatır |
| Varsayılan süre | 180 sn | admin `pk_default_duration` ile değiştirebilir |
| Min süre | 60 sn | |
| Maks süre | 600 sn | |

> Geri sayımı **`endsAt`/`endTime` − `serverNow`** farkından hesaplayın. Cihaz saatini kullanmayın.

---

## 8. Skor

- Skor **hediyelerle** artar; hediye gönderildiğinde backend PK skorunu otomatik işler. Flutter ayrı bir skor çağrısı yapmaz.
- `POST /api/live/pk/score` yalnızca **admin/superadmin** içindir (normal kullanıcıda 403 `FORBIDDEN`).
- Kazanan: `score1 > score2` → `user1`, tersi → `user2`, eşitlik → `isDraw: true`, `winnerId: null`.

---

## 9. Gerçek zamanlı olaylar (SSE)

PK olayları **iki kanaldan** da yayınlanır; hangi bağlamdaysanız (oda veya yayın) o kanalı dinleyin:

| Bağlam | Kanal |
|---|---|
| Sesli oda | oda SSE akışı, olay adı **`pk`** |
| Canlı yayın | yayın SSE akışı, olay adı **`pk`** |
| Push bildirimi | `type: "pk_invite"`, `data.type` = `pk:invite` / `pk:accepted` |

### Olay gövdesi (ortak)
```json
{
  "type": "pk",
  "battleId": "cmu1...",
  "action": "created | started | active | paused | rejected | cancelled | completed | starting",
  "eventType": "PK_STARTING | PK_STARTED | PK_REQUEST_REJECTED | PK_REQUEST_CANCELLED",
  "room1Id": "...", "room2Id": "...",
  "user1Id": "...", "user2Id": "...",
  "score1": 0, "score2": 0,
  "status": "pending",
  "duration": 180,
  "startedAt": "...", "acceptedAt": "...", "endsAt": "...", "endTime": "...",
  "expiresAt": "...",
  "challengerName": "Ada",
  "countdownSec": 5,
  "participants": [ { "userId": "...", "side": 1, "seatNumber": 3, "isCaptain": true } ],
  "serverNow": "2026-09-14T22:10:00.000Z"
}
```
Alanlar action'a göre değişir; `battleId`, `action`, `status` her zaman vardır.

### Davet bildirimi (oda kanalı `room_event`)
`create` anında hedef odaya ayrıca bir `pk_invite` room_event düşer — davet modalini bununla açabilirsiniz.

---

## 10. Yeniden bağlanma / senkronizasyon

SSE koparsa:
1. `GET /api/live/pk?roomId=<mevcut oda/yayın>` → tek kaynak doğruluk.
2. `data == null` ise yerel PK state'ini temizleyin.
3. `status` terminal ise (`completed/cancelled/rejected/expired`) sonuç ekranını gösterip 5 sn sonra kapatın.
4. `active` ise geri sayımı `endsAt − serverNow` ile yeniden kurun.
5. Oda içi kullanıcı PK'sı için ek olarak `GET /api/chat/rooms/{roomId}/pk` çağırın (katılımcı listesi burada).

---

## 11. UI davranış kuralları

| Durum | Beklenen UI |
|---|---|
| PK butonu görünürlüğü | Yalnız **oda sahibi** / **yayıncı**. Misafir/co-host'ta gizle |
| Aday listesi boş | "Şu an PK yapılabilecek kimse yok" |
| `selfBusy: true` | PK butonu pasif |
| `pending` (gönderen) | "Yanıt bekleniyor · 60sn" + **İptal** butonu |
| `pending` (alıcı) | Davet modali + **Kabul / Reddet**, 60 sn geri sayım |
| `starting` | Tam ekran geri sayım (`countdownSec`) |
| `active` | Çift taraflı skor barı + kalan süre |
| `paused` | Skor barı donuk + "Duraklatıldı" rozeti |
| `completed` | Kazanan animasyonu, `isDraw` ise "Berabere" |
| `expired` | "Davet yanıtlanmadı" toast'ı |

---

## 12. Doğrulanmış senaryolar (backend, 2026-09-14)

| # | Senaryo | Sonuç |
|---|---|---|
| T1 | Yayın oluştur → zarf açılıyor, `id` alınıyor | 200 ✅ |
| T2 | `roomId` anahtarıyla `/api/video-streams/pk` create | 200 ✅ |
| T3 | Sahibi olmayan kullanıcı create | 403 `NOT_STREAM_OWNER` ✅ |
| T4 | Geçersiz kimlikle create | 404 `STREAM_NOT_FOUND` ✅ |
| T5 | `pending` PK → `cancel` | 200 ✅ |
| T6 | `/api/live/pk` yayın↔yayın create + cancel | 200 ✅ |
| T7 | `/api/chat/rooms/{id}/pk` oda↔oda create + cancel | 200 ✅ |
| T7c | `/api/live/pk` oda↔oda create + cancel | 200 ✅ |
| T8 | `/api/live/pk` **karışık** oda↔yayın create + cancel | 200 ✅ |
