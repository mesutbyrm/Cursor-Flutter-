# Canlifal Flutter — Cursor Agent Prompt

**Kaynak repo:** `mobile/` (paket: `canlifal_social`)  
**Üretim API:** `https://canlifal.com`  
**Yerel mirror:** `api/` (Express; üretimin tam kopyası değil)

Bu belge, Cursor / Cloud Agent'ların canlifal.com ile uyumlu Flutter geliştirmesi yaparken izlemesi gereken sözleşmeyi tanımlar.

> **canlifal.com dağıtımı:** Bu dosyayı site kökünde yayınlamak için Next.js `public/FLUTTER_CURSOR_PROMPT.md` olarak kopyalayın.  
> Şu an `https://canlifal.com/FLUTTER_CURSOR_PROMPT.md` catch-all route nedeniyle HTML döndürebilir — `public/` altına koyun.

---

## Genel kurallar

1. **Yeni API icat etme** — Önce `mobile/lib/core/network/api_endpoints.dart` ve `docs/canlifal-flutter-api-docs.txt` kontrol et.
2. **Auth:** Mobil = `Authorization: Bearer <JWT>`. Web = NextAuth cookie. Mobilde cookie auth birincil değil.
3. **Kimlik:** Kullanıcı anahtarı = Prisma `User.id` / `/api/me` → `id`. OIDC `sub` veya `gcid` ile karıştırma.
4. **Sesli oda ID:** `room.id` (cuid) kullan; slug yalnızca URL için.
5. **Gerçek zamanlı:** Sesli oda = **SSE** (`/stream`). Canlı video = Socket.IO + TRTC. Fal AI = SSE streaming (henüz mobilde yok).
6. **Değişiklik sonrası:** `cd mobile && dart analyze && flutter test`

---

## 1. Authentication — Dual auth (Bearer JWT)

### Üretim modeli

| İstemci | Mekanizma |
|---------|-----------|
| Web (canlifal.com) | NextAuth session cookie |
| Flutter mobil | JWT Bearer (`mobile-*` uçları) |

### Mobil uçlar

```
POST /api/auth/mobile-register
POST /api/auth/mobile-login
POST /api/auth/mobile-google
POST /api/auth/mobile-tiktok
POST /api/auth/mobile-refresh
POST /api/auth/forgot-password
GET  /api/me
```

### Flutter referans

- `mobile/lib/core/network/dio_provider.dart` — Bearer ekleme, 401 → refresh
- `mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart`
- `mobile/lib/core/config/env.dart` — `Env.useMobileAuth` (canlifal.com = true)

### Dio interceptor kalıbı

```dart
// Her istek (public auth hariç):
options.headers['Authorization'] = 'Bearer $accessToken';
// 401 → POST /api/auth/mobile-refresh → tekrar dene (bir kez)
```

**Durum:** ✅ Tam

---

## 2. Canlı yayın — Oluşturma, katılma, bitirme

### API

```
GET  /api/video-streams
POST /api/video-streams              # yayın oluştur
POST /api/video-streams/{id}/live-started
POST /api/video-streams/{id}/join    # izleyici
POST /api/video-streams/{id}/leave
POST /api/video-streams/{id}/end
GET  /api/video-streams/{id}/messages
POST /api/video-streams/{id}/messages
POST /api/trtc/usersig               # TRTC oda girişi
```

### Flutter referans

- `features/live/data/datasources/live_remote_datasource.dart`
- `features/live/presentation/providers/live_room_providers.dart`
- `features/live/presentation/pages/live_broadcast_prep_page.dart`
- `features/live/presentation/pages/live_broadcast_room_page.dart`
- `features/trtc/presentation/trtc_room_manager.dart`

### Akış

1. `POST /api/video-streams` → `streamId`
2. `POST …/live-started` + TRTC `enterRoom` (`roomId` = stream oda ID)
3. İzleyici: `POST …/join` + TRTC audience
4. Bitir: `POST …/end` + TRTC `leave`

**Sunucu env:** `TRTC_SDK_APP_ID`, `TRTC_SECRET_KEY` zorunlu.

**Durum:** ✅ Temel akış

---

## 3. Kamera döndürme — `switchCamera()`

