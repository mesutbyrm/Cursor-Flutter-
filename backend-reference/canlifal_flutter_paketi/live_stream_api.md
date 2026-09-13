# live_stream_api.md — Canlı Yayın Backend API'si

> Kaynak: üretim kodu taraması (2026-09-12). Doğrulanamayan her konu `MISSING` olarak işaretlenmiştir.

## 1. Mimari

Canlı yayın iki kökte toplanır:

| Kök | Adet | İçerik |
|---|---|---|
| `/api/video-streams/**` | 54 | Yayın yaşam döngüsü, sohbet, hediye, beğeni, moderatör, PK, sinyalleşme |
| `/api/live/**` | 19 | Oda/misafir/koltuk/mesaj/heartbeat yardımcıları, yayın PK'sı |

Medya taşıma **Tencent TRTC / WebRTC**'dir. Backend medya taşımaz.
- İmza: `POST /api/trtc/usersig`, `POST /api/trtc/token` (mobil JWT).
- Webhook: `POST /api/trtc/webhook`, `POST /api/tencent/webhook`.
- Telemetri: `POST /api/rtc/telemetry`.
- Eş-yayın (co-broadcast) sinyalleşmesi: `GET|POST|DELETE /api/video-streams/[streamId]/signal` ve `/api/video-streams/signal`.

> ⚠️ **RTMP push URL'i, stream key üretimi, HLS/CDN playback URL'i için ayrı bir endpoint kaynakta BULUNAMADI → MISSING.** Yayın TRTC oda kimliği üzerinden çalışır; Flutter da TRTC SDK ile aynı odaya bağlanmalıdır. RTMP/HLS gerekiyorsa bu **yeni (ek) bir uç** gerektirir — bu belge kapsamında önerilir, uygulanmamıştır.

Gerçek zamanlı yayın olayları: `GET /api/video-streams/[streamId]/stream` (SSE) ve PK için `GET /api/pk/[matchId]/stream` (SSE).

## 2. Yayın yaşam döngüsü

| Adım | Endpoint | Not |
|---|---|---|
| Yayın listesi | `GET /api/video-streams` | Yanıt `{ streams, items, pagination }` |
| Yayın başlat | `POST /api/video-streams` | Başarı `{ success, data }`; `429` → `{ error, message, remainingMinutes }` |
| Yayın detayı | `GET /api/video-streams/[streamId]` | |
| Yayın güncelle | `PATCH /api/video-streams/[streamId]` | |
| Medya gerçekten başladı | `POST /api/video-streams/[streamId]/live-started` | |
| İzleyici katıl / ayrıl | `POST` / `DELETE /api/video-streams/[streamId]/join`, `POST .../leave` | |
| İzleyici listesi | `GET /api/video-streams/[streamId]/viewers` | |
| Kalp atışı (medya) | `POST /api/video-streams/[streamId]/media-heartbeat` | **Kritik** |
| Otomatik kapanış | `GET` / `POST /api/video-streams/[streamId]/auto-close` | |
| Yayını bitir | `POST /api/video-streams/[streamId]/end` | |

🔴 **`media-heartbeat` zorunludur.** `lib/stream-auto-close.ts`, heartbeat kesildiğinde yayını otomatik kapatır. Flutter uygulaması **arka plana düşse bile** yayıncı için heartbeat'i sürdürmeli, aksi hâlde yayın sunucu tarafından sonlandırılır. Arka plan/ön plan davranışı için Android foreground service önerilir.

`/api/live/**` tarafında karşılıkları: `POST /api/live/create-room`, `POST /api/live/join-room`, `POST /api/live/leave-room`, `POST /api/live/heartbeat`, `GET /api/live/rooms`, `GET /api/live/online-users`.

## 3. Sohbet, yorum, beğeni

| İşlem | Endpoint |
|---|---|
| Yayın mesajları | `GET` · `POST /api/video-streams/[streamId]/messages` |
| Yorumlar | `GET` · `POST /api/video-streams/[streamId]/comments` |
| Beğeni | `GET` · `POST /api/video-streams/[streamId]/like` |
| (live ailesi) | `GET` · `POST /api/live/message` |

## 4. Hediye

- `GET` · `POST /api/video-streams/[streamId]/gifts`
- `GET /api/video-streams/gifts` (yayınlarda son hediyeler)
- `POST /api/live/gift/send`, `GET /api/live/gift-types`
- Genel: `POST /api/gifts/send` → ayrıntı `gifts_coins_wallet_api.md`

Hediye işlemleri **idempotent**tir (`Idempotency-Key` başlığı) ve çift taraflı ledger kaydı üretir.

