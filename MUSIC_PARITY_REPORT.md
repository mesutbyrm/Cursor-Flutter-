# Canlifal Web ↔ Flutter Music Parity Report

Tarih: 2026-06-10

## Kaynaklar

- Web/API sozlesmesi: `api/src/routes/chat_rooms.ts`, `api/src/lib/chatRoomStore.ts`
- Flutter remote datasource: `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart`
- Flutter state/controller: `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers.dart`
- Flutter music UI: `mobile/lib/features/voice_hub/presentation/pages/voice_music_hub_page.dart`
- Mini player: `mobile/lib/features/voice_hub/presentation/widgets/voice_room/voice_room_music_mini_player.dart`
- Background player: `mobile/lib/features/voice_hub/presentation/services/voice_room_dj_player.dart`
- Stream resolver: `mobile/lib/features/voice_hub/data/youtube_stream_resolver.dart`
- Socket/SSE: `mobile/lib/features/voice_hub/data/services/voice_room_sse_service.dart`, `voice_room_gift_socket.dart`

Not: Gercek Next.js web kaynak kodu bu repoda yoktur. Bu rapor yerel API
mirror, uretim dokumanlari ve Flutter uygulamasina dayanir.

## Web muzik sozlesmesi

| Islem | Endpoint / event | Web/API davranisi |
|---|---|---|
| Sarki arama | `GET /api/music/search?q=...` | YouTube API ile arama; `{ items: [...] }` doner |
| Eski/yedek arama | `GET /api/youtube/search`, `GET /api/chat/youtube-search` | Eski mobil/web uyum yollari |
| Populer muzik | `GET /api/chat/music/popular` | Populer sarki katalogu |
| Stream cozme | `GET /api/chat/youtube-stream?url=...` veya `?videoId=...` | Piped ile audio stream cozer |
| Audio proxy | `GET /api/chat/youtube-audio?url=...` | googlevideo stream proxy |
| Kuyruk getirme | `GET /api/chat/rooms/:roomId/music-queue` | `queue`, `cost`, `musicEnabled`, `nowPlaying`, `playing`, `musicUrl` doner |
| Ucretli istek | `POST /api/chat/rooms/:roomId/song-request` | Jeton kontrolu, `priority`, `giftTo`, `note`; kuyruga ekler |
| Yedek kuyruk post | `POST /api/chat/rooms/:roomId/music-queue` | `song-request` yedegi |
| !istek komutu | `POST /api/chat/rooms/:roomId/messages` | Server `addTextMessage()` icinde `!istek` parse eder ve `requestMusicQueue(skipPayment: true)` cagirir |
| Sarki degistirme | `POST /api/chat/rooms/:roomId/music-queue/advance` | Kuyrukta sonraki sarkiyi baslatir |
| Kuyruktan silme | `DELETE /api/chat/rooms/:roomId/music-queue/:itemId` | Yetkili kullanici item siler |
| Kuyruk temizleme | `DELETE /api/chat/rooms/:roomId/music-queue` | Kuyruk ve DJ state temizlenir |
| Muzik ayarlari | `PATCH /api/chat/rooms/:roomId/music-settings` | `musicEnabled`, `musicRequestCost`, `maxMusicQueue` |
| DJ state | `GET/POST /api/chat/rooms/:roomId/dj` | `musicUrl`, `playing`, `nowPlaying`, `musicQueue` |
| Realtime | SSE `type: dj`; Socket.IO `dj`, `music`, `QUEUE_UPDATED`, `CURRENT_SONG_CHANGED` | Tum kullanicilara kuyruk/playing/musicUrl yayinlanir |

## Flutter muzik akisi

| Kontrol | Flutter karsiligi | Durum |
|---|---|---|
| `!istek` komutu | `VoiceRoomLiveController.sendMessage()` komutu server mesaj endpointine yollar | Web ile ayni |
| Ucretli muzik istegi | `VoiceMusicHubPage._submit()` → `requestMusic(priority: true)` → `POST /song-request` | Web ile ayni |
| DJ/ucretsiz istek | Yetkili/DJ ise `priority: false` / server skipPayment mantigi | Web ile uyumlu |
| Sarki arama | `ChatRoomRemoteDataSource.searchYoutube()` | Web API + eski endpoint + populer katalog + client fallback |
| Kuyruk getirme | `fetchMusicQueue()` | Odaya giriste ve modal acilista otomatik alinir |
| Sonradan odaya giren kullanici | `build()` → `refresh(includeDj: true)` → `fetchDj + fetchMusicQueue` | Mevcut kuyruk otomatik gelir |
| Realtime sync | SSE `onDjUpdate`, Socket `onDjUpdate` | `musicQueue`, `nowPlaying`, `musicUrl`, `playing` state'e islenir |
| Sarki degistirme | `skipMusic()` → `/music-queue/advance` + `refresh()` | Web ile ayni |
| Mini player | `VoiceRoomMusicMiniPlayer` | Kuyruk, duration, progress, play/pause/stop/skip gosterir |
| Background playback | `VoiceRoomDjPlayer` + `just_audio` + `audio_service` | Android/iOS background media session |
| Stream cozme | `YoutubeStreamResolver` | Site API → Piped → Invidious → youtube_explode fallback |
| googlevideo local playback | `VoiceRoomDjStreamLoader` | Referer gerektiren streamleri lokal dosyaya indirir |

## Bu turda uygulanan duzeltmeler

