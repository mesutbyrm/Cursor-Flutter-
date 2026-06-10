# Canlifal Web ↔ Flutter Live & PK Audit Report

Tarih: 2026-06-10

## Kapsam

Bu rapor Canlifal.com web canli yayin ve PK sisteminin Flutter
uygulamasindaki karsiligini uçtan uca denetler.

Kontrol edilen basliklar:

- Yayin baslatma
- Yayin kapatma
- PK daveti
- PK kabul / red
- PK savas ekrani
- Skor sistemi
- Hediye entegrasyonu
- Yayin sonlandirma
- Sonuc ekranlari

Kaynaklar:

- `api/src/routes/video_streams.ts`
- `api/src/routes/pk_battles.ts`
- `api/src/lib/pkBattleService.ts`
- `api/src/socket/giftHub.ts`
- `mobile/lib/features/live/data/datasources/live_remote_datasource.dart`
- `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart`
- `mobile/lib/features/live/presentation/providers/live_video_pk_provider.dart`
- `mobile/lib/features/live/presentation/pages/live_broadcast_room_page.dart`
- `mobile/lib/features/live/presentation/pages/live_pk_invite_page.dart`
- `mobile/lib/features/live/presentation/pages/live_pk_battle_page.dart`
- `mobile/lib/features/voice_hub/data/datasources/pk_battle_remote_datasource.dart`
- `mobile/lib/features/voice_hub/presentation/providers/pk_battle_remote_provider.dart`

Not: Gercek Next.js web istemci kaynak kodu bu repoda yoktur. Denetim mevcut
API mirror, uretim dokumanlari ve Flutter kodu uzerinden yapilmistir.

## Web/API sozlesmesi

| Islem | Endpoint / event | Beklenen davranis |
|---|---|---|
| Yayin listesi | `GET /api/video-streams` | `streams/items/data` listesi |
| Yayin detayi | `GET /api/video-streams/:id` | `stream` ve flat stream payload |
| Yayin baslatma | `POST /api/video-streams` | Stream live olarak olusur |
| Takipci bildirimi | `POST /api/video-streams/:id/live-started` | Push/in-app bildirim tetikler |
| Yayin kapatma | `POST /api/video-streams/:id/end` | `streamEnded` / `STREAM_ENDED` socket |
| Viewer join/leave | `POST /api/video-streams/:id/join`, `/leave` | Viewer count socket ile senkron |
| Live chat | `GET/POST /api/video-streams/:id/messages` | `streamMessage`, `chatMessage`, `message` socket |
| Live like | `POST /api/video-streams/:id/like` | Kumulatif like count |
| PK daveti | `POST /api/video-streams/:id/pk-battle` + `opponentStreamId` | `pk:invite`, `pkBattle` yayinlanir |
| PK kabul | `/api/pk/battles/:id/accept` veya route action | Battle active olur; `pk:accept`, `pk:start` |
| PK red | `/api/pk/battles/:id/reject` | Battle rejected olur |
| PK bitis | `/api/pk/battles/:id/end` | Battle ended olur; winner/result |
| PK skor | Hediye entegrasyonu: `applyPkGift` | `giftToPkPoints()` ile skor hesaplanir |
| PK socket | `pk:*`, `pkBattle`, `pkBattleUpdated`, `PK_UPDATED` | Iki yayin tarafina gider |

## Flutter audit sonucu

| Kontrol | Flutter karsiligi | Durum |
|---|---|---|
| Yayin baslatma | `LiveRemoteDataSource.createVideoStream()` | Gecti |
| Yayin kapatma | `LiveRemoteDataSource.endVideoStream()` | Gecti |
| Yayin sonu socket | `LiveGiftSocketBridge` `streamEnded` / `STREAM_ENDED` | Gecti |
| PK daveti | `LivePkInvitePage` rakip yayin secip `inviteStream()` cagirir | Gecti |
| PK kabul/red | `PkBattleRemoteController.accept/reject()` | Gecti |
| PK savas ekrani | `LivePkBattlePage` + `LivePkScoreBar` | Gecti |
| Skor sistemi | Remote battle skor state'i + hediye entegrasyonu | Gecti |
| Hediye entegrasyonu | `LiveGiftController`, `LiveGiftsRemoteDataSource`, `applyPkGift` response/socket | Gecti |
| Sonuc ekranlari | Voice PK sonuc ekrani var; live PK sonuc UI kismi | Kismi |

## Bu turda uygulanan duzeltme

