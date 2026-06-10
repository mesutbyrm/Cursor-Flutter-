# Canlifal Web ↔ Flutter Music End-to-End Audit Report

Tarih: 2026-06-10

## Kapsam

Bu rapor Canlifal.com web muzik sistemi ile Flutter sesli oda muzik sistemini
uçtan uca denetler.

Kontrol edilen basliklar:

- `!istek` komutu
- Sarki arama
- Sarki kuyrugu
- Mini player
- Oda ici senkronizasyon
- Arka plan oynatma
- Ucretli muzik istegi
- Sarki gecme
- Sarki bitince sonraki sarki

Kaynaklar:

- API mirror: `api/src/routes/chat_rooms.ts`, `api/src/lib/chatRoomStore.ts`
- Flutter remote datasource: `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart`
- Flutter live state: `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers.dart`
- Music UI: `mobile/lib/features/voice_hub/presentation/pages/voice_music_hub_page.dart`
- Mini player: `mobile/lib/features/voice_hub/presentation/widgets/voice_room/voice_room_music_mini_player.dart`
- Background player: `mobile/lib/features/voice_hub/presentation/services/voice_room_dj_player.dart`
- Stream resolver: `mobile/lib/features/voice_hub/data/youtube_stream_resolver.dart`
- Socket/SSE: `voice_room_sse_service.dart`, `voice_room_gift_socket.dart`

Not: Gercek Next.js web istemci kaynak kodu bu repoda yoktur. Bu audit mevcut
API sozlesmesi, yerel API mirror, Flutter kodu ve CI kanitlari uzerinden
yapilmistir.

## Audit ozeti

| Kontrol | Web/API davranisi | Flutter davranisi | Durum |
|---|---|---|---|
| `!istek` komutu | `POST /api/chat/rooms/:roomId/messages`; server `addTextMessage()` icinde `/istek` parse edip `requestMusicQueue(skipPayment: true)` cagirir | `VoiceRoomLiveController.sendMessage()` komutu dogrudan mesaj endpointine yollar; server sonucu bekler ve music sync tetikler | Gecti |
| Sarki arama | `GET /api/music/search?q=...`; eski/yedek `/api/youtube/search`, `/api/chat/youtube-search`; populer katalog | Flutter once web API, sonra eski endpoint, populer katalog, client YouTube fallback dener | Gecti |
| Sarki kuyrugu | `GET /api/chat/rooms/:roomId/music-queue`; `queue/cost/musicEnabled/nowPlaying/playing/musicUrl` | `fetchMusicQueue()` `queue`, `musicQueue`, `items` aliaslarini okur | Gecti |
| Mini player | DJ state + kuyruk + playback durumu | `VoiceRoomMusicMiniPlayer` background player state, duration, progress, play/pause/stop/skip gosterir | Gecti |
| Oda ici senkron | SSE `type:dj`, Socket.IO `dj/music/QUEUE_UPDATED/CURRENT_SONG_CHANGED` | SSE ve socket payloadlari `_applyDjRealtimePayload()` ile state/player'a islenir | Gecti |
| Arka plan oynatma | Web iframe/audio farkli; mobilde native background gerekir | `just_audio + audio_service`; Android/iOS background media session | Gecti |
| Ucretli muzik istegi | `POST /song-request`, `priority: true`, jeton kontrolu | `VoiceMusicHubPage._submit()` `requestMusic(priority: true)` kullanir; jeton kontrolu yapar | Gecti |
| Sarki gecme | `POST /music-queue/advance` | `skipMusic()` endpointi cagirir ve `refresh()` yapar | Gecti |
| Sarki bitince sonraki | `advanceMusicQueue()` kuyruktan siradakini baslatir | `VoiceRoomDjPlayer.onTrackComplete` → `_onDjTrackComplete()` → `advanceMusicQueue()` + refresh | Gecti |

## Uygulanan duzeltme kanitlari

