# Canlifal.com Web ↔ Flutter Senkronizasyon Analiz Raporu

**Tarih:** 2026-05-19  
**Referans:** Web (Canlifal.com) — bu repoda yalnızca `api/` mirror + `mobile/` + dokümantasyon mevcut; Next.js web kaynak kodu repoda yok. Analiz `api/`, `mobile/` ve mevcut dokümanlara dayanır.

**APK sürümü (bu düzeltme dalı):** `1.0.136+138`

---

## 1. Tespit Edilen Hatalar

### 1.1 Kendi kendine beğeni artışı (KRİTİK — düzeltildi)

| Bulgu | Kanıt |
|-------|-------|
| Hediye tam ekran animasyonu her hediyede `burstHearts` → `POST /like` tetikliyordu | `live_broadcast_room_page.dart` gift listener |
| Swipe izleyicide 2–3 oda örneği aynı global `liveRoomInteractionProvider` paylaşıyordu | `LiveSwipeViewerPage` + global provider |
| Sunucu toplamı gelince sayaç sıçraması | `live_room_interaction_provider.dart` `total > state.likeCount` |

**Düzeltme:** Hediye listener'dan API beğenisi kaldırıldı; yalnızca `pulseHeartsVisual()`. Provider yayın başına (`family`) yapıldı. Beğeni yalnızca kullanıcı çift dokunuşu (`_onDoubleTapHeart`) ile gönderilir.

### 1.2 PK sistemi mobilde eksik / mock (KISMEN düzeltildi)

| Alan | Web (API mirror) | Flutter (önce) | Durum |
|------|------------------|----------------|-------|
| Video PK API | `POST/GET /api/video-streams/:id/pk-battle` | Sadece `create` + snackbar | UI + polling + socket eklendi |
| Voice PK | API yok | Tamamen local mock (`pk_battle_provider.dart`) | Hâlâ mock — API gerekli |
| Dual-stream sync | `create` iki stream'e yazar, `score` tek tarafta kalıyordu | — | `syncPkMirrors` eklendi |
| PK socket | Yoktu | Yoktu | `pkBattle`, `pkBattleUpdated`, `PK_UPDATED` eklendi |

### 1.3 Müzik çalmama (KISMEN düzeltildi)

| Neden | Açıklama |
|-------|----------|
| SSE `musicQueue` eksik | SSE yalnızca `queueLength` gönderiyordu; socket tam kuyruk gönderiyordu |
| YouTube çözümleme | Mobil Piped/Invidious gerekir; PR #113 fallback (watch URL) production'da olmalı |
| TRTC + DJ audio focus | `AndroidAudioFocus.gain` TRTC ile çakışıyordu → `gainTransientMayDuck` |
| Debug eksikliği | `musicId`, `streamUrl`, `playState` logları eklendi |

### 1.4 Sesli oda hediye socket'i boştu (düzeltildi)

`chat_room_providers.dart` içinde `onEvent: (_) {}` — socket hediyeleri yutuluyordu; yalnızca 6 sn REST poll kullanılıyordu.

**Düzeltme:** `publishRemote` → `voiceRoomGiftRealtimeProvider`.

### 1.5 Auth

- REST: `dio_provider.dart` Bearer JWT + 401 refresh — **doğru**
- Canlı socket: JWT gönderilmiyor (web mirror ile aynı)
- SSE: ayrı Dio + manuel token

### 1.6 Performans

- Sesli oda: SSE 3s + poll 5–12s + hediye poll 6s + heartbeat 20s (üst üste)
- Canlı: socket + chat poll 8s + hediye poll 4s + 1s `setState` timer
- `ref.watch(voiceRoomLiveProvider)` geniş rebuild

---

## 2. Web'de Olup Flutter'da Olmayan Özellikler

| Özellik | Not |
|---------|-----|
| Voice PK sunucu entegrasyonu | `voice_pk_battle_page.dart` tamamen local |
| PK rakip yayın seçici UI | Video PK'da `opponentStreamId` seçimi yok |
| PK süre sayacı (sunucu) | API'de timer yok; web davranışı doğrulanamadı |
| Web Next.js kaynak | Repoda yok — tam diff mümkün değil |
| `public/FLUTTER_CURSOR_PROMPT.md` | canlifal.com URL'si HTML dönüyor (deploy bekliyor) |

---

## 3. Eksik API Entegrasyonları

| Endpoint | Flutter durumu |
|----------|----------------|
| `POST /api/video-streams/:id/like` | Var — artık yalnızca kullanıcı etkileşimi |
| `POST/GET /api/video-streams/:id/pk-battle` | Var — accept/reject/score/end + polling |
| Voice PK API | **Yok** — mock |
| `GET /api/chat/rooms/:id/stream` (SSE) | Var — `musicQueue` eklendi |
| `GET /api/chat/rooms/:id/music-queue` | Var |
| Co-broadcast, fortune session, signal | PR #114 ile eklendi |

---

## 4. Eksik Socket Eventleri

### Canlı yayın (`stream:{id}`)

| Event | Tetikleyen | Veri | Flutter |
|-------|------------|------|---------|
| `gift` / `giftSent` | `gifts.ts` | Hediye payload | Var |
| `streamMessage` / `chatMessage` / `message` | `giftHub.ts` | Mesaj | Var |
| `viewerCount` / `viewerCountUpdated` | `video_streams.ts` join/leave | `{ viewerCount }` | Var |
| `streamEnded` / `STREAM_ENDED` | `endLiveStream` | `{ streamId }` | Var |
| `pkBattle` / `pkBattleUpdated` / `PK_UPDATED` | `video_streams.ts` pk-battle | `{ battle }` | **Eklendi** |

