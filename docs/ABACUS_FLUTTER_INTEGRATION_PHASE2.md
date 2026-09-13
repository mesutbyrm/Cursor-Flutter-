# Abacus entegrasyon — Aşama 2 raporu

> **Tarih:** 2026-09-13  
> **Referans:** `backend-reference/canlifal_flutter_paketi/` (değiştirilmedi)  
> **Önceki:** `docs/ABACUS_FLUTTER_INTEGRATION_REPORT.md` (Aşama 1)

---

## 1. Değiştirilen dosyalar

| Dosya | Özet |
|-------|------|
| `mobile/lib/features/gifts/data/gift_idempotency.dart` | `Idempotency-Key` başlığı (`giftIdempotentPostOptions`) |
| `mobile/lib/features/live/data/datasources/live_gifts_remote_datasource.dart` | Yayın hediye POST + idempotency header |
| `mobile/lib/features/voice_hub/data/datasources/chat_room_gifts_remote_datasource.dart` | Oda hediye POST + idempotency header |
| `mobile/lib/features/live/data/datasources/live_field/live_field_gift_api.dart` | `POST /api/live/gift/send` + idempotency header |
| `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart` | Presence heartbeat: `POST` (OpenAPI; PATCH kaldırıldı) |
| `mobile/lib/core/economy/domain/economy_wallet_snapshot.dart` | `GET /api/wallet` düz alanları (`jetonBalance`, `cfcBalance`, `credits`, `coins`) |
| `mobile/lib/features/voice_hub/domain/entities/chat_room_sse_event.dart` | SSE `gift_received` (websocket_events.md) |
| `mobile/test/core/economy/economy_integration_test.dart` | Düz cüzdan JSON testi |
| `docs/ABACUS_FLUTTER_INTEGRATION_PHASE2.md` | Bu rapor |

---

## 2. Her değişikliğin nedeni

| Değişiklik | Abacus kaynağı |
|------------|----------------|
| Idempotency başlığı | `gifts_coins_wallet_api.md` §4, OpenAPI `idempotent` |
| Presence heartbeat POST | `openapi.yaml` `/api/chat/rooms/{roomId}/presence` — GET/POST/DELETE (PATCH yok); `voice_room_api.md` §2 |
| Cüzdan düz JSON | `gifts_coins_wallet_api.md` §2 `GET /api/wallet` örneği |
| `gift_received` SSE | `websocket_events.md` §2.3 |

Aşama 1 düzeltmeleri **geri alınmadı** (tema PATCH, reciprocal POST, oyun liderlik GET, bildirim POST, burç GET, referral/wallet/fal erişim).

---

## 3. Kullanılan backend endpointleri (doğrulanmış özet)

### Authentication
- `POST /api/auth/mobile-login`, `mobile-refresh`, `mobile-register`
- `POST /api/auth/logout`, `GET /api/me`
- `GET /api/mobile/config`, `POST`/`DELETE /api/devices/fcm`
- **Uygulanmadı (mobilde eksik / doğrulanmış ama UI yok):** `POST /api/auth/logout-all`, `GET/DELETE /api/auth/sessions` — OpenAPI’de var, tam oturum yönetimi ekranı yok

### Kullanıcı / profil
- `GET/PATCH /api/me`, `GET/PATCH /api/user/theme` (Aşama 1)
- Mevcut profil datasource’lar OpenAPI ile uyumlu (ek değişiklik gerekmedi)

### Coin / wallet
- `GET /api/wallet` birincil + `GET /api/user/wallet` yedek
- Yanıt: düz `jetonBalance` / `cfcBalance` / `credits` desteği eklendi
- `GET /api/jeton`, `POST /api/jeton` `{ action: daily_login }` — mevcut kodda kullanılıyor

### Hediyeler
- `POST /api/video-streams/{streamId}/gifts` + idempotency header
- `POST /api/chat/rooms/{roomId}/gifts` + idempotency header
- `POST /api/live/gift/send` + idempotency header
- `POST /api/gifts/check-reciprocal` `{ recipientId }` (Aşama 1)
- `GET /api/gifts/catalog`, `types`, `version`, `recent-big`

