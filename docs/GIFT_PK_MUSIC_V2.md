# GIFT + PK + MUSIC V2 — Aşama 8 Raporu

**Dal:** `cursor/gift-pk-music-v2-premium-5ac6`  
**Sürüm:** `1.0.327+363`  
**Tarih:** 2026-08-21

Bu aşama; hediye, PK, müzik/!istek ve oda içi etkileşim akışlarını mevcut backend API + SSE mimarisine hizalar. Tencent RTC, Agora ve Socket.IO eklenmedi; yeni endpoint uydurulmadı.

---

# GIFT

## API

| İşlem | Endpoint | Repository / dosya |
|--------|----------|-------------------|
| Hediye türleri | `GET /api/live/gift-types` | `live_field_gift_api.dart`, `voiceRoomGiftTypesProvider` |
| Hediye gönder (sesli oda) | `POST /api/live/gift/send` | `chat_room_gifts_remote_datasource.dart` |
| Hediye gönder (canlı yayın) | `POST /api/video-streams/{id}/gifts` | `live_gifts_remote_datasource.dart` |

Katalog backend'den gelir; fiyat/görsel/isim hardcode edilmez. Gönderim yalnızca başarılı REST yanıtından sonra UI'da kalıcı başarı gösterir; hata: **«Hediye gönderilemedi»**.

## Wallet

- Gönderim sonrası `refreshWalletCache(force: true)` (tek çağrı; çift refresh kaldırıldı).
- SSE/REST yanıtında `remainingBalance` varsa gönderen kullanıcı için `WalletBalancesNotifier.applyJetonFromServer()` ile anında jeton senkronu (`gift_event_listener.dart`).
- Flutter kendi matematiğiyle backend bakiyesini ezmez.

## Event

- Birincil yol: oda SSE `GET /api/chat/rooms/{roomId}/stream` + gift engine router.
- Dedup: `gift_session_controller.dart` — `id`, `giftHistoryId`, `queueItemId`; sıfır jeton olayları atlanır.
- Oda izolasyonu: `room_event_scope.dart` + `gift_event_listener` aktif oda kontrolü.

## Animation

- Animasyon yalnızca SSE/realtime kaynaklarından (`sse`, `voice_realtime`, `live_realtime`, …).
- REST yanıtı client-side animasyon tetiklemez; engine dedupe ile çift animasyon engellenir.
- `jetonAmount` = backend `totalCoin` öncelikli (`LiveGiftEvent.jetonAmount`).

## Ranking

- Oda: `voiceSessionGiftLeaderboardProvider`, `voice_gift_leaderboard_provider.dart`.
- Canlı: `live_gift_leaderboard_provider.dart`.
- PK skoru ayrı kanal: PK remote state (`pkBattleRemoteProvider`).

---

# PK

## Request

- `POST /api/live/pk` — `pk_battle_remote_datasource.dart` (`inviteVoiceRoom`).
- Karşı taraf UI: `VoicePkInviteListener` + SSE `onPk` + REST yedek `GET /api/pk/me/invites`.
- Fake local dialog yok; davet backend/SSE üzerinden gelir.

## Accept / Reject

- `POST /api/live/pk` action: `accept` / `reject` — mevcut body formatı korunur.
- Sonuç her iki cihazda SSE + remote state ile güncellenir.

## State

- Backend status değerleri parse edilir: `pending`, `active`, `rejected`, `ended`, …
- `PkBattleRemote` + `pkBattleForRoomProvider` oda kapsamlı görünüm.
- **Düzeltme:** `pk_battle_provider` sahte `_baseScore` (8000+hash) kaldırıldı; shell skorları 0'dan başlar.

## Score

- Sunucu otoriter modda (`serverAuthoritative: true`) skor `applyRemoteBattle*` ile backend'den gelir.
- Hediye PK skoruna REST yanıtındaki `pkBattle` + SSE ile yansır (`voice_gift_pk_sync.dart`).
- Yerel `applyGift` yalnızca alıcı/sender id çözülebilirse çalışır; hashCode tahmini kaldırıldı.

## Timer

- `PkBattleRemote.secondsLeft` backend'den; aktif PK'da periyodik tick yalnızca non-authoritative shell için.
- Sabit 90/120 sn hardcode yok (backend `durationSeconds` / `secondsLeft` kullanılır).

## Result

- Bitiş: backend `status=ended` + `result.winnerSide`; local timer ile kazanan belirlenmez.

---

# MUSIC

## Search

- `GET /api/youtube/search?q=...` — backend proxy; Flutter doğrudan YouTube Data API çağırmaz.

## Song Request

- `POST /api/chat/rooms/{roomId}/song-request` — `voice_music_submit.dart`.
- `!istek` ve UI arama aynı endpoint'e gider; JWT Bearer zorunlu.
- `skipPayment` backend kuralına göre (`voice_music_submit.dart`).

## Queue

- Backend kuyruk; Flutter ayrı queue oluşturmaz.
- SSE: `onSong`, `onSongQueue`, `onDjUpdate` — `chat_room_providers_sse.dart`.

## SSE

- `GET /api/chat/rooms/{roomId}/stream` — oda girişinde açılır, çıkışta kapanır.
- Tek oda = tek SSE bağlantısı (mevcut `chat_room_providers` lifecycle).

## Audio

- `just_audio` + `VoiceRoomDjPlayer` / `RoomMusicService`.
- Piped/backend audio URL kullanılır; YouTube watch URL doğrudan stream kabul edilmez.

## Player

- Mini player: mevcut DJ sync provider'ları (`chat_room_providers_dj_sync.dart`).
- Ses modunda yalnızca audio stream; gereksiz video decode yok.

