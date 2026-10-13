# CanlıFal — Durable Event Outbox (PR #49) · Flutter rehberi

> **Backend referans:** `591477e1` (squash merge PR #49) · `nextjs_space/lib/event-outbox.ts`  
> **Flutter tek kaynak:** [`FLUTTER_ENTegrasyon_KILAVUZU.md`](FLUTTER_ENTegrasyon_KILAVUZU.md) §5–6 (SSE)  
> **Tarih:** 13 Ekim 2026

---

## 1. Outbox nedir? (mobil açısından)

Backend, kritik olayları (SSE yayını, bildirim + push) **veritabanı outbox** tablosuna yazar, hemen teslim etmeyi dener; başarısız olursa arka plan işlemci (`drainOutbox`, ~2 sn) en fazla **5 deneme** ile tekrarlar.

**Mobilde yeni REST ucu yok.** İstemci aynı SSE kanallarını dinlemeye devam eder; fark, sunucunun hediye / bildirim tesliminin daha dayanıklı olmasıdır.

| Kanal (`channel`) | Teslim | Flutter dinleme |
|-------------------|--------|------------------|
| `sse_chat` | `emitChatEvent(roomId, …)` | `GET /api/chat/rooms/{id}/stream` |
| `sse_room` | `emitRoomEvent(roomId, …)` | Oda SSE (sesli hub) |
| `sse_stream` | `emitStreamEvent(streamId, …)` | `GET /api/video-streams/{id}/stream` |
| `notification` | `createNotificationWithPush` | Bildirim listesi + FCM + uygulama içi dinleyiciler |

---

## 2. Outbox’a alınan hediye akışları (591477e)

Aşağıdaki route’lar `durableEmitSSE` / `durableNotify` kullanır:

| Senaryo | REST | SSE hedef | Olay |
|---------|------|-----------|------|
| Sesli oda hediyesi | `POST /api/chat/rooms/{roomId}/gifts` | `sse_chat` | `gift` (+ motor `enginePayload` varsa öncelik) |
| Genel hediye | `POST /api/gifts/send` | push/notification | `gift_received` vb. |
| Canlı yayın | `POST /api/live/gift/send` | `sse_stream` / `sse_chat` | `gift` |
| Video stream | `POST /api/video-streams/{streamId}/gifts` | `sse_stream` | `gift` |

**Flutter beklentisi (780+ ile hizalı):**

1. **SSE birincil** — `room_event` / stream SSE içindeki `gift`, `gift_sent`, motor payload’ları.
2. **Idempotency** — Aynı `giftId` / event id ile gelen tekrarlar UI’da tek animasyon (voice gift orchestrator + seat flash dedupe).
3. **Alıcı cüzdanı** — `gift_event_listener`: alıcı jeton + profil invalidate (SSE veya push sonrası).
4. **Reconnect** — Kılavuz §6: exponential backoff, max 20, 401 → refresh → yeniden bağlan. Outbox gecikmesi birkaç saniye sürebilir; kısa reconnect yeterli.

---

## 3. Bildirim tipleri (outbox `notification` kanalı)

Hediye sonrası tipik push/in-app tipler (sunucu `notifyParams.type`):

- `gift_received` — alıcı
- `jeton_payment_approved` / `jeton_payment_rejected` — ödeme (outbox ile aynı desen)

Mobil: `jeton_payment_realtime_notifications.dart`, `gift_event_listener.dart`, bildirim SSE.

---

## 4. Flutter’da yapılmaması gerekenler

- Outbox tablosuna veya drain API’sine istek **atmayın** (admin/web only).
- Socket.IO eklemeyin — üretim **SSE-only**.
- Hediye için yalnızca REST yanıtına güvenip SSE’yi atlamayın (outbox teslimi SSE/push tarafında).

---

## 5. Test / doğrulama checklist (cihaz veya staging)

1. İki hesap, aynı sesli oda — A, B’ye hediye gönderir → B’de anında jeton + animasyon (refresh yok).
2. Uçak modu 5 sn → SSE kopması → geri gelince tek hediye animasyonu (çift banner yok).
3. Canlı yayında hediye → izleyici ve yayıncı skor/gift overlay.
4. Alıcı uygulama arka planda → push veya foreground’da bildirim + cüzdan güncellemesi.

---

## 6. Backend ↔ Flutter parity (591477e clone, `--used-only`)

Script: `python3 scripts/backend-route-parity.py canlifal-backend/nextjs_space --used-only`

| Durum | Yol | Flutter aksiyon |
|-------|-----|-----------------|
| Sunucuda yok | `/api/social-accounts`, `/api/admin/social-accounts` | Boş liste / admin hata mesajı (781+) |
| Sunucuda yok | `/api/agency/periods`, `/api/agency/wallet/transactions` | Yedek: `accruals`, `GET /api/agency/wallet` |
| Sunucuda yok | `/api/agency/members/remove` | `DELETE /api/agency/members?memberId=` (781+) |
| Sözleşme | `POST …/members/invite` + `userId` | `POST /api/agency/members` + `username` (782+) |
| Sözleşme | `POST/GET /api/agency` kök | `apply` / `my` (782+) |
| Sunucuda yok | `/api/pk/me/history\|stats\|matches` (ana site) | Router → **games**; istek yoksa boş (781+) |
| Sunucuda yok | `/api/jeton/payment-request` | Birincil: `POST /api/payments/requests` |
| Method | `PATCH /api/short-videos/{id}` | Backend yalnız GET/DELETE — düzenleme kapalı (781+) |
| Tanı | `/api/notifications/test-push` | Yalnız diagnostik ekran |

---

## 7. İlgili Flutter dosyalar

| Konu | Dosya |
|------|--------|
| Backend yönlendirme | `lib/core/network/api_backend_router.dart` |
| Sesli oda SSE hediye | `features/voice_hub/.../chat_room_providers_room_sync.dart` |
| Hediye dinleyici | `features/gifts/presentation/sync/gift_event_listener.dart` |
| PK geçmiş/istatistik | `features/live/data/pk/pk_room_remote_datasource.dart` |
| Ajans üye çıkarma | `features/agency/data/datasources/agency_management_datasource.dart` |

---

## 8. Referanslar

- Backend: `lib/event-outbox.ts`, `enqueueSSE`, `durableEmitSSE`, `durableNotify`, `drainOutbox`
- Parity durumu: [`BACKEND_FLUTTER_PARITY_2026-09_STATUS.md`](BACKEND_FLUTTER_PARITY_2026-09_STATUS.md)
- Yeni uçlar özeti: [`CANLIFAL_YENi_ENDPOINTLER_FLUTTER_REHBER.md`](CANLIFAL_YENi_ENDPOINTLER_FLUTTER_REHBER.md)
