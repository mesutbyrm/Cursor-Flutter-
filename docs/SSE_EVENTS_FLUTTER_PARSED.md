# SSE Events — Flutter Parser Referansı (FAZ 0)

**Tarih:** 2026-08-18  
**Kaynak:** Mevcut Flutter kodu (uydurma yok). Resmi backend şeması gelene kadar geçici referans.  
**Stream:** `GET /api/chat/rooms/{roomId}/stream`

Kaynak dosyalar:
- `mobile/lib/features/voice_hub/domain/entities/chat_room_sse_event.dart`
- `mobile/lib/features/voice_hub/presentation/utils/voice_sse_dj_payload.dart`
- `mobile/lib/features/voice_hub/music/domain/entities/room_playback_sync.dart`

---

## Müzik / DJ olayları (P0)

| `type` (ve alias) | Flutter enum | Oynatma tetikler? | Beklenen alanlar |
|-------------------|--------------|-------------------|------------------|
| `dj`, `dj_update`, `djevent` | `dj` | Evet (`shouldApplyDjPlaybackFromSongSse`) | `playing`, `isPlaying`, `musicUrl`, `nowPlaying`, `musicQueue` |
| `song_started` | `songStarted` | Evet | `nowPlaying` / `currentSong`, `musicUrl`, `videoId`, `elapsedMs` |
| `song_resumed` | `songResumed` | Evet | Aynı |
| `song_changed` | `songChanged` | Evet | Aynı |
| `queue_updated` | `queueUpdated` | Evet | `queue` / `musicQueue` |
| `music_started`, `musicstarted` | `musicStarted` | Evet | `playing: true` |
| `music_stopped`, `musicstopped` | `musicStopped` | Durdur | `playing: false` |
| `player_state` | `playerState` | Koşullu | `musicUrl`, `playing` |
| `song_paused` | `songPaused` | Hayır (duraklat) | — |
| `song_finished` | `songFinished` | Hayır | — |

### `nowPlaying` / şarkı nesnesi

Flutter şu anahtarları okur: `musicUrl`, `videoUrl`, `youtubeUrl`, `videoId`, `title`, `withVideo`, `requestType`, `playMode`, `embedUrl`, `streamUrl`.

Sarmalayıcılar: `data`, `payload`, `dj` (iç içe birleştirilir).

---

## Oda / presence

| `type` | Alias | Alanlar |
|--------|-------|---------|
| `presence` | `roomusers`, `users` | `onlineUsers`, `roomId` |
| `user_join` | `join`, `userjoined` | kullanıcı bilgisi |
| `user_leave` | `leave`, `userleft` | kullanıcı bilgisi |
| `typing` | — | yazıyor göstergesi |

---

## PK

| `type` | Alias |
|--------|-------|
| `pk` | `pk_battle`, `pk_score`, `pk_invite`, `pk_ended`, `gift_ranking_updated`, … |

---

## Diğer

| `type` | Açıklama |
|--------|----------|
| `message` | Sohbet mesajı |
| `gift` | Hediye animasyonu |
| `moderation` | ban/mute |
| `announcement` | duyuru |
| `fortune_request` | canlı fal isteği |
| `connected`, `heartbeat` | bağlantı |

---

## Backend'den hâlâ istenen

1. Her müzik olayı için **gerçek JSON örneği** (oda `cmoohrbr`, `!istek` sonrası)
2. Alan adlarının canonical listesi (web ile birebir)
3. Diğer SSE stream'ler: notifications, live video, fortune, PK

Bkz. `docs/BACKEND_REQUIREMENTS_TO_REQUEST.md` Eksik #5.