### Sesli oda (`room:{id}`)

| Event | Flutter |
|-------|---------|
| `gift` / `giftSent` | **Eklendi** (publishRemote) |
| `dj` / `music` / `QUEUE_UPDATED` / `CURRENT_SONG_CHANGED` | Var (onDjUpdate) |
| `roomUsers` / `presenceUpdated` / `userJoined` / `userLeft` | SSE presence (socket opsiyonel) |

---

## 5. Eksik TRTC İşlemleri

| İşlem | Web (doküman) | Flutter |
|-------|---------------|---------|
| Join room | `POST /api/trtc/usersig` | Var — `TrtcRoomManager` |
| Voice oda adı | `voice_room_{prismaId}` | `voice_room_entity.dart` ile uyumlu |
| Live oda adı | `streamId` | Aynı |
| Publish/subscribe audio | TRTC SDK | Var |
| DJ + TRTC audio focus | Web iframe ayrı kanal | `gainTransientMayDuck` ile iyileştirildi |

---

## 6. Performans Sorunları

1. **Çift/üçlü veri kanalı** — socket + poll + SSE aynı veriyi çekiyor
2. **Global interaction provider** — swipe'ta çapraz yayın etkileşimi (düzeltildi: family)
3. **1s setState timer** — `live_broadcast_room_page.dart` elapsed süre
4. **Geniş `ref.watch(voiceRoomLiveProvider)`** — tüm oda sayfası rebuild
5. **Hediye poll 2 dk geri oynatma** — odaya girişte eski hediyeler tetiklenebilir (like artık bağlı değil)

**Öneri (gelecek):** Poll aralıklarını socket bağlıyken devre dışı bırak; `RepaintBoundary` / `select` ile dar rebuild.

---

## 7. Düzeltilen Dosyalar

### API
- `api/src/lib/liveStreamExtrasStore.ts` — PK mirror sync
- `api/src/socket/giftHub.ts` — `emitPkBattleUpdate`
- `api/src/routes/video_streams.ts` — PK sonrası socket emit
- `api/src/routes/chat_rooms.ts` — SSE `musicQueue`

### Flutter
- `mobile/lib/features/live/presentation/pages/live_broadcast_room_page.dart`
- `mobile/lib/features/live/presentation/providers/live_room_interaction_provider.dart`
- `mobile/lib/features/live/presentation/providers/live_video_pk_provider.dart`
- `mobile/lib/features/live/presentation/providers/live_room_providers.dart`
- `mobile/lib/features/live/presentation/widgets/broadcast_room/live_pk_score_bar.dart`
- `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart`
- `mobile/lib/features/live/data/services/live_gift_socket_bridge.dart`
- `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers.dart`
- `mobile/lib/features/voice_hub/presentation/services/voice_room_dj_player.dart`
- `mobile/lib/features/voice_hub/data/services/voice_room_gift_realtime_service.dart`
- `mobile/pubspec.yaml` — `1.0.136+138`

---

## 8. Yapılan Değişiklikler (özet)

1. **Auto-like:** Hediye → beğeni API zinciri kırıldı; per-stream interaction provider
2. **PK:** API mirror sync, socket events, skor çubuğu UI, hediye→PK skor, 3s polling
3. **Müzik:** SSE'ye tam `musicQueue`, DJ audio focus, debug logları
4. **Voice hediye:** Socket → `publishRemote` ile gerçek zamanlı
5. **Rapor:** Bu doküman

---

## 9. Kalan Riskler

| Risk | Önem |
|------|------|
| Voice PK hâlâ local mock | Yüksek — web paritesi için API şart |
| Web kaynak repoda yok | Orta — bazı davranışlar doğrulanamadı |
| PK in-memory (Prisma yok) | Orta — restart'ta PK kaybolur |
| Production'da PR #113 müzik fallback deploy | Yüksek — müzik çalmama devam edebilir |
| Canlı socket JWT yok | Düşük — mirror ile uyumlu |
| Performans optimizasyonu tam değil | Orta |
| `FLUTTER_CURSOR_PROMPT.md` public deploy | Düşük — dokümantasyon |

---

## Socket Event Envanteri (tam liste)

Kaynak: `api/src/socket/giftHub.ts`

### Client → Server
- `joinStream` `{ streamId, userId? }`
- `leaveStream` `{ streamId }`
- `joinRoom` `{ roomId }`
- `leaveRoom` `{ roomId }`

### Server → Client (canlı)
- `gift`, `giftSent`
- `streamMessage`, `chatMessage`, `message`
- `viewerCount`, `viewerCountUpdated`
- `streamEnded`, `STREAM_ENDED`
- `pkBattle`, `pkBattleUpdated`, `PK_UPDATED` *(yeni)*

### Server → Client (sesli oda)
- `gift`, `giftSent`
- `chatMessage`, `message`, `roomMessage`
- `dj`, `music`, `QUEUE_UPDATED`, `CURRENT_SONG_CHANGED`
- `roomUsers`, `presenceUpdated`, `userJoined`, `userLeft`

---

## Deploy Notları

1. **API** — bu dal + PR #113 (`tryStartMusicFromQueue` YouTube fallback) production'a
2. **APK** — `1.0.136+138` derle ve dağıt
3. **public/FLUTTER_CURSOR_PROMPT.md** — canlifal.com köküne kopyala
