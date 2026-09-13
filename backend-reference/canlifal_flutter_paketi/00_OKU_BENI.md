# CanlıFal — Flutter Entegrasyon Envanteri

**Üretim tarihi:** 12 Eylül 2026 (BÖLÜM 22 dahil, yeniden taranmış) · **Kaynak:** canlı kod ağacı (checkpoint `B6: Kabul testi (29/29) + Flutter dokümanı`, canlifal.com'a yayınlandı)
**Taban URL:** `https://canlifal.com` · **Sürümlü taban:** `https://canlifal.com/api/v1`

Bu paket, Flutter uygulamasının mevcut web/backend sistemiyle **birebir** çalışabilmesi için gereken tüm teknik sözleşmeyi içerir. Önceki devir paketindeki dokümanların aksine bu envanter **F3–F9, §25 ve §90 güncellemelerinden sonra**, canlı koddan otomatik tarama ile üretilmiştir.

---

## Özet rakamlar

| Ölçüm | Değer |
|---|---|
| Route dosyası | **612** |
| Endpoint (path + method) | **953** |
| Endpoint grubu | **116** |
| Yönetici endpoint'i | 359 |
| Mobil JWT kabul eden rota (`FLUTTER_READY`) | 306 |
| Kimlik gerektirmeyen (açık) rota | 121 |
| Yalnız yönetim rotası (`ADMIN_ONLY`) | 175 |
| SSE (akış) endpoint'i | 21 |
| Veri modeli (tablo) | **268** (3302 alan) |
| Servis/kütüphane modülü | **118** |
| MCP sunucusu | **yok** (bkz. `MCP_VE_ENTEGRASYONLAR.md`) |

---

## Dosya rehberi

| Dosya | İçerik |
|---|---|
| `00_OKU_BENI.md` | Bu dosya — giriş ve harita |
| `FLUTTER_ENTEGRASYON_REHBERI.md` | Flutter tarafı uygulama planı, katman tasarımı, örnek kod |
| `AUTHENTICATION.md` | JWT/oturum modeli, giriş uçları, roller, hata kodları, 409 onay protokolü |
| `REALTIME.md` | SSE kanalları, olay adları, polling, WebRTC sinyalizasyonu, TRTC, push |
| `TUM_OZELLIKLER_HARITASI.md` | **Sitedeki 19 özellik alanının** (yönetim paneli dahil) uç nokta haritası — buradan başlayın |
| `ENDPOINTS.md` | 953 endpoint'in gruplu, okunabilir tablosu (auth, sınıf, admin, SSE, query, body) |
| `endpoint_classification.md` / `.json` | Her rotanın Flutter sınıfı: FLUTTER_READY / PUBLIC / ADMIN_ONLY / WEB_ONLY / INTERNAL / DEPRECATED_ALIAS |
| `admin_permissions.md` | Roller, guard'lar, 175 yönetim rotasının tam izin tablosu, denetim (audit) ve kritik onay protokolü |
| `websocket_events.md` | Tüm gerçek zamanlı olay adları ve yükleri |
| `BOLUM22_MULTIGUEST_PK_GIFTBOX.md` | Çoklu misafir + PK/Battle + Hediye Kutusu tam sözleşmesi |
| `live_stream_api.md` · `voice_room_api.md` · `gifts_coins_wallet_api.md` · `ranking_api.md` | Alan bazlı derinlemesine API belgeleri |
| `openapi.yaml` | OpenAPI 3.0.3 sözleşmesi (612 yol) — kod üretimi için |
| `flutter_integration_checklist.md` | Entegrasyon kontrol listesi |
| `endpoints_index.json` | Aynı envanterin makine okunur hali (auth, admin, sse, body/query alanları, idempotency, audit, ledger bayrakları) |
| `postman_collection.json` | İçe aktarılabilir Postman koleksiyonu (`baseUrl` + `token` değişkenli) |
| `DATA_MODELS.md` | 268 modelin alan/tip/Dart karşılık tablosu |
| `data_models.json` | Modellerin makine okunur hali (kod üretimi için) |
| `database_schema.sql` | Veritabanının tam DDL çıktısı |
| `SERVICES.md` | 118 servis modülü ve dışa açtıkları semboller |
| `MCP_VE_ENTEGRASYONLAR.md` | MCP durumu + dış servisler (TRTC, OneSignal, S3/R2, LLM, sosyal giriş) |
| `kaynak/` | Referans kaynak dosyaları: `prisma/schema.prisma`, `middleware.ts`, 27 kritik `lib/*.ts` (BÖLÜM 22 `live-guest.ts`, `gift-box.ts`, `pk-state.ts`, `gift-pk-score.ts` dahil) |

---

## En çok kullanılan endpoint grupları

| Grup | Endpoint |
|---|---|
| `admin` | 335 |
| `chat` | 61 |
| `video-streams` | 55 |
| `user` | 41 |
| `games` | 40 |
| `gifts` | 27 |
| `agency` | 22 |
| `auth` | 22 |
| `short-videos` | 21 |
| `live` | 19 |
| `fortune-tellers` | 18 |
| `fortunes` | 15 |
| `me` | 15 |
| `dreams` | 14 |

---

## Kritik kurallar (Flutter’ın uyması gerekenler)

1. **Tek kimlik başlığı:** `Authorization: Bearer <accessToken>`. Çerez kullanılmaz.
2. **Para birimleri:** `jetonBalance` (Jeton) çekilebilir tek birimdir; `credits` (CFC) ödül birimidir ve **paraya çevrilemez**. Arayüzde bunları karıştırmayın.
3. **409 `requiresConfirmation`** yanıtı hata değildir — onay akışıdır; aynı gövde `confirm: true` ile tekrar gönderilir.
4. **Ödeme bildirimi** (`POST /api/payments/notify`) artık `productType` (`jeton|cfc|gold`), `requestedAmount`, `requestedGoldDays`, `requestedGoldType`, `proofUrl` kabul eder.
5. **Ödeme geçmişi** (`GET /api/payments/notify`) **düz dizi** döner (geriye dönük uyumlu) ve her kayıt `statusLabel`, `statusColor`, `productLabel`, `requestedSummary`, `loadedSummary`, `adminMessage`, `wasCorrected`, `canDispute`, `isFinal`, `disputeTicketId` alanlarıyla zenginleştirilmiştir.
6. **Ödeme itirazı:** `POST /api/payments/notifications/{id}/dispute` — yalnızca sonuçlanmış ödemeler için, en az 10 karakter mesaj, aynı ödeme için ikinci itiraz **409**.
7. **Falcı listesi** (`GET /api/fortune-tellers`) artık `isGoldUser`, `favoriteCount`, `presenceLabel` döner; detayda ayrıca `isFavorited`.
8. **PK skor uçları** (`/api/live/pk/score`, `/api/chat/rooms/{id}/pk/score`) **yalnızca yönetici**dir. Skor normal akışta hediye gönderiminden sunucu tarafında hesaplanır — istemci skor göndermez.
9. **Yayın canlılığı:** yayın süresince `POST /api/video-streams/{id}/media-heartbeat` gönderilmezse yayın sunucu tarafından kapatılır.
10. **Derin bağlantılar** `lib/deeplink.ts` şemasıyla üretilir; push bildirim yönlendirmeleri bu şemayı bekler.

---

## Doğrulama notu

Endpoint, model ve servis sayıları kod ağacı taranarak üretildi. `endpoints_index.json` içindeki `bodyFields` ve `queryParams` alanları statik kod analizinden gelir; çoğu route için eksiksizdir, ancak dinamik olarak okunan alanları kapsamayabilir. Şüpheli bir uç için `endpoints_index.json` içindeki `file` alanı ilgili kaynak dosyayı gösterir.