| Alan | Sorun | Duzeltme | Dosya |
|---|---|---|---|
| Kuyruk response alias | Flutter bazi yerlerde sadece `queue` okuyordu; web/socket payloadlari `musicQueue` veya `items` donebilir | `queue`, `musicQueue`, `items` birlikte desteklendi | `chat_room_remote_datasource.dart`, `chat_room_dj_state.dart` |
| Kapak gorseli alias | Queue/search modelleri bazi API yanitlarindaki `thumbnail` veya `image` alanlarini her yerde okumuyordu | `thumbUrl`, `thumbnail`, `image` birlikte desteklendi | `music_queue_item.dart` |
| Kanal/sanatci alias | Web arama yaniti `channelTitle` donebilir | `uploader`, `channelTitle`, `channel`, `artist` birlikte desteklendi | `music_queue_item.dart` |

## Request / response model uyumu

| Model | Web/API alanlari | Flutter okunan alanlar | Durum |
|---|---|---|---|
| Arama sonucu | `videoId`, `id`, `title`, `url`, `thumbnail`, `thumbUrl`, `channelTitle`, `channel`, `duration` | `YoutubeSearchHit.fromJson` ve `_parseYoutubeHits` alias okur | Uyumlu |
| Kuyruk item | `id`, `videoId`, `title`, `youtubeUrl`, `url`, `thumbUrl`, `thumbnail`, `image`, `requestedBy`, `user`, `giftTo`, `note`, `uploader`, `channelTitle`, `channel`, `artist`, `duration` | `MusicQueueItem.fromJson` alias okur | Uyumlu |
| DJ state | `djUsers`, `activeDjId`, `musicUrl`, `playing`, `backgroundImage`, `musicQueue`, `queue`, `items`, `nowPlaying`, `musicRequestCost`, `cost`, `maxMusicQueue`, `maxQueueLength`, `musicEnabled` | `ChatRoomDjState.fromJson` alias okur | Uyumlu |
| Music queue response | `queue`, `musicQueue`, `items`, `cost`, `musicRequestCost`, `maxMusicQueue`, `musicEnabled`, `nowPlaying`, `playing`, `canRequestMusic`, `musicUrl` | `fetchMusicQueue()` alias okur | Uyumlu |
| Request response | `item`, `queue`, `musicQueue`, `items`, `newBalance`, `coinBalance`, `queuePosition`, `musicUrl`, `playing` | `requestMusic()` alias okur | Uyumlu |

## Socket / SSE muzik senkronu

| Event | Flutter listener | Islenen alanlar |
|---|---|---|
| SSE `type: dj` | `VoiceRoomSseService.onDjUpdate` | `playing`, `musicUrl`, `nowPlaying`, `queue`, `musicQueue` |
| Socket `dj` | `VoiceRoomGiftSocket.onDjUpdate` | Ayni payload |
| Socket `music` | `VoiceRoomGiftSocket.onDjUpdate` | Ayni payload |
| Socket `QUEUE_UPDATED` | `VoiceRoomGiftSocket.onDjUpdate` | Ayni payload |
| Socket `CURRENT_SONG_CHANGED` | `VoiceRoomGiftSocket.onDjUpdate` | Ayni payload |
| Chat `!istek` sistem satirlari | `_onMusicRelatedChatMessage` | Flash + kuyruk sync tetikler |

## Test plani

1. Web'de `!istek Tarkan Dudu` yaz:
   - Flutter chat'te istek satiri gorunmeli.
   - Flutter mini player/kuyruk SSE veya socket ile guncellenmeli.
2. Flutter'da `!istek` yaz:
   - Web sohbetinde ayni mesaj gorunmeli.
   - Web kuyrugu guncellenmeli.
3. Flutter Müzik Aç modalindan ucretli sarki iste:
   - `/song-request` kullanilmali.
   - Jeton dusmeli veya yetersiz jeton mesaji donmeli.
   - Web kuyrugunda sarki gorunmeli.
4. Web DJ sarki atla/degistir:
   - Flutter `nowPlaying`, `musicUrl`, `musicQueue` guncellenmeli.
5. Sonradan ikinci Flutter kullanicisi odaya gir:
   - `GET /music-queue` ile mevcut kuyrugu otomatik almali.
6. Uygulama arka plana alin:
   - Android/iOS media session muzik calmayi surdurmeli.

## Kalan riskler

1. Gercek Next.js web kaynak kodu bu repoda yok; web UI davranisi API mirror
   uzerinden cikarildi.
2. Production `youtube-stream` endpointi bazi durumlarda watch URL fallback
   donebilir; Flutter bunu Piped/Invidious/youtube_explode ile telafi eder.
3. YouTube kaynakli stream URL'leri zamanla gecersiz olabilir; resolver cache
   invalidation ve retry uygulanmistir.
4. Web tarafinda kuyruk DB modeli uretimde farkli olabilir; Flutter response
   aliaslari buna toleransli hale getirildi.

## Sonuc

Flutter muzik sistemi, mevcut Canlifal web/API sozlesmesine gore:

- `!istek` komutu
- Ucretli muzik istegi
- Sarki arama
- Sarki kuyrugu
- Sarki degistirme
- Mini player
- Socket/SSE senkronizasyonu
- Sonradan odaya giren kullanici
- Arka plan oynatma

alanlarinda mevcut backend API'leriyle hizalanmistir. Yeni backend, yeni API
veya yeni database tablosu olusturulmamistir.

