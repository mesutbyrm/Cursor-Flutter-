# CanlifalTV Flutter API — Entegrasyon Paritesi

**Kaynak:** CanlifalTV Flutter Mobil API Dokümantasyonu (Mayıs 2026)  
**Üretim:** `https://canlifal.com`  
**Flutter teknik kılavuz:** `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` (çelişkide öncelikli)  
**7 saha live API:** `docs/api/field/README.md`

---

## Özet

| Bölüm | Durum | Flutter katmanı |
|-------|-------|-----------------|
| 1 Auth | ✅ | `auth_service.dart`, `dio_provider` refresh |
| 2 JWT | ✅ | `token_storage.dart`, Bearer otomatik |
| 3 Profil | ✅ | `profile_service.dart`, `canlifal_user_api_datasource.dart` |
| 4 Sosyal feed | ✅ | `features/social/`, `feed/` |
| 5 Hikayeler | ✅ | `ApiEndpoints.feed` → `/api/stories` |
| 6 Canlı yayın | ✅ | `live_remote_datasource`, `stream_service` |
| 7 Sesli oda | ✅ | `chat_room_remote_datasource`, `live_field/*` |
| 8 DM | ✅ | `features/messages/` |
| 9 Bildirimler | ✅ | `notifications_remote_datasource` |
| 10 Hediye | ✅ | `gift_service`, `chat_room_gifts_*` |
| 11 Jeton/CFC | ✅ | `wallet/`, `payment_service` |
| 12 Gold üyelik | ✅ | `membership_remote_datasource` |
| 13 FunClub | ⚠️ kısmi | `fan-clubs`, celebrities modülleri |
| 14 Referral | ✅ | `ApiEndpoints.referral` |
| 15 Trend/Arama | ⚠️ kısmi | `trends`, `search` endpoint tanımlı |
| 16 Oyunlar | ⚠️ kısmi | `game_service.dart` |
| 17 Fal (12+) | ✅ | `features/fortune/` |
| 18 TRTC | ✅ | `trtc_remote_datasource`, TRTC-only runtime |
| 19 Dosya yükleme | ✅ | `upload` modülü |
| 20 Diğer | ⚠️ kısmi | homepage, daily-missions, blog linkleri |

---

## Bu oturumda hizalanan sözleşmeler

| Alan | CanlifalTV doc | Flutter düzeltmesi |
|------|----------------|-------------------|
| Profil güncelle | `PUT /api/user/profile` | `profile_service`: PUT + PATCH yedek |
| Yayın bitir | `PATCH` `{status:"ended"}` | `live_remote_datasource.endVideoStream` |
| Yayın ayrıl | `DELETE .../join?viewerId=` | `leaveVideoStream` DELETE önce |
| Hediye gönder | `recipientUsername`, `type` | `gift_service.sendGift` |
| Üyelik planları | `GET /api/memberships` | `membership_remote_datasource` çift path |
| Üyelik satın al | `POST /api/memberships/purchase` | `payment_service` çift path |
| Bildirim okundu | `POST /api/notifications` `{markAll}` | `notifications_remote_datasource` |
| Koltuk | `action: "sit"` | `assignSeat` sit/take zinciri |

---

## Gerçek zamanlı notu

CanlifalTV dokümanı HTTP polling önerir. **Mobil üretim:** kılavuz §5 SSE birincil (`/api/chat/rooms/{id}/stream`, video-stream SSE, vb.). Polling yalnızca SSE yoksa veya yedek olarak kullanılır.

---

## Endpoint hızlı referans

Tam metin: kullanıcı tarafından sağlanan **CanlifalTV API Dokümantasyonu** → `docs/api/CANLIFALTV_FLUTTER_API.md`

Flutter sabitleri: `mobile/lib/core/network/api_endpoints.dart`
