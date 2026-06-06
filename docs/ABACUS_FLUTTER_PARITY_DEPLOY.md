# Abacus Deploy — FLUTTER_CURSOR_PROMPT Tam Parite + APK

Aşağıdaki metni **Abacus.ai**'ye olduğu gibi yapıştırın.

---

```
# Görev: canlifal.com — Flutter tam parite deploy (API + statik prompt + APK)

## Bağlam

- Site: https://canlifal.com (Next.js App Router + Prisma)
- Mobil: Flutter `canlifal_social`, paket `com.mesutbyrm.canlifal`
- GitHub: https://github.com/mesutbyrm/Cursor-Flutter-
- PR #114 — branch `cursor/flutter-parity-full-7009` (tam parite)
- PR #113 — müzik isteği oynatma düzeltmesi (merge edilmemişse ayrıca al)
- Hedef APK: **1.0.135+137**

## 1) Statik prompt dosyası (ÖNCE)

`docs/FLUTTER_CURSOR_PROMPT.md` dosyasını Next.js projesine kopyala:

```
public/FLUTTER_CURSOR_PROMPT.md
```

Redeploy sonrası doğrula:

```bash
curl -s https://canlifal.com/FLUTTER_CURSOR_PROMPT.md | head -3
# Beklenen: # Canlifal Flutter — Cursor Agent Prompt
# HTML dönmemeli!
```

---

## 2) Yeni API endpoint'leri (canlifal.com Next.js)

Referans kaynak (mirror): GitHub repo `api/src/` — özellikle:
- `api/src/lib/liveStreamExtrasStore.ts`
- `api/src/routes/video_streams.ts`
- `api/src/routes/social.ts`
- `api/src/routes/userFlutterApi.ts`
- `api/src/lib/chatRoomStore.ts` (nickname + müzik)

### A) Canlı beğeni — TikTok tarzı (+1/tap)

```
POST /api/video-streams/{streamId}/like
Authorization: Bearer {JWT}
Body: { "count": 1 }
Response: { "likeCount": 42, "success": true }
```

### B) PK Battle

```
POST /api/video-streams/{streamId}/pk-battle
Body: {
  "action": "create" | "accept" | "reject" | "score" | "end",
  "opponentStreamId": "...",   // create için opsiyonel
  "opponentId": "...",
  "score": 1,
  "side": "left" | "right"
}
Response: { "battle": { "status", "leftScore", "rightScore", "winner" } }

GET /api/video-streams/{streamId}/pk-battle
```

### C) WebRTC signaling (HTTP poll — TRTC dışı senaryolar)

```
GET  /api/video-streams/{streamId}/signal?since={iso8601}
POST /api/video-streams/{streamId}/signal
Body: { "type": "offer" | "answer" | "ice", "payload": { ... } }
Response GET: { "signals": [ { "id", "type", "payload", "createdAt" } ] }
```

### D) Co-broadcast (birlikte yayın)

```
POST /api/video-streams/{streamId}/co-broadcast/invite
Body: { "inviteeId": "user_cuid" }
→ yalnızca yayıncı

POST /api/video-streams/{streamId}/co-broadcast
Body: { "inviteId": "...", "accept": true }

GET /api/user/co-broadcast-invites
→ { "invites": [ ... ] }
```

### E) Canlı falcı oturumu

```
POST /api/fortune-tellers/session
Body: { "tellerId": "ft-xxx" }
Response: { "sessionId": "fs-...", "status": "pending" }

⚠️ Route sırası: /fortune-tellers/session POST, /fortune-tellers/:id GET'den ÖNCE tanımlanmalı
```

### F) Oda rumuzu (presence)

```
POST /api/chat/rooms/{roomId}/presence
Body: { "nickname": "YeniRumuz" }
→ mevcut join + rumuz güncelleme
```

### G) Müzik isteği (PR #113 — kritik, yoksa şarkı çalmaz)

`tryStartMusicFromQueue` içinde Piped başarısızsa **YouTube watch URL** ile `playing: true` set et.
`getDjState`: `nowPlaying` = kuyruk[0] (playing false olsa bile).
`GET /music-queue` response'a `musicUrl` ekle.

Kaynak: `api/src/lib/chatRoomStore.ts` (PR #113 branch: `cursor/music-playback-fix-7009`)

---

## 3) Ortam değişkenleri

```env
YOUTUBE_API_KEY=AIza...           # müzik arama + !istek
TRTC_SDK_APP_ID=...
TRTC_SECRET_KEY=...
```

---

## 4) Flutter APK derleme

```bash
git clone https://github.com/mesutbyrm/Cursor-Flutter-.git
cd Cursor-Flutter-
git checkout cursor/flutter-parity-full-7009
# Müzik fix yoksa: git merge origin/cursor/music-playback-fix-7009

cd mobile
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://canlifal.com
```

`pubspec.yaml` → `version: 1.0.135+137`

APK'yı indirme sayfasına / GitHub Releases'e yükle.

---

## 5) curl doğrulama

```bash
BASE=https://canlifal.com
TOKEN="..."        # test JWT
STREAM="stream-id"
ROOM="sohbet"

# Prompt dosyası
curl -sI "$BASE/FLUTTER_CURSOR_PROMPT.md" | grep -i content-type

# Beğeni
curl -s -X POST "$BASE/api/video-streams/$STREAM/like" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"count":1}' | jq .

# PK oluştur
curl -s -X POST "$BASE/api/video-streams/$STREAM/pk-battle" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"action":"create"}' | jq .

# Falcı oturumu
curl -s -X POST "$BASE/api/fortune-tellers/session" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"tellerId":"ft-1"}' | jq .

# Rumuz
curl -s -X POST "$BASE/api/chat/rooms/$ROOM/presence" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"nickname":"TestRumuz"}' | jq .

# Co-broadcast davetleri
curl -s "$BASE/api/user/co-broadcast-invites" \
  -H "Authorization: Bearer $TOKEN" | jq .

# Müzik kuyruğu (musicUrl dolu mu?)
curl -s "$BASE/api/chat/rooms/$ROOM/music-queue" \
  -H "Authorization: Bearer $TOKEN" | jq '{playing, musicUrl, nowPlaying}'
```

---

## 6) Manuel test (APK 1.0.135+137)

### Canlı yayın
- [ ] Double-tap kalp → sayaç artar, sunucuda `likeCount` kalıcı
- [ ] Host: **PK** butonu → "PK başlatıldı" mesajı
- [ ] Kamera çevir (switchCamera) çalışır

### Sesli oda
- [ ] Ayarlar → **Rumuz değiştir** → sohbette yeni ad görünür
- [ ] `!istek Şarkı` → sohbette görünür **ve çalar** (PR #113 API şart)

### Falcı
- [ ] Canlı falcı profili → **Canlı Fal Oturumu Başlat** → sessionId snackbar

### Co-broadcast
- [ ] `GET /co-broadcast-invites` 200 döner (boş dizi olabilir)

---

## 7) Deploy sırası

1. API endpoint'leri + müzik fix (PR #113) deploy
2. `public/FLUTTER_CURSOR_PROMPT.md` ekle + redeploy
3. curl testleri yeşil
4. APK 1.0.135+137 yayınla
5. Kullanıcılara güncelleme bildirimi

Deploy bitince raporla:
- commit hash / deploy URL
- curl çıktıları (like, pk, session, musicUrl)
- APK indirme linki
```