## 5. Moderasyon (yayıncı / moderatör / admin)

| İşlem | Endpoint |
|---|---|
| Moderatör ekle/kaldır/listele | `GET` · `POST` · `DELETE /api/video-streams/[streamId]/moderators` |
| Susturma | `GET` · `POST` · `DELETE /api/video-streams/[streamId]/mute` |
| Yasaklama | `GET` · `POST` · `DELETE /api/video-streams/[streamId]/ban` |
| Kullanıcı şikâyeti | `POST /api/user/report` (rate limitli) |
| Platform düzeyi falcı yasağı | `POST /api/admin/live-tellers/[tellerId]/ban` (admin) |

Yetki katmanı: yayın sahibi → yayın moderatörü → platform moderatörü/admin. Guard fonksiyonları için `admin_permissions.md`.

## 6. Eş-yayın (co-broadcast) ve misafir

- `GET` · `POST` · `PATCH /api/video-streams/[streamId]/co-broadcast`
- `POST /api/video-streams/[streamId]/co-broadcast/invite`
- `GET` · `POST /api/live/guest`, `GET /api/live/guest/list`
- `GET` · `POST /api/live/seats`

## 7. PK (yayın düellosu)

| İşlem | Endpoint |
|---|---|
| Yayın PK'sı | `GET` · `POST /api/video-streams/[streamId]/pk-battle` |
| PK listesi / oluştur | `GET` · `POST /api/video-streams/pk`, `GET /api/video-streams/pk/list` |
| Adaylar | `GET /api/video-streams/pk/candidates` |
| Skor (admin) | `POST /api/video-streams/pk/score`, `POST /api/live/pk/score` |
| Aktif PK | `GET /api/pk/active`, `GET /api/live/pk/active` |
| Maç detayı | `GET /api/pk/[matchId]` |
| Maç SSE | `GET /api/pk/[matchId]/stream` |
| Davetlerim | `GET /api/pk/me/invites` |
| PK sıralaması | `GET /api/pk/leaderboard` |

🔒 Skor uçları **admin-only**. Gerçek skor `applyGiftPkScore` ile hediyelerden sunucuda üretilir.

## 8. Fal talebi (yayın içi)

`GET` · `POST` · `PATCH` · `DELETE /api/video-streams/[streamId]/fortune-requests`
`GET /api/video-streams/[streamId]/fortune-requests/my-status`

## 9. Flutter için kritik notlar

1. TRTC SDK zorunlu; `usersig` backend'den alınır, istemcide üretilmez.
2. Yayıncı: `POST /api/video-streams` → TRTC'ye bağlan → `POST .../live-started` → periyodik `POST .../media-heartbeat` → `POST .../end`.
3. İzleyici: `POST .../join` → SSE `GET .../stream` → `DELETE .../join` veya `POST .../leave`.
4. Yeniden bağlanma: SSE koptuğunda yayın detayını (`GET /api/video-streams/[streamId]`) yeniden çekip SSE'yi yeniden açın.
5. Yayın kalitesi/çözünürlük seçimi TRTC SDK tarafındadır; backend'de kalite endpoint'i **yoktur (MISSING)**.

## 10. Tam endpoint tablosu (yayın + live + PK + RTC)

> Toplam **83** endpoint (path+method). Kaynak: üretim kodu taraması, 2026-09-12.