| Alan | Sorun | Duzeltme | Dosya |
|---|---|---|---|
| PK request payload | `LiveStreamExtrasDataSource.pkAction()` desteklenmeyen `score` ve `side` alanlarini tum action payloadlarina ekliyordu. Web/API sozlesmesinde skor hediye ile hesaplanir; `score` action yoktur. | `score` ve `side` parametreleri ve payload alanlari kaldirildi. | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart` |

## Önceki turda dogrulanan duzeltmeler

| Alan | Durum |
|---|---|
| `PK Başlat` | Artik direkt create cagirmiyor; rakip yayin secim ekranina gider |
| Rakip secimi | `LivePkInvitePage` `opponentStreamId` ile davet yollar |
| Hediye sonrasi skor | Eski `action: score` kaldirildi; remote battle refresh/socket kullanilir |

## Request / response model audit

| Model | Web/API alanlari | Flutter parser | Durum |
|---|---|---|---|
| Live stream | `id`, `streamId`, `title`, `status`, `viewerCount`, `thumbnailUrl`, `broadcasterId`, `broadcasterName` | `LiveStreamDto.fromApiMap` | Uyumlu |
| Create stream response | `stream`, `videoStream`, `broadcast`, flat `id/streamId` | `_extractStreamId()` | Uyumlu |
| PK response | `battle`, `pk`, `full`, flat battle | `_unwrapBattle()` / `PkBattleRemote.fromJson` | Uyumlu |
| PK score | `challengerScore`, `opponentScore`, `leftScore`, `rightScore` | `PkBattleRemote` | Uyumlu |
| PK result | `winnerId`, `winnerSide`, final scores, `championBadge` | `PkResultRemote` | Uyumlu |
| Gift score | `recentGifts`, `points`, `side`, `quantity` | `PkGiftRemote` | Uyumlu |

## Socket audit

| Event | Flutter listener | Durum |
|---|---|---|
| `joinStream` / `leaveStream` | `LiveGiftSocketBridge` | Var |
| `gift` / `giftSent` | `LiveGiftSocketBridge` | Var |
| `streamMessage` / `chatMessage` / `message` | `LiveGiftSocketBridge` | Var |
| `viewerCount` / `viewerCountUpdated` | `LiveGiftSocketBridge` | Var |
| `streamEnded` / `STREAM_ENDED` | `LiveGiftSocketBridge` | Var |
| `pkBattle` / `pkBattleUpdated` / `PK_UPDATED` | Live bridge + PK socket | Var |
| `pk:invite`, `pk:accept`, `pk:reject`, `pk:start`, `pk:score-update`, `pk:gift`, `pk:end`, `pk:winner` | `PkBattleSocketService` | Var |

## Test plani

1. Flutter host yayin baslatir:
   - `POST /api/video-streams`
   - `POST /api/video-streams/:id/live-started`
2. Web/Flutter izleyici yayina girer:
   - `joinStream`
   - viewer count guncellenir
3. Host PK baslatir:
   - Rakip secim ekrani acilir
   - Rakip secilmeden create cagrisi yapilmaz
4. Rakip secilir:
   - `POST /api/video-streams/:id/pk-battle` `opponentStreamId` ile gider
5. Rakip kabul eder:
   - `accept` endpointi battle state'i active yapar
6. Hediye gonderilir:
   - API `applyPkGift` skor hesaplar
   - Flutter remote battle/socket ile skor gunceller
   - `score`/`side` alanlari gonderilmez
7. PK bitirilir:
   - `end` endpointi result/winner olusturur
8. Yayin kapatilir:
   - `POST /api/video-streams/:id/end`
   - `streamEnded` / `STREAM_ENDED` socket gelir

## Kalan riskler

1. Gercek Next.js web UI kaynak kodu bu repoda yoktur.
2. Production `/api/pk/*` route deploy durumu canli smoke test gerektirir.
3. Live PK sonuc UI, voice PK sonuc ekranina gore daha kisidir; webdeki tam
   sonuc ekran birebirligi manuel test ister.
4. TRTC split screen ve remote video cihaz testi gerektirir.

## Sonuc

Canli yayin ve PK sistemi mevcut web/API sozlesmesine gore yayin baslatma,
yayin kapatma, PK daveti, PK kabul/red, skor, hediye entegrasyonu ve yayin
sonlandirma alanlarinda Flutter tarafinda hizalanmistir.

Bu audit turunda desteklenmeyen `score` / `side` request payload kalintilari
kaldirildi. Yeni backend, yeni API veya yeni database tablosu olusturulmadi.