Client-side TRTC; REST yok.

```dart
// features/trtc/presentation/trtc_room_manager.dart
void switchCamera() {
  _device?.switchCamera(_cameraOn);
}
```

UI: `live_premium_bottom_bar.dart`, `live_room_bottom_bar.dart` (yalnızca yayıncı).

**Durum:** ✅

---

## 4. PK Battle — Create, accept, reject, score, end

### Üretim API (video stream)

```
POST /api/video-streams/{id}/pk-battle        # oluştur / kabul / red / skor / bitir
```

### Flutter durumu

- **UI var:** `voice_pk_battle_page.dart`, `pk_battle_provider.dart` (sesli oda premium)
- **API yok:** Skorlar yerel/mock; `POST …/pk-battle` bağlı değil

### Yapılacak (gap)

1. `ApiEndpoints` → `videoStreamPkBattle(streamId)`
2. Remote datasource + provider → sunucu PK state
3. Canlı video odasına bağla (voice-room PK değil)

**Durum:** ⚠️ Kısmi (UI only)

---

## 5. Beğeni — TikTok tarzı kümülatif like

### Üretim API

```
POST /api/video-streams/{id}/like   # her tap = +1, kümülatif
```

### Flutter durumu

- Canlı yayında double-tap → `live_room_interaction_provider.dart` yerel `likeCount++`
- **API'ye POST yok** — diğer izleyiciler göremez

### Yapılacak (gap)

```dart
await dio.post(ApiEndpoints.videoStreamLike(streamId));
// Response: { likeCount: N } → state güncelle
```

**Durum:** ⚠️ Kısmi (yerel UI)

---

## 6. Fal isteme — Falcı listesi + oturum

### API

```
GET  /api/fortune-tellers
GET  /api/fortune-tellers/{id}
POST /api/fortune-tellers/session     # canlı falcı oturumu başlat
GET/POST /api/teller-chat/{sessionId}
```

### Flutter durumu

- Liste: ✅ `home_remote_datasource.dart`, `home_live_fortune_tellers_row.dart`
- Katalog fallar (tarot, kahve): ✅ yerel `FortuneSessionPage` + `FortuneReadingService`
- **Canlı falcı oturumu:** ❌ `POST …/session` yok; detay sayfası DM'e yönlendiriyor

**Durum:** ⚠️ Kısmi

---

## 7. Rumuz değiştirme — Presence endpoint

### API

```
POST /api/chat/rooms/{roomId}/presence
Body: { "nickname": "YeniRumuz" }   # üretim destekler
GET  /api/chat/rooms/{roomId}/presence
```

### Flutter durumu

- `joinPresence` → boş POST; rumuz `auth.username`'den gelir
- Kullanıcı odada rumuz değiştiremez

### Yapılacak (gap)

```dart
await dio.post(
  ApiEndpoints.chatRoomPresence(roomId),
  data: {'nickname': newNickname},
);
```

**Durum:** ❌

---

## 8. Müzik / DJ — YouTube arama, şarkı isteği, kuyruk

### API

```
GET  /api/music/search?q=
POST /api/chat/rooms/{id}/song-request
GET  /api/chat/rooms/{id}/music-queue
POST /api/chat/rooms/{id}/music-queue
POST /api/chat/rooms/{id}/music-queue/advance
GET  /api/chat/rooms/{id}/dj
POST /api/chat/rooms/{id}/dj
GET  /api/chat/youtube-stream?url=
```

### Sohbet komutları

- `!istek Sanatçı - Şarkı` → sunucu YouTube arar, kuyruğa ekler (`skipPayment: true`)
- Üretim format: `[SONG_REQUEST_FREE] videoId|başlık|||`

### Flutter referans

- `chat_room_remote_datasource.dart` — arama, kuyruk, istek
- `chat_room_providers.dart` — senkron, oynatma, SSE `type: dj`
- `voice_room_dj_player.dart` + `youtube_stream_resolver.dart`
- `voice_music_sync.dart` — `SONG_REQUEST_FREE` parse

### Kritik sunucu davranışı

`tryStartMusicFromQueue`: Piped başarısızsa **YouTube watch URL** ile `playing: true` set et. Aksi halde sohbette mesaj görünür ama çalmaz.

