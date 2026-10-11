# Canlifal — Hediye Sistemi Flutter Rehberi

> **Backend referans:** canlifal `full-source` — PR [#38](https://github.com/mesutbyrm/canlifal/pull/38) (`clientPrice` + katalog cache invalidation).  
> **Geniş sistem dokümanı:** [`CANLIFAL_HEDIYE_SISTEMI_DOKUMANTASYONU.md`](CANLIFAL_HEDIYE_SISTEMI_DOKUMANTASYONU.md) · **API kılavuz:** [`FLUTTER_ENTegrasyon_KILAVUZU.md`](FLUTTER_ENTegrasyon_KILAVUZU.md) §9.

Bu rehber, mobil istemcinin web ile **aynı hediye davranışını** sürdürmesi için Flutter tarafındaki zorunlu parçaları özetler.

---

## 1. `clientPrice` gönderimi ve 409 işleme

| Uç | Dosya |
|---|---|
| `POST /api/chat/rooms/{id}/gifts` | `chat_room_gifts_remote_datasource.dart` |
| `POST /api/video-streams/{id}/gifts` | `live_gifts_remote_datasource.dart` |
| `POST /api/gifts/send` (kısa video) | `shorts_remote_datasource.dart` |
| Birleşik `POST /api/live/gift/send` | `live_field_gift_api.dart` (opsiyonel alan; üretimde yoksa yok sayılır) |

- Gönderim gövdesine **birim jeton** olarak opsiyonel `clientPrice` eklenir (`gift_client_price.dart` → `giftClientPriceFields`).
- Sunucu fiyat uyuşmazlığında **`409`** + `code: PRICE_MISMATCH` (+ `serverPrice`) döner.
- **`ApiException.fromDio`** 409 + `PRICE_MISMATCH` eşlemesi yapar.
- UI hata yakalama: `handleGiftSendFailure` → katalog cache bust + `giftSendUserMessage` («Fiyat güncellendi…»).

---

## 2. Katalog versiyon senkronizasyonu (polling)

- `gift_catalog_version_watcher.dart` — **45 sn** aralıkla `fetchCatalogVersion()`; sürüm artınca `syncCatalogIfNeeded(forceRefresh: true)` + provider invalidate.
- Admin CRUD sonrası sunucu cache temizliği (PR #38) ile birlikte istemci tarafında **409** sonrası `invalidateAllGiftCatalogs` zorunlu yenileme yapar.

---

## 3. SSE `eventId` ile dedup

- `gift_session_controller.dart` — `GiftEngineSseRouter.dedupeKey`, `_maxProcessedIds`, join grace, REST yanıtı + SSE çift oynatma engeli (`_awaitingAnimationKeys`).
- Oda SSE: kılavuz §5 chat room stream; hediye motoru `GiftEngineSseAction`.

---

## 4. Tek bildirim şeridi

Web’deki «GiftNotificationStrip» karşılığı mobilde:

| Bileşen | Rol |
|---|---|
| `GiftNotificationStack` | Canlı yayın chat üstü kompakt banner (max 2) |
| `GlobalGiftQueue` + `GlobalGiftNotification` | Uygulama geneli tek aktif şerit, `maxQueue` |
| `voice_seat_gift_flash_stack` / `live_seat_gift_flash_stack` | Koltuk mini flaş |

---

## 5. Video player lifecycle

- `gift_session_controller.dart` — `_videoHoldId`, `_videoHoldUntilMs`, `GiftVideoHold` ile tam ekran MP4 bitene kadar sıradaki animasyon bekletilir.
- `gift_animation_player.dart` — video controller dispose / mount kontrolü.

---

## 6. Animasyon süresi güvenliği (clamp)

- `gift_engine_parser.dart` — `durationMs`, `queueGapMs`, `feedDurationMs`, `startDelayMs`, `combo` clamp.
- `gift_render_meta.dart` / `gift_animation_policy.dart` — katalog + event süreleri **800–20000 ms** bandında.

---

## 7. Queue taşma koruması

- `global_gift_queue.dart` — admin `maxQueue` (varsayılan 10); taşan kayıtlar düşürülür.
- `gift_session_controller.dart` — animasyon kuyruğu ve feed sınırları (`_maxRecent`, combo replay clamp).

---

## 8. `assetFormat` bazlı renderer seçimi

- `gift_media_type.dart` — `mediaType` / `assetType` / `assetFormat` → dal (PNG, SVGA, Lottie, MP4).
- `gift_animation_player.dart` — katalog + SSE event birleşimi; `GiftMediaSpec.resolve`.
- `gift_event_catalog_enricher.dart` — eksik format URL’den türetme.

---

## Kontrol listesi (release)

- [ ] Tüm hediye POST’larında `clientPrice` (birim fiyat) gönderiliyor mu?
- [ ] 409 sonrası katalog yenileniyor mu?
- [ ] Version watcher açık mı (`main_app_shell`)? 
- [ ] SSE dedup log’larında çift animasyon yok mu?
- [ ] MP4 hediyede dispose sonrası crash yok mu?

**İlgili test:** `mobile/test/features/gifts/gift_client_price_test.dart`
