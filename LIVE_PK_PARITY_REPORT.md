# Canlifal Web ↔ Flutter Live & PK Parity Report

Tarih: 2026-06-10

## Kaynaklar

- Web/API sozlesmesi: `api/src/routes/video_streams.ts`, `api/src/routes/pk_battles.ts`
- PK servis mantigi: `api/src/lib/pkBattleService.ts`
- Socket sozlesmesi: `api/src/socket/giftHub.ts`
- Flutter live datasource: `mobile/lib/features/live/data/datasources/live_remote_datasource.dart`
- Flutter live extras: `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart`
- Flutter PK datasource/provider: `mobile/lib/features/voice_hub/data/datasources/pk_battle_remote_datasource.dart`, `pk_battle_remote_provider.dart`
- Flutter live PK UI: `live_pk_invite_page.dart`, `live_pk_battle_page.dart`, `live_broadcast_room_page.dart`

## Web/API sozlesmesi

| Alan | Endpoint / event | Davranis |
|---|---|---|
| Yayin listesi | `GET /api/video-streams` | `streams/items/data` listesi doner |
| Yayin detayi | `GET /api/video-streams/:id` | `stream` ve flat stream payload doner |
| Yayin baslatma | `POST /api/video-streams` | `title`, `description`, `category`, `tags`, `thumbnailUrl`; stream live olur |
| Takipci bildirimi | `POST /api/video-streams/:id/live-started` | Yayina baslandi bildirimi |
| Yayin kapatma | `POST /api/video-streams/:id/end` | Sadece yayin sahibi; `streamEnded` / `STREAM_ENDED` socket |
| Izleyici giris/cikis | `POST /api/video-streams/:id/join`, `/leave` | Viewer count guncellenir; socket viewer event |
| Mesaj | `GET/POST /api/video-streams/:id/messages` | `streamMessage`, `chatMessage`, `message` socket |
| Begeni | `POST /api/video-streams/:id/like` | Kumulatif like count |
| Sinyal | `GET/POST /api/video-streams/:id/signal` | WebRTC/legacy polling |
| Co-broadcast | `POST /api/video-streams/:id/co-broadcast/invite`, `/co-broadcast` | Davet/yanit |
| Live PK create | `POST /api/video-streams/:id/pk-battle` | `opponentStreamId` zorunlu |
| Live PK state | `GET /api/video-streams/:id/pk-battle` | `battle/pk/full` doner |
| PK genel | `/api/pk/battles`, `/api/pk/battles/:id/accept`, `/reject`, `/end`, `/api/pk/history` | Davet/kabul/red/bitis/gecmis |
| PK skor | Gift entegrasyonu (`applyPkGift`) | Skor hediye puaniyla hesaplanir; `action: score` sozlesmede yok |
| PK socket | `pk:*`, `pkBattle`, `pkBattleUpdated`, `PK_UPDATED` | Iki tarafa yayinlanir |

## Flutter mevcut durum

| Kontrol | Flutter karsiligi | Durum |
|---|---|---|
| Yayin baslatma | `LiveRemoteDataSource.createVideoStream()` | Var |
| Takipci bildirimi | `videoStreamLiveStarted` cagrisi | Var |
| Yayin kapatma | `endVideoStream()` + fallback DELETE | Var |
| Viewer join/leave | `joinVideoStream`, `leaveVideoStream`, socket viewer count | Var |
| Live chat | `fetchStreamMessages`, `sendStreamMessage`, socket chat | Var |
| Hediye entegrasyonu | `LiveGiftsRemoteDataSource`, `LiveGiftSocketBridge`, `LiveGiftController` | Var |
| PK daveti | `LivePkInvitePage` → `inviteStream(opponentStreamId)` | Var |
| PK savaş ekranı | `LivePkBattlePage`, `LivePkScoreBar` | Var |
| PK skor | Remote battle + gift event refresh | Bu turda desteklenmeyen `action: score` kaldirildi |
| PK sonuc | Voice PK sonuc ekrani var; live PK sonuc detay ekrani kismi | Kismi |

## Bu turda uygulanan duzeltmeler

