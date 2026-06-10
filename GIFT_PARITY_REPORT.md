# Canlifal Web ↔ Flutter Gift Parity Report

Tarih: 2026-06-10

## Kaynaklar

- Web/API hediye sozlesmesi: `api/src/routes/gifts.ts`
- Socket eventleri: `api/src/socket/giftHub.ts`
- Flutter live gift datasource: `mobile/lib/features/live/data/datasources/live_gifts_remote_datasource.dart`
- Flutter live gift controller: `mobile/lib/features/live/presentation/gifts/live_gift_controller.dart`
- Flutter voice gift datasource: `mobile/lib/features/voice_hub/data/datasources/chat_room_gifts_remote_datasource.dart`
- Flutter voice gift UI: `voice_room_gift_sheet.dart`, `voice_premium_gift_panel_2026.dart`
- Hediye animasyon/ses: `mobile/lib/features/gifts/`

## Web/API sozlesmesi

| Islem | Endpoint / event | Davranis |
|---|---|---|
| Hediye katalog | `GET /api/gifts?platform=mobile|web`, `GET /api/video-streams/gifts?platform=mobile` | `id/slug/giftTypeId`, `name/nameTr`, `icon/iconUrl`, `animation`, `animationType`, `price`, `rarity`, `platform`, `sound` doner |
| Canli yayin hediye gonder | `POST /api/video-streams/:streamId/gifts` | Jeton duser, `GiftEvent` olusturur, `gift/giftSent` socket yayinlar, PK skorunu guncelleyebilir |
| Canli yayin hediye listesi | `GET /api/video-streams/:streamId/gifts` | Son hediye olaylarini doner |
| Canli yayin liderlik | `GET /api/video-streams/:streamId/gifts/leaderboard` | Gonderen bazli 24 saatlik liderlik |
| Sesli oda hediye gonder | `POST /api/chat/rooms/:roomId/gifts` | Jeton duser, `GiftEvent` olusturur, `gift/giftSent` oda socket yayinlar, PK skorunu guncelleyebilir |
| Sesli oda hediye listesi | `GET /api/chat/rooms/:roomId/gifts` | Son oda hediyelerini doner |
| Socket yayin | `gift`, `giftSent` | Web ve Flutter ayni payload alias'larini okur |

## Flutter parity durumu

| Kontrol | Flutter karsiligi | Durum |
|---|---|---|
| Hediye gonderme | `LiveGiftsRemoteDataSource.sendGift`, `ChatRoomGiftsRemoteDataSource.sendGift` | Var |
| Hediye alma | `LiveGiftSocketBridge`, `VoiceRoomGiftSocket`, realtime services | Var |
| Jeton dusme | API `newBalance/balance/coinBalance` parse edilir; `coinBalanceProvider` invalidate edilir | Var |
| Canli yayin gorunumu | `LiveGiftController`, `GiftNotificationStack`, `PremiumGiftFullscreenOverlay` | Var |
| Sesli oda gorunumu | `VoicePremiumGiftPanel2026`, `VoiceGiftFlightQueue`, leaderboard tracker | Var |
| Animasyonlar | Lottie/Rive/SVGA/premium painter fallback | Var |
| Ses efektleri | `GiftSoundService` | Bu turda sesli oda premium + legacy picker'a eklendi |
| Combo | Canli yayin controller ve voice combo tracker | Var |
| PK etkisi | API `pkBattle` payload parse edilir; socket PK eventleri ayrica dinlenir | Var/kismi, prod route smoke test gerekli |

## Bu turda uygulanan duzeltmeler

| Alan | Sorun | Duzeltme | Dosya |
|---|---|---|---|
| Sesli oda premium hediye sesi | Canli yayin hediye akisi `GiftSoundService` kullanirken sesli oda premium panelinde basarili gonderim sonrasi ses/haptic calismiyordu | `giftSoundServiceProvider.playFor(g.toEntity())` eklendi | `voice_premium_gift_panel_2026.dart` |
| Sesli oda legacy hediye sesi | Legacy picker da hediye sesi caldirmiyordu | Ayni `GiftSoundService` cagrisi eklendi | `voice_room_gift_sheet.dart` |

