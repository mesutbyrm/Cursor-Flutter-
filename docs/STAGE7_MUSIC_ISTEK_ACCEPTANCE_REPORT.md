# Aşama 7 — !İstek + Müzik Sistemi Acceptance Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 UTC |
| API | https://canlifal.com |
| Flutter sürüm | 1.0.144+178 |
| Dal | `cursor/backend-flutter-sync-0cde` |
| Gerçek cihaz | **Yok** (`adb devices` boş) |
| Test hesabı | jeton=0, audio istek=10 jeton (backend mesajı) |

## Özet

Kod incelemesi ve API testleri tamamlandı. **Üç kritik Flutter hatası düzeltildi.** Gerçek cihazda ses çıkışı, pause/stop, iki cihazlı SSE senkronu ve jeton düşümü E2E **doğrulanmadı** — Aşama 7 **PASS değil**.

---

## Ödeme testi (BLOCKED-BY-TEST-ACCOUNT)

| Alan | Değer |
|------|--------|
| BEFORE BALANCE | 0 |
| REQUEST PRICE | 10 jeton (audio, backend hata mesajı) |
| ACTUAL DEDUCTION | — |
| AFTER BALANCE | 0 |
| TRANSACTION | HTTP 400 `Yetersiz jeton. 10 jeton gerekiyor.` |
| QUEUE STATUS | Değişmedi (ödeme reddedildi) |
| PLAYBACK STATUS | — (cihaz testi yok) |

---

## Sonuç tablosu

| FEATURE | RESULT | ROOT CAUSE | FIX | RETEST |
|---------|--------|------------|-----|--------|
| COMMAND PARSE | **PASS** (kod) / **BLOCKED** (cihaz) | — | `VoiceMusicSync.parseIstekSongTitle`; `!istek` → arama sheet | Unit/kod OK |
| SEARCH | **PASS** | Auth gerekli | `GET /api/music/search?q=` Bearer — Tarkan Dudu 12 sonuç | API ✅ |
| SONG SELECT | **BLOCKED-BY-DEVICE** | Cihaz yok | `voice_youtube_song_sheet` ses/video seçici | Cihaz |
| AUDIO PRICE | **PASS** (API) | — | Backend: 10 jeton; Flutter `dj.musicRequestCost` | API mesajı |
| VIDEO PRICE | **BLOCKED-BY-TEST-ACCOUNT** | Ödeme yapılamadı | `dj.videoRequestCost` (varsayılan 2× audio) | Fonlu hesap |
| JETON TRANSACTION | **PASS** (kod) / **BLOCKED** (E2E) | Local düşüm yok | `newBalance` song-request yanıtı; pre-check only | Cihaz+jeton |
| SONG REQUEST | **PASS** (insufficient) / **BLOCKED** (success) | Bakiye 0 | `POST …/song-request` `requestType` audio/video | API 400 ✅ |
| QUEUE | **PASS** (API) / **BLOCKED** (cihaz) | — | Backend `music-queue` source of truth | API ✅ |
| SSE DJ EVENT | **PASS** (connect) / **BLOCKED** (playback) | Cihaz yok | `RoomSongBloc.eventFromSse` + `VoiceRoomDjSyncMixin` | API stream ✅ |
| AUDIO PLAYBACK | **BLOCKED-BY-DEVICE** | Cihaz yok | `just_audio` + backend `musicUrl` | Cihaz |
| VIDEO PLAYBACK | **BLOCKED-BY-DEVICE** | Cihaz yok | YouTube video mode ayrı dal | Cihaz |
| PAUSE | **PASS** (kod fix) / **BLOCKED** (cihaz) | Pause API sonrası player durmuyordu | `pauseMusic` → `player.pause()` | Cihaz |
| RESUME | **BLOCKED-BY-DEVICE** | — | `updateDj` action play + `_applyDjPlayback` | Cihaz |
| STOP | **BLOCKED-BY-DEVICE** | — | SSE stopped → `player.stop()` | Cihaz |
| NEXT | **BLOCKED-BY-DEVICE** | — | `skipMusicQueue` POST action skip | Cihaz |
| AUTO NEXT | **BLOCKED-BY-DEVICE** | — | `onTrackComplete` → skip | Cihaz |
| ROOM SWITCH | **PASS** (kod) / **BLOCKED** (cihaz) | — | `prepareForRoomEntry` stop; leave cleanup | Kod mevcut |
| BACKGROUND | **BLOCKED-BY-DEVICE** | — | `VoiceRoomMusicLifecycleHost` detached shutdown | Cihaz |
| INSUFFICIENT BALANCE | **PASS** | — | HTTP 400 yetersiz jeton | API ✅ |
| DUPLICATE REQUEST | **PASS** (kod fix) / **BLOCKED** (cihaz) | Aynı videoId tekrar eklenebiliyordu | `submitSelectedSong` kuyruk kontrolü | Cihaz |
| CLEANUP | **PASS** (kod) / **BLOCKED** (cihaz) | — | `leaveRoomSession` SSE release + player | Kod mevcut |

---

## Düzeltilen kod hataları

1. **`room_music_repository_impl.dart`** — `switch` fall-through: `pause` çağrısı ardından `resume`/`stop`/`next` de çalışıyordu
2. **`room_music_remote_datasource.dart`** — `pauseDj` DELETE `/music` (kuyruk silme) yerine POST `action: pause`
3. **`chat_room_providers_playback.dart`** — `pauseMusic` yerel `just_audio` duraklatmıyordu (ses devam ediyordu)
4. **`chat_room_providers.dart`** — Aynı `videoId` kuyrukta tekrar istek engeli

---

## API test çıktısı

```
✅ SEARCH — 12 sonuç (videoId, title, thumbnail)
✅ AUTH — token
✅ QUEUE — kuyruk OK, audio=10 jeton
✅ SONGREQ — HTTP 400 yetersiz jeton
✅ SSE_DJ — stream açık
```

Detay: `mobile/docs/API_MUSIC_PHASE_REPORT.md`

---

## Kritik bug kontrolleri (cihaz gerekli)

| Bug | Kod durumu | Cihaz |
|-----|------------|-------|
| Mini player var ses yok | `waitUntilPlaying` 30s doğrulama var | BLOCKED |
| audio URL null | Pipeline log + SSE `musicUrl` | BLOCKED |
| SSE geliyor player tetiklenmiyor | `_applyDjRealtimePayload` | BLOCKED |
| Aynı şarkı iki kez | Dedupe signature + duplicate guard | Kısmen kod |
| Stop ama ses devam | pause fix uygulandı | BLOCKED |
| Oda değişince eski şarkı | `prepareForRoomEntry` stop | BLOCKED |
| Jeton düşmeden kuyruk | `skipPayment: false` !istek | API insufficient ✅ |

---

## Aşama 7 kararı

| Durum | Açıklama |
|-------|----------|
| **KOD** | Switch fall-through, pause ses, duplicate request düzeltildi |
| **API** | Search, queue, insufficient, SSE connect PASS |
| **CİHAZ** | Playback, pause/resume/stop/next, background BLOCKED |
| **Final performans / release** | **Geçilmez** — iki cihaz + fonlu hesap retest gerekli |

### Retest için gerekenler

1. İki Android cihaz, aynı voice room
2. ≥10 jeton (audio) / ≥20 jeton (video test)
3. `!istek Tarkan Dudu` → seç → ses modu → ödeme → SSE → ses çıkışı doğrula
4. Pause / resume / stop / next / oda değiştir / background