| METHOD | ENDPOINT | AUTH | ÖZELLİK | QUERY | BODY ALANLARI | KAYNAK DOSYA |
|---|---|---|---|---|---|---|
| `POST` | `/api/live/create-room` | mobil JWT | — | — | — | `app/api/live/create-room/route.ts` |
| `GET` | `/api/live/gift-types` | mobil JWT | — | — | — | `app/api/live/gift-types/route.ts` |
| `POST` | `/api/live/gift/send` | mobil JWT + web oturum | ADMIN, RL, IDEM, LEDGER | — | — | `app/api/live/gift/send/route.ts` |
| `GET` | `/api/live/guest` | mobil JWT + web oturum | — | roomId, streamId | — | `app/api/live/guest/route.ts` |
| `POST` | `/api/live/guest` | mobil JWT + web oturum | — | roomId, streamId | — | `app/api/live/guest/route.ts` |
| `GET` | `/api/live/guest/list` | public | — | roomId, streamId | — | `app/api/live/guest/list/route.ts` |
| `POST` | `/api/live/heartbeat` | mobil JWT | — | — | — | `app/api/live/heartbeat/route.ts` |
| `POST` | `/api/live/join-room` | mobil JWT + web oturum | ADMIN | — | — | `app/api/live/join-room/route.ts` |
| `POST` | `/api/live/leave-room` | mobil JWT | — | — | — | `app/api/live/leave-room/route.ts` |
| `GET` | `/api/live/message` | mobil JWT | RL | after, limit, roomId, roomType | — | `app/api/live/message/route.ts` |
| `POST` | `/api/live/message` | mobil JWT | RL | after, limit, roomId, roomType | — | `app/api/live/message/route.ts` |
| `GET` | `/api/live/online-users` | mobil JWT | — | limit, roomId, roomType | — | `app/api/live/online-users/route.ts` |
| `GET` | `/api/live/pk` | mobil JWT | RL, IDEM | roomId | — | `app/api/live/pk/route.ts` |
| `POST` | `/api/live/pk` | mobil JWT | RL, IDEM | roomId | — | `app/api/live/pk/route.ts` |
| `GET` | `/api/live/pk/active` | public | — | includePending, roomId, streamId | — | `app/api/live/pk/active/route.ts` |
| `POST` | `/api/live/pk/score` | mobil JWT + web oturum | — | — | — | `app/api/live/pk/score/route.ts` |
| `GET` | `/api/live/rooms` | mobil JWT | — | limit, page, search, type | — | `app/api/live/rooms/route.ts` |
| `GET` | `/api/live/seats` | mobil JWT | — | roomId | — | `app/api/live/seats/route.ts` |
| `POST` | `/api/live/seats` | mobil JWT | — | roomId | — | `app/api/live/seats/route.ts` |
| `GET` | `/api/pk/[matchId]` | public | — | — | — | `app/api/pk/[matchId]/route.ts` |
| `GET` | `/api/pk/[matchId]/stream` | public | SSE | — | — | `app/api/pk/[matchId]/stream/route.ts` |
| `GET` | `/api/pk/active` | public | — | includePending | — | `app/api/pk/active/route.ts` |
| `GET` | `/api/pk/leaderboard` | public | — | limit, metric, period | — | `app/api/pk/leaderboard/route.ts` |
| `GET` | `/api/pk/me/invites` | mobil JWT + web oturum | — | direction | — | `app/api/pk/me/invites/route.ts` |
| `POST` | `/api/rtc/telemetry` | web oturum | RL | — | — | `app/api/rtc/telemetry/route.ts` |
| `POST` | `/api/tencent/webhook` | public | — | — | — | `app/api/tencent/webhook/route.ts` |
| `POST` | `/api/trtc/token` | mobil JWT | — | — | — | `app/api/trtc/token/route.ts` |
| `POST` | `/api/trtc/usersig` | mobil JWT | — | — | — | `app/api/trtc/usersig/route.ts` |
| `POST` | `/api/trtc/webhook` | public | — | — | — | `app/api/trtc/webhook/route.ts` |
| `GET` | `/api/video-streams` | mobil JWT + web oturum | RL | limit, page | — | `app/api/video-streams/route.ts` |
| `POST` | `/api/video-streams` | mobil JWT + web oturum | RL | limit, page | — | `app/api/video-streams/route.ts` |
| `GET` | `/api/video-streams/[streamId]` | mobil JWT + web oturum | ADMIN | — | backgroundUrl, broadcastImage, description, isImageMode, status, title | `app/api/video-streams/[streamId]/route.ts` |
| `PATCH` | `/api/video-streams/[streamId]` | mobil JWT + web oturum | ADMIN | — | backgroundUrl, broadcastImage, description, isImageMode, status, title | `app/api/video-streams/[streamId]/route.ts` |
| `GET` | `/api/video-streams/[streamId]/auto-close` | mobil JWT | — | — | — | `app/api/video-streams/[streamId]/auto-close/route.ts` |
| `POST` | `/api/video-streams/[streamId]/auto-close` | mobil JWT | — | — | — | `app/api/video-streams/[streamId]/auto-close/route.ts` |
| `DELETE` | `/api/video-streams/[streamId]/ban` | mobil JWT | — | userId | reason, userId | `app/api/video-streams/[streamId]/ban/route.ts` |
| `GET` | `/api/video-streams/[streamId]/ban` | mobil JWT | — | userId | reason, userId | `app/api/video-streams/[streamId]/ban/route.ts` |
| `POST` | `/api/video-streams/[streamId]/ban` | mobil JWT | — | userId | reason, userId | `app/api/video-streams/[streamId]/ban/route.ts` |
| `GET` | `/api/video-streams/[streamId]/co-broadcast` | mobil JWT | — | — | action, userId | `app/api/video-streams/[streamId]/co-broadcast/route.ts` |
| `PATCH` | `/api/video-streams/[streamId]/co-broadcast` | mobil JWT | — | — | action, userId | `app/api/video-streams/[streamId]/co-broadcast/route.ts` |
| `POST` | `/api/video-streams/[streamId]/co-broadcast` | mobil JWT | — | — | action, userId | `app/api/video-streams/[streamId]/co-broadcast/route.ts` |
| `POST` | `/api/video-streams/[streamId]/co-broadcast/invite` | mobil JWT | — | — | — | `app/api/video-streams/[streamId]/co-broadcast/invite/route.ts` |
| `GET` | `/api/video-streams/[streamId]/comments` | mobil JWT | RL | — | content, isHidden, nickname | `app/api/video-streams/[streamId]/comments/route.ts` |
| `POST` | `/api/video-streams/[streamId]/comments` | mobil JWT | RL | — | content, isHidden, nickname | `app/api/video-streams/[streamId]/comments/route.ts` |
| `POST` | `/api/video-streams/[streamId]/end` | mobil JWT + web oturum | ADMIN | — | — | `app/api/video-streams/[streamId]/end/route.ts` |
| `DELETE` | `/api/video-streams/[streamId]/fortune-requests` | mobil JWT | ADMIN | refundAll, userId | action, requestId | `app/api/video-streams/[streamId]/fortune-requests/route.ts` |
| `GET` | `/api/video-streams/[streamId]/fortune-requests` | mobil JWT | ADMIN | refundAll, userId | action, requestId | `app/api/video-streams/[streamId]/fortune-requests/route.ts` |
| `PATCH` | `/api/video-streams/[streamId]/fortune-requests` | mobil JWT | ADMIN | refundAll, userId | action, requestId | `app/api/video-streams/[streamId]/fortune-requests/route.ts` |
| `POST` | `/api/video-streams/[streamId]/fortune-requests` | mobil JWT | ADMIN | refundAll, userId | action, requestId | `app/api/video-streams/[streamId]/fortune-requests/route.ts` |
| `GET` | `/api/video-streams/[streamId]/fortune-requests/my-status` | mobil JWT | — | — | — | `app/api/video-streams/[streamId]/fortune-requests/my-status/route.ts` |
| `GET` | `/api/video-streams/[streamId]/gifts` | mobil JWT + web oturum | ADMIN, RL, IDEM, LEDGER | — | giftTypeId, quantity | `app/api/video-streams/[streamId]/gifts/route.ts` |
| `POST` | `/api/video-streams/[streamId]/gifts` | mobil JWT + web oturum | ADMIN, RL, IDEM, LEDGER | — | giftTypeId, quantity | `app/api/video-streams/[streamId]/gifts/route.ts` |
| `DELETE` | `/api/video-streams/[streamId]/join` | mobil JWT | — | viewerId | — | `app/api/video-streams/[streamId]/join/route.ts` |
| `POST` | `/api/video-streams/[streamId]/join` | mobil JWT | — | viewerId | — | `app/api/video-streams/[streamId]/join/route.ts` |
| `POST` | `/api/video-streams/[streamId]/leave` | mobil JWT | — | viewerId | — | `app/api/video-streams/[streamId]/leave/route.ts` |
| `GET` | `/api/video-streams/[streamId]/like` | mobil JWT | — | — | — | `app/api/video-streams/[streamId]/like/route.ts` |
| `POST` | `/api/video-streams/[streamId]/like` | mobil JWT | — | — | — | `app/api/video-streams/[streamId]/like/route.ts` |
| `POST` | `/api/video-streams/[streamId]/live-started` | mobil JWT | — | — | — | `app/api/video-streams/[streamId]/live-started/route.ts` |
| `POST` | `/api/video-streams/[streamId]/media-heartbeat` | mobil JWT | — | — | — | `app/api/video-streams/[streamId]/media-heartbeat/route.ts` |
| `GET` | `/api/video-streams/[streamId]/messages` | mobil JWT | — | limit, since | — | `app/api/video-streams/[streamId]/messages/route.ts` |
| `POST` | `/api/video-streams/[streamId]/messages` | mobil JWT | — | limit, since | — | `app/api/video-streams/[streamId]/messages/route.ts` |
| `DELETE` | `/api/video-streams/[streamId]/moderators` | mobil JWT | — | — | userId | `app/api/video-streams/[streamId]/moderators/route.ts` |
| `GET` | `/api/video-streams/[streamId]/moderators` | mobil JWT | — | — | userId | `app/api/video-streams/[streamId]/moderators/route.ts` |
| `POST` | `/api/video-streams/[streamId]/moderators` | mobil JWT | — | — | userId | `app/api/video-streams/[streamId]/moderators/route.ts` |
| `DELETE` | `/api/video-streams/[streamId]/mute` | mobil JWT | — | — | expiresAt, reason, viewerId | `app/api/video-streams/[streamId]/mute/route.ts` |
| `GET` | `/api/video-streams/[streamId]/mute` | mobil JWT | — | — | expiresAt, reason, viewerId | `app/api/video-streams/[streamId]/mute/route.ts` |
| `POST` | `/api/video-streams/[streamId]/mute` | mobil JWT | — | — | expiresAt, reason, viewerId | `app/api/video-streams/[streamId]/mute/route.ts` |
| `GET` | `/api/video-streams/[streamId]/pk-battle` | mobil JWT | — | — | — | `app/api/video-streams/[streamId]/pk-battle/route.ts` |
| `POST` | `/api/video-streams/[streamId]/pk-battle` | mobil JWT | — | — | — | `app/api/video-streams/[streamId]/pk-battle/route.ts` |
| `DELETE` | `/api/video-streams/[streamId]/signal` | mobil JWT | — | recipientId | — | `app/api/video-streams/[streamId]/signal/route.ts` |
| `GET` | `/api/video-streams/[streamId]/signal` | mobil JWT | — | recipientId | — | `app/api/video-streams/[streamId]/signal/route.ts` |
| `POST` | `/api/video-streams/[streamId]/signal` | mobil JWT | — | recipientId | — | `app/api/video-streams/[streamId]/signal/route.ts` |
| `GET` | `/api/video-streams/[streamId]/stream` | mobil JWT | SSE | — | — | `app/api/video-streams/[streamId]/stream/route.ts` |
| `GET` | `/api/video-streams/[streamId]/viewers` | public | — | — | — | `app/api/video-streams/[streamId]/viewers/route.ts` |
| `GET` | `/api/video-streams/gifts` | mobil JWT | — | — | — | `app/api/video-streams/gifts/route.ts` |
| `GET` | `/api/video-streams/pk` | mobil JWT + web oturum | ADMIN, RL, IDEM | streamId | — | `app/api/video-streams/pk/route.ts` |
| `POST` | `/api/video-streams/pk` | mobil JWT + web oturum | ADMIN, RL, IDEM | streamId | — | `app/api/video-streams/pk/route.ts` |
| `GET` | `/api/video-streams/pk/candidates` | mobil JWT + web oturum | — | streamId | — | `app/api/video-streams/pk/candidates/route.ts` |
| `GET` | `/api/video-streams/pk/list` | public | — | — | — | `app/api/video-streams/pk/list/route.ts` |
| `POST` | `/api/video-streams/pk/score` | mobil JWT + web oturum | ADMIN | — | battleId, points, streamId | `app/api/video-streams/pk/score/route.ts` |
| `DELETE` | `/api/video-streams/signal` | mobil JWT | — | recipientId, streamId | — | `app/api/video-streams/signal/route.ts` |
| `GET` | `/api/video-streams/signal` | mobil JWT | — | recipientId, streamId | — | `app/api/video-streams/signal/route.ts` |
| `POST` | `/api/video-streams/signal` | mobil JWT | — | recipientId, streamId | — | `app/api/video-streams/signal/route.ts` |