## Cleanup

- `RoomMusicService.bindRoom()` — oda değişince stop + dedupe clear.
- `clearVoiceRoomLiveSession()` — gift session, recent gifts, seat totals temizliği.

---

# ROOM

## Room Isolation

- Yeni: `mobile/lib/core/room/room_event_scope.dart`
- Gift listener: yabancı oda sessionKey olayları ignore.
- Global gift overlay: aktif oda dışı toast engellendi.
- PK: `ingestSseBattle` yabancı oda active PK'sını global state'e yazmaz (pending davet istisnası).

## Event Deduplication

- Gift: `gift_session_controller` + `GiftEngineSseRouter`.
- Music: `RoomMusicPlaybackDedupe`.
- Global insights feed: `_seenFeedIds` (400 cap).

## Network Recovery

- SSE reconnect: mevcut exponential backoff (`chat_room_providers`).
- Gift send: Dio retry katmanı; duplicate payment için REST idempotency backend'e bağlı.
- PK poll yedek: `VoicePkInviteListener` 4 sn REST.

---

# TESTS

Çalıştırılan / eklenen:

| Test dosyası | Konu |
|--------------|------|
| `test/core/room_event_scope_test.dart` | Oda izolasyon helper |
| `test/features/voice_hub/pk_battle_shell_test.dart` | Sahte PK skor yok, gift taraf çözümleme |
| `test/features/gifts/gift_playable_filter_test.dart` | Sıfır fiyat filtresi |
| Mevcut gift/pk/music/sse test paketleri | Regresyon |

Komutlar:

```bash
cd mobile && dart analyze
cd mobile && flutter test test/core/room_event_scope_test.dart test/features/voice_hub/pk_battle_shell_test.dart test/features/gifts/ test/features/voice_hub/pk_* test/features/voice_hub/music_* test/voice_music_sync_test.dart test/gift_session_controller_test.dart
```

---

# MULTI DEVICE TESTS

Cloud ortamında fiziksel çift cihaz testi **yapılamadı**. Manuel senaryo:

1. **PK:** A → B davet; B kabul; her iki cihazda active PK + backend skor/timer.
2. **Gift:** A hediye gönderir; B doğru jeton miktarı + animasyon (tek) + PK skor güncellemesi görür.
3. **Music:** A `!istek`; B (DJ) kuyrukta görür; oda çıkışında müzik durur.

---

# BACKEND EKSİKLERİ

1. **`remainingBalance` tutarlılığı:** Bazı gift SSE payload'larında alan eksik olabilir; bu durumda tam senkron için `GET /api/user/credits` refresh gerekir.
2. **Canlı yayın gift path:** Video yayın hâlâ `/api/video-streams/{id}/gifts` kullanır; sesli oda ile birleşik `/api/live/gift/send` değil (backend tasarımı).
3. **PK davet hedef çözümleme:** `opponentVoiceRoomId` / `targetUserId` eksik geldiğinde REST poll yedek devreye girer; ideal olarak tüm PK SSE olaylarında roomId set edilmeli.

---

# FAKE/HARDCODE DATA

| Bulgu | Durum |
|-------|--------|
| `pk_battle_provider._baseScore` (8000+hash) | **Kaldırıldı** |
| `giftTargetsLeft` hashCode parity | **Kaldırıldı** — id tabanlı |
| `room_gift_panel` çift wallet refresh | **Düzeltildi** |
| `GiftPlayableFilter` price>=0 | **price>0** (sıfır jeton UI'da yok) |
| Discover mock (`VoiceRoomsMockData`) | Kapsam dışı (keşif ekranı) |

Production kodunda `testGift`, `fakeToken`, `0 Jeton` hardcode **bulunmadı** (gift session sıfır jeton olaylarını bilinçli filtreler).

---

# DEĞİŞEN DOSYALAR

| Dosya | Değişiklik |
|-------|------------|
| `mobile/lib/core/room/room_event_scope.dart` | **Yeni** — oda izolasyon helper |
| `mobile/lib/features/voice_hub/presentation/providers/pk_battle_provider.dart` | Sahte skor/timer streak kaldırıldı; gift taraf id eşlemesi |
| `mobile/lib/features/voice_hub/presentation/providers/pk_battle_remote_provider.dart` | SSE PK oda filtresi |
| `mobile/lib/features/gifts/presentation/sync/gift_event_listener.dart` | Wallet sync + oda izolasyonu |
| `mobile/lib/features/gifts/presentation/global/global_gift_event_bridge.dart` | Global overlay oda filtresi |
| `mobile/lib/features/gifts/presentation/widgets/room_gift_panel.dart` | Çift refresh kaldırıldı |
| `mobile/lib/features/gifts/domain/gift_playable_filter.dart` | Sıfır fiyat filtresi |
| `mobile/lib/features/profile/presentation/providers/profile_providers.dart` | `applyJetonFromServer` |
| `mobile/test/core/room_event_scope_test.dart` | **Yeni** |
| `mobile/test/features/voice_hub/pk_battle_shell_test.dart` | **Yeni** |
| `mobile/test/features/gifts/gift_playable_filter_test.dart` | Sıfır fiyat testi |
| `mobile/pubspec.yaml` | `1.0.327+363` |
| `mobile/CHANGELOG.md` | Aşama 8 notları |
| `docs/GIFT_PK_MUSIC_V2.md` | Bu rapor |

---

**Not:** Tencent RTC / presence / seat mimarisi (Aşama 7) bu dalda ayrı commit gerektirmedi; oda izolasyon helper'ı bu aşamada gift/PK/music için eklendi.