### Gift box
- OpenAPI: `/api/gift-box`, `/api/gift-box/{boxId}`, `/api/gift-box/{boxId}/join`, `/api/gift-box/share`
- **Flutter:** modül/ekran yok → **uygulanmadı** (uydurma yapılmadı)

### Canlı yayın
- Doğrulanmış ve mevcut: `POST /api/video-streams`, `GET/PATCH` detay, `POST join`, `DELETE join`, `POST leave` yedek, `POST live-started`, `POST media-heartbeat`, `POST end`, SSE `GET .../stream`, co-broadcast/guest uçları `api_endpoints.dart`’ta
- **Değişiklik:** hediye idempotency header

### Sesli sohbet
- `POST/GET/DELETE /api/chat/rooms/{roomId}/presence` (join/leave/heartbeat)
- SSE `GET .../stream`, koltuk `GET/PATCH .../seats`, speak-request ailesi
- **Değişiklik:** heartbeat PATCH → POST

### PK
- SSE `GET /api/pk/{matchId}/stream`; skor **sunucu/hediye** (`gift-pk-score.ts` — Flutter skor POST etmez, dokümana uygun)
- Games host router mevcut

### Realtime / SSE
- 6 kanal `websocket_events.md` ile hizalı; `gift_received` sesli oda parser’a eklendi
- WebSocket **kullanılmıyor** (dokümana uygun)

### Bildirimler
- `GET/POST/DELETE /api/notifications`, SSE stream; okundu `POST` (Aşama 1)

### Sıralamalar
- Birincil `GET /api/leaderboards`; yedek `/api/leaderboard` (Abacus OpenAPI’de **yok** — yalnız fallback)

### Üyelik / ajans / müzik
- Mevcut endpoint sabitleri OpenAPI ile örtüşüyor; bu aşamada ek kod değişikliği gerekmedi

---

## 4–11. Durum özetleri

| Alan | Durum |
|------|--------|
| **Authentication** | JWT + refresh + logout + `/api/me` doğrulandı; logout-all/sessions UI eksik |
| **Live stream** | Yaşam döngüsü uçları mevcut; heartbeat/live-started kullanılıyor |
| **Voice room** | Presence tabanlı giriş; heartbeat OpenAPI POST |
| **Gift** | Idempotency header + bağlam uçları |
| **Wallet/Coin** | `/api/wallet` düz JSON parse |
| **PK** | SSE + hediye skoru sunucu tarafı; client skor POST yok |
| **Realtime** | SSE only; `gift_received` sesli oda |

---

## 12. Test sonuçları

```bash
cd mobile && dart analyze   # 0 error
cd mobile && flutter test test/core/economy/economy_integration_test.dart
cd mobile && flutter test test/core/network/api_endpoint_canonical_contract_test.dart
```

---

## 13. Doğrulanamayan / uygulanmayan

| Konu | Neden |
|------|--------|
| `POST /api/user/fortunes` kayıt | OpenAPI yalnız GET + PATCH `{fortuneId}` |
| `PATCH /api/payments/requests` iptal | OpenAPI yalnız GET + POST |
| Burç `zodiacSign` query | OpenAPI yalnız `lang` (`GET /api/horoscope/daily`) |
| Gift box UI/API katmanı | Flutter’da özellik yok |
| RTMP/HLS push URL | `live_stream_api.md` MISSING |
| Oda “tek tık kapat” | `voice_room_api.md` MISSING merkezi uç |

---

## 14. Kalan backend eksikleri (istemci tarafı)

- Oturum listesi / tüm cihazlardan çıkış (`/api/auth/sessions`, `logout-all`) — ekran yok
- Gift box ürün akışı — backend hazır, mobil yok
- Fal kaydı POST — backend sözleşmesi net değil; mevcut POST yedek korunuyor (Aşama 1’den)

---

## Referans bütünlüğü

`backend-reference/canlifal_flutter_paketi/**` dosyalarına **yazılmadı / değiştirilmedi**.