## Request / response model uyumu

| Model | Web alanlari | Flutter okunan alanlar | Durum |
|---|---|---|---|
| Gift catalog | `id`, `slug`, `giftTypeId`, `name`, `nameTr`, `icon`, `iconUrl`, `animation`, `animationKey`, `animationType`, `price`, `rarity`, `platform`, `sound`, `sortOrder` | `GiftEntity.fromJson`, `LiveVideoGiftType.fromGift` | Uyumlu |
| Gift event | `id`, `senderId`, `senderName`, `receiverId`, `receiverName`, `giftTypeId`, `giftId`, `giftName`, `giftTypeName`, `quantity`, `count`, `price`, `coinCost`, `combo`, `comboCount`, `icon`, `iconUrl`, `animation`, `animationKey`, `animationType`, `rarity`, `sound`, `createdAt`, `timestamp` | `LiveGiftsRemoteDataSource.parseGiftEvent` | Uyumlu |
| Send result | `newBalance`, `balance`, `coinBalance`, `streamerBalance`, `pkBattle` | `LiveGiftSendResult` ve provider invalidate | Uyumlu |

## Socket parity

| Event | Web/API | Flutter |
|---|---|---|
| `gift` | Canli yayin ve sesli oda icin yayinlanir | `LiveGiftSocketBridge`, `VoiceRoomGiftSocket` dinler |
| `giftSent` | Alias event | `LiveGiftSocketBridge`, `VoiceRoomGiftSocket` dinler |
| PK gift events | `pk:gift`, `pk:score-update`, `PK_UPDATED` | `PkBattleSocketService` ve live bridge dinler |

## Animasyon ve ses parity

| Alan | Flutter |
|---|---|
| Lottie | `GiftCatalogMaps.lottieAsset`, `PremiumGiftFullscreenOverlay` |
| Rive | `GiftCatalogMaps.riveAsset` |
| SVGA | `GiftCatalogMaps.svgaAsset` + painter fallback |
| Premium painter fallback | `PremiumGiftCatalog2026`, `PremiumGiftIcon` |
| Ses | `GiftSoundService` asset sound → rarity sound → system sound fallback |
| Haptic | Rarity'ye gore light/medium/heavy impact |

## Test plani

1. Canli yayinda hediye gonder:
   - Jeton duser.
   - Gonderen/alici isimleri dogru gorunur.
   - Animasyon ve ses/haptic calisir.
   - Web ve Flutter ayni socket eventini gorur.
2. Sesli odada hediye gonder:
   - Jeton duser.
   - Oda icinde hediye event/animasyon gorunur.
   - Bu surumle ses/haptic calisir.
3. Web'den hediye gonder:
   - Flutter `gift`/`giftSent` eventini alir.
   - Bildirim/animasyon kuyruguna girer.
4. Flutter'dan hediye gonder:
   - Web tarafinda ayni event gorunur.
5. Yetersiz jeton:
   - API 402 `INSUFFICIENT_COINS` mesajini Flutter snackbar olarak gosterir.
6. PK aktifken hediye:
   - `pkBattle` response ve PK socket eventleri skor guncellemesini tetikler.

## Kalan riskler

1. Gercek Next.js web kaynak kodu bu repoda yoktur; UI birebirligi API mirror
   ve uretim envanterinden cikarildi.
2. Hediye asset katalogu webde daha genis olabilir; Flutter local asset
   bulunmadiginda premium painter fallback kullanir.
3. Web tarafindaki tam animasyon zamanlamasi gorsel test gerektirir.
4. PK gift skorunun production'da calismasi `/api/pk/*` route deploy durumuna
   baglidir.

## Sonuc

Flutter hediye sistemi mevcut Canlifal web/API sozlesmesine gore:

- Hediye gonderme
- Hediye alma
- Jeton dusme
- Animasyonlar
- Oda ici gorunum
- Canli yayin gorunumu
- Ses efektleri

alanlarinda hizalanmistir. Bu turda sesli oda hediye ses/haptic parity eksigi
giderildi. Yeni backend, yeni API veya yeni database tablosu olusturulmadi.