**Durum:** ✅ (PR #113 — `1.0.134+136`)

---

## 9. SSE — Flutter örneği

Sesli oda birincil kanal. Socket.IO değil.

### Endpoint

```
GET /api/chat/rooms/{roomId}/stream
Accept: text/event-stream
Authorization: Bearer ...
```

### Olay tipleri

| `type` | İçerik |
|--------|--------|
| `message` | Yeni sohbet satırı |
| `presence` | Kullanıcı listesi |
| `dj` | `playing`, `musicUrl`, `nowPlaying`, `queue` |

### Referans

`mobile/lib/features/voice_hub/data/services/voice_room_sse_service.dart`

```dart
// Özet kalıp
final dio = Dio(BaseOptions(
  baseUrl: Env.apiBaseUrl,
  receiveTimeout: Duration.zero,
  headers: {'Accept': 'text/event-stream'},
));
final res = await dio.get<ResponseBody>(
  ApiEndpoints.chatRoomStream(roomId),
  options: Options(
    responseType: ResponseType.stream,
    headers: {'Authorization': 'Bearer $token'},
  ),
);
// Satırları parse et: "data: {...}\n\n"
```

Yedek: 5–12 sn REST polling (`chat_room_providers.dart` → `refresh`).

**Durum:** ✅ Sesli oda | ❌ Fal AI SSE

---

## 10. WebRTC Signaling — Polling

### Üretim API

```
POST /api/video-streams/{id}/signal   # offer/answer/ice — HTTP poll döngüsü
```

### Flutter durumu

Mobil **Tencent TRTC SDK** kullanır (`POST /api/trtc/usersig`). `/signal` poll loop yok.

TRTC yeterli değilse (Safari WebRTC, teller oturumu):

```dart
// Poll döngüsü örneği
Timer.periodic(const Duration(seconds: 2), (_) async {
  final res = await dio.get('${ApiEndpoints.videoStream(id)}/signal?since=$cursor');
  for (final sig in res.data['signals']) { /* handle ICE/SDP */ }
});
```

**Durum:** ❌ (TRTC ile kısmen karşılanıyor)

---

## 11. Co-Broadcast — Birlikte yayın

### API

```
POST /api/video-streams/{id}/co-broadcast
POST /api/video-streams/{id}/co-broadcast/invite
GET  /api/user/co-broadcast-invites
```

### Flutter durumu

`api_endpoints.dart`'ta yok; UI yok.

**Durum:** ❌

---

## Parite özeti

| Özellik | Durum |
|---------|-------|
| Auth Bearer JWT | ✅ |
| Canlı yayın CRUD | ✅ |
| switchCamera | ✅ |
| PK Battle API | ⚠️ UI only |
| Canlı like API | ⚠️ yerel |
| Falcı listesi | ✅ |
| Falcı oturumu | ❌ |
| Rumuz (presence) | ❌ |
| Müzik/DJ | ✅ |
| SSE (sesli oda) | ✅ |
| WebRTC /signal poll | ❌ |
| Co-broadcast | ❌ |

---

## Öncelikli backlog (mobil)

1. `POST /api/video-streams/{id}/like` — canlı beğeni
2. `POST /api/video-streams/{id}/pk-battle` — video PK
3. Co-broadcast davetleri + UI
4. `POST /api/fortune-tellers/session` — canlı falcı
5. Presence `nickname` body
6. `/signal` polling (TRTC dışı senaryolar)

---

## İlgili belgeler

| Belge | Açıklama |
|-------|----------|
| `docs/canlifal-flutter-api-docs.txt` | Mobil API referansı |
| `docs/WEB_TO_FLUTTER_PARITY.md` | Sayfa/API matrisi |
| `docs/FLUTTER_BACKEND_PARITY.md` | Deploy kontrol listesi |
| `docs/VOICE_ROOM_SSE_ANALYSIS.md` | SSE detayı |
| `AGENTS.md` | Agent talimatları |

---

## APK derleme

```bash
cd mobile
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://canlifal.com
```

Güncel sürüm: `mobile/pubspec.yaml` → `version:` satırı.