| Alan | Sorun | Duzeltme | Dosya |
|---|---|---|---|
| PK daveti | Canli yayin odasindaki `PK Başlat` butonu rakip yayin secmeden `create` cagiriyordu. Web/API `opponentStreamId` ister. | Buton artik `/live/pk-invite` rakip secim ekranina gider. | `live_broadcast_room_page.dart` |
| PK skor | Eski provider hediye sonrasi `action: score` gonderiyordu. Web/API skor hesaplamasi hediyelerle `applyPkGift` uzerinden yapiliyor; `score` action sozlesmede yok. | `addScore()` ve `action: score` kullanimi kaldirildi; hediye sonrasi remote battle refresh yapiliyor. | `live_video_pk_provider.dart`, `live_broadcast_room_page.dart` |

## Socket / realtime parity

| Event | Flutter listener | Durum |
|---|---|---|
| `joinStream`, `leaveStream` | `LiveGiftSocketBridge` | Var, reconnect'te tekrar join eder |
| `gift`, `giftSent` | `LiveGiftSocketBridge` | Var |
| `streamMessage`, `chatMessage`, `message` | `LiveGiftSocketBridge` | Var |
| `viewerCount`, `viewerCountUpdated` | `LiveGiftSocketBridge` | Var |
| `streamEnded`, `STREAM_ENDED` | `LiveGiftSocketBridge` + live room provider | Var |
| `pkBattle`, `pkBattleUpdated`, `PK_UPDATED` | `LiveGiftSocketBridge`, `PkBattleSocketService` | Var |
| `pk:score-update`, `pk:end`, `pk:winner` | Live bridge + PK socket | Var |

## Request / response model parity

| Model | Web/API alanlari | Flutter okunan alanlar | Durum |
|---|---|---|---|
| Live stream | `id`, `streamId`, `title`, `description`, `category`, `status`, `isLive`, `viewerCount/viewers/watching`, `thumbnailUrl/coverUrl/broadcastImage`, broadcaster fields | `LiveStreamDto.fromApiMap` | Uyumlu |
| Live create response | `stream`, `videoStream`, `broadcast`, flat `id/streamId` | `_extractStreamId` | Uyumlu |
| PK state | `battle`, `pk`, `full`, flat battle fields | `PkBattleRemote.fromJson` | Uyumlu |
| PK scores | `challengerScore/opponentScore`, `leftScore/rightScore` | `PkBattleRemote` | Uyumlu |
| PK result | `result`, `winnerId`, `winnerSide`, final scores | `PkResultRemote` | Uyumlu |
| PK gift | `recentGifts` | `PkGiftRemote` | Uyumlu |

## Test plani

1. Flutter host yayin baslatir:
   - `POST /api/video-streams` basarili.
   - `POST /api/video-streams/:id/live-started` basarili veya toleransli skip.
2. Web/Flutter izleyici yayina girer:
   - `joinStream` ve `viewerCount` socket senkron olur.
3. Host `PK Başlat` tiklar:
   - Rakip yayin secim ekrani acilir.
   - Rakip secilmeden create cagrisi yapilmaz.
4. Rakip secilir:
   - `POST /api/video-streams/:id/pk-battle` `opponentStreamId` ile gider.
   - `pk:invite` / `pkBattle` socket gelir.
5. Rakip kabul eder:
   - `/api/pk/battles/:id/accept` veya route action ile state active olur.
6. Hediye gonderilir:
   - API `applyPkGift` skor hesaplar.
   - Flutter remote battle refresh/socket ile skor gunceller.
   - `action: score` gonderilmez.
7. PK bitirilir:
   - `/api/pk/battles/:id/end` cagrilir.
   - Sonuc/winner payloadlari guncellenir.

## Kalan riskler

1. Gercek Next.js web UI kaynak kodu bu repoda yok; UI birebirligi API mirror
   uzerinden cikarildi.
2. Live PK sonuc ekrani voice PK sonuc ekranina gore daha kismi; webdeki live
   sonuc UI birebir dogrulanmadi.
3. Production `/api/pk/*` deploy durumu onceki dokumanlarda gap olarak
   isaretlenmisti; canli smoke test gerekli.
4. TRTC remote video split screen cihaz testi gerektirir.

## Sonuc

Canli yayin ve PK Flutter akisi mevcut Canlifal web/API sozlesmesiyle su
basliklarda hizalanmistir:

- Yayin baslatma
- Yayin kapatma
- PK daveti
- PK savas ekrani
- Skor hesaplama
- Hediye entegrasyonu
- Sonuc/bitis state'i

Bu turda desteklenmeyen `action: score` kaldirildi ve rakipsiz PK create yerine
web/API ile uyumlu rakip secim akisi kullanildi. Yeni backend, yeni API veya
yeni database tablosu olusturulmadi.