---

## GÜNCELLEME 2026-09-12 — Canlı Yayın Teknolojisinin Kesin Tespiti (§8)

Kaynak kod taraması sonucu **kesin** bulgu:

| Soru | Cevap | Kanıt |
|---|---|---|
| RTMP giriş ucu var mı? | **Hayır** | Kod tabanında RTMP/ingest/stream-key üreten hiçbir uç yok |
| HLS/DASH çıkışı var mı? | **Hayır** | `.m3u8` / playlist üreten hiçbir uç yok |
| WebSocket sunucusu var mı? | **Hayır** | 20 uç `text/event-stream` (SSE); WebSocket sunucusu yok |
| Kullanılan teknoloji | **Tencent TRTC (WebRTC tabanlı)** | İmza/oda katılım uçları TRTC `userSig` üretir |

**Flutter için sonuç:** Yayın izleme ve yayın açma için `tencent_trtc_cloud` SDK'sı zorunludur; HLS oynatıcı ile izlemek **mümkün değildir**. Yayın meta verileri (izleyici sayısı, hediye akışı, sohbet, PK skoru) REST + SSE üzerinden gelir; ses/görüntü TRTC üzerinden.

`VideoStream` modelinde `isLive` alanı **yoktur** — canlı olma durumu `status` (`'live'` / `'ended'`) ve `endedAt` alanları ile belirlenir.