| Surum | Duzeltme | Kanit |
|---|---|---|
| `1.0.166+168` | Web API sonuc vermezse mobil YouTube arama ve stream manifest fallback | `youtube_explode_dart`, `YoutubeStreamResolver` |
| `1.0.167+169` | `just_audio + audio_service` background playback | `voice_room_dj_player.dart`, Android/iOS ayarlari |
| `1.0.169+171` | Socket/SSE event listener parity | `voice_room_gift_socket.dart`, `SOCKET_PARITY_REPORT.md` |
| `1.0.170+172` | Queue/metadata response alias uyumu | `MusicQueueItem`, `ChatRoomDjState`, `fetchMusicQueue()` |

## Endpoint matrisi

| Islem | Endpoint | Flutter kullaniyor mu? |
|---|---|---|
| Arama | `GET /api/music/search?q=` | Evet |
| Eski arama | `GET /api/youtube/search?q=` | Evet, fallback |
| Populer muzik | `GET /api/chat/music/popular` | Evet, fallback |
| Stream cozme | `GET /api/chat/youtube-stream` | Evet |
| Queue oku | `GET /api/chat/rooms/:id/music-queue` | Evet |
| Ucretli istek | `POST /api/chat/rooms/:id/song-request` | Evet |
| Yedek queue post | `POST /api/chat/rooms/:id/music-queue` | Evet, fallback |
| Sarki gec | `POST /api/chat/rooms/:id/music-queue/advance` | Evet |
| Queue item sil | `DELETE /api/chat/rooms/:id/music-queue/:itemId` | Evet |
| Queue temizle | `DELETE /api/chat/rooms/:id/music-queue` | Evet |
| Ayarlar | `PATCH /api/chat/rooms/:id/music-settings` | Evet |
| DJ state | `GET/POST /api/chat/rooms/:id/dj` | Evet |
| `!istek` | `POST /api/chat/rooms/:id/messages` | Evet |

## Request / response model audit

| Model | Beklenen web alanlari | Flutter parser durumu |
|---|---|---|
| Search hit | `videoId`, `id`, `title`, `url`, `thumbnail`, `thumbUrl`, `channelTitle`, `channel`, `duration` | Alias destekli |
| Queue item | `id`, `videoId`, `title`, `youtubeUrl`, `url`, `thumbUrl`, `thumbnail`, `image`, `requestedBy`, `user`, `giftTo`, `note`, `uploader`, `channelTitle`, `channel`, `artist`, `duration` | Alias destekli |
| DJ state | `musicUrl`, `playing`, `nowPlaying`, `musicQueue`, `queue`, `items`, `musicRequestCost`, `maxMusicQueue`, `musicEnabled` | Alias destekli |
| Queue response | `queue`, `musicQueue`, `items`, `cost`, `musicRequestCost`, `maxMusicQueue`, `canRequestMusic`, `musicUrl`, `playing` | Alias destekli |
| Request response | `item`, `queue`, `musicQueue`, `items`, `newBalance`, `coinBalance`, `queuePosition`, `musicUrl`, `playing` | Alias destekli |

## Runtime test kisitlari

Bu ortamda Android/iOS cihaz, TRTC runtime ve gercek web istemci oturumu yoktur.
Bu nedenle fiziksel cihazda asagidaki manuel testler yine yapilmalidir:

1. Web'de `!istek` yazildiginda Flutter kuyruk/mini player guncellemesi.
2. Flutter'da `!istek` yazildiginda web kuyruk guncellemesi.
3. Flutter ucretli istek sonrasi jeton dusumu ve web kuyruk gorunumu.
4. Sarki bitince sonraki sarkiya otomatik gecis.
5. Uygulama arka plana alindiginda muzik notification/control center ile surmesi.

## Son CI kaniti

Son genel basarili APK:

- Surum: `1.0.173+175`
- Run: <https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27248704892>
- `Dependencies`: basarili
- `Analyze`: basarili
- `Build release APK`: basarili
- `apk-latest`: yayinlandi

Muzik audit raporu dokuman olarak eklendi; yeni kod degisikligi gerektirmez.

## Sonuc

Muzik sisteminde bu audit sirasinda yeni bir kod hatasi tespit edilmedi.
Mevcut Flutter implementasyonu web/API sozlesmesi ile su alanlarda uyumludur:

- `!istek`
- Sarki arama
- Queue okuma/yazma
- Ucretli istek
- Mini player
- Realtime SSE/socket sync
- Background playback
- Sarki gecme
- Sarki bitince sonraki sarkiya gecme

