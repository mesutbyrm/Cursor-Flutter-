# Sesli Sohbet Odası — Flutter / Backend Senkronizasyon Raporu

**Tarih:** 4 Ağustos 2026  
**Sürüm:** `1.0.124+158`  
**Referans:** `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` §9.3 (ChatRoomRepository)

---

## Özet

Bu oturumda sesli sohbet odası için üretim backend sözleşmesine uygun tam senkronizasyon hedeflendi. Yeni endpoint veya mock eklenmedi; yalnızca mevcut REST + SSE + TRTC akışları güçlendirildi.

---

## 1. Odadan çıkış

| Adım | Uygulama |
|------|----------|
| State/SSE anında kesilir | `leaveRoomSession(awaitBackend: false)` — önce yerel state, SSE release, gift/PK |
| TRTC | `voiceRoomAudioCoordinator.leave()` ≤600ms timeout |
| Backend leave | `_leaveRoomBackend()` arka planda |
| Navigator | RTC/Basic sayfa hemen `pop` — Future beklemez |
| PK Socket | `disconnectSocket()` eklendi |

**Dosyalar:** `chat_room_providers.dart`, `voice_room_rtc_page.dart`, `voice_room_basic_page.dart`

---

## 2. Videolu hediyeler

- Backend `engineDurationMs` / `durationMs` birebir kullanılır (12s zorlama kaldırıldı).
- `VoiceGiftAmbientOverlay` video süresini `VideoPlayerController` ile senkronlar.
- `gift_session_controller` watchdog backend süresine uyumlu.

**Dosyalar:** `gift_engine_parser.dart`, `voice_gift_ambient_overlay.dart`, `gift_session_controller.dart`

---

## 3–4. !istek müzik + YouTube

- Akış: `!istek` → chat → `pendingMusicSearchQuery` → arama sheet → `POST song-request` → SSE `dj_update` → `_applyDjPlayback`.
- YouTube parse yalnızca backend URL/videoId üzerinden; `music-stream` + `youtube-stream` fallback.
- Hoparlör kapalıyken `_applyDjPlayback` muted — oynatma başlamaz.

**Dosyalar:** `chat_room_providers.dart`, `room_music_remote_datasource.dart`

---

## 5. Koltuk altı 1×1 video

- `VoiceRoomSeatVideoStrip` — aktif videolu müzikte `YoutubeVideoBackground(compact: true)` 56×56.

---

## 6. Müzik istek butonu

- `VoiceRoomSpecFooter` — mesaj gönder üstünde altın müzik ikonu.
- Görünürlük: `VoiceMusicAccess.canRequestSongs` + jeton bakiyesi.

---

## 7. Çevrimiçi sayısı

- `VoiceRoomLiveState.hubOnlineCount` — backend/SSE snapshot.
- `onlineCountFor()` = max(presence, hubOnlineCount, room.displayOnline).
- AppBar: `VoiceHeaderOnlineBadge` jeton (`💎`) yanında premium rozet.
- Koltuk üstü “X kişi çevrimiçi” metni kaldırıldı (`voice_premium_stage.dart`).

---

## 8. Mikrofon / hoparlör

| Kural | Uygulama |
|-------|----------|
| Mikrofon kapalı | TRTC `muteLocalAudio(true)` — kanaldan çıkmadan |
| Hoparlör kapalı | `muteAllRemoteAudio` + DJ pause + video clear + hediye SFX yok |
| Hoparlör açılınca | Müzik yalnızca `backgroundMusicEnabled` ise devam |
| UI gate | `VoiceRoomUiState.effectiveMusicMuted`, `roomOutputEnabled` |

**Dosyalar:** `trtc_room_manager.dart`, `voice_room_audio_coordinator.dart`, `voice_room_ui_provider.dart`, `gift_session_controller.dart`

---

## 9. Performans

- Mevcut: `RepaintBoundary`, SSE hub ref-count, gift prefetch pool, `DevicePerfTuning`.
- Yeni: Seat video strip yalnızca aktif video modunda mount.

---

## 10. Test sonuçları

| Test | Sonuç |
|------|-------|
| `voice_room_sync_test.dart` | onlineCount + output gate |
| `gift_duration_parser_test.dart` | backend durationMs |
| `gift_session_controller_test.dart` | queue/FIFO |
| `gift_engine_sse_router_test.dart` | SSE motor |
| `sse_connection_hub_test.dart` | ref-count |
| Tam `flutter test` | CI gate |

---

## Değiştirilen dosyalar (özet)

- `chat_room_providers.dart` (+ presence, music, leave)
- `voice_room_rtc_page.dart`, `voice_room_basic_page.dart`
- `trtc_room_manager.dart`, `voice_trtc_engine.dart`, `voice_room_audio_coordinator.dart`
- `voice_room_ui_provider.dart`, `gift_session_controller.dart`
- `voice_gift_ambient_overlay.dart`, `gift_engine_parser.dart`
- `voice_web_room_header.dart`, `voice_header_online_badge.dart`
- `voice_room_seat_video_strip.dart`, `voice_room_spec_footer.dart`
- `voice_premium_stage.dart`, `chat_room_providers_presence.dart`
- `mobile/test/voice_room_sync_test.dart`
- `docs/FLUTTER_VOICE_ROOM_SYNC_REPORT.md`

---

## Backend ↔ Flutter parity kontrol listesi

- [x] `POST /api/chat/rooms/{id}/presence` join/leave
- [x] `POST /api/chat/rooms/{id}/voice` join/leave
- [x] SSE `dj_update`, `gift_*`, `music_*`
- [x] `POST song-request` + `music-stream`
- [x] TRTC token `/api/trtc/token`
- [x] Jeton — `walletBalancesProvider` + `VoiceMusicAccess`
