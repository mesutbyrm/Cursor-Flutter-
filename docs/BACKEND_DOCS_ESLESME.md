# Backend dokümanları ↔ Flutter eşleşmesi

> **Kaynak:** [`mesutbyrm/canlifal` PR #1](https://github.com/mesutbyrm/canlifal/pull/1) — dal `docs/backend-flutter-parity-2026-09` (HEAD `fdd5e62`), `nextjs_space/app/api/**/route.ts` (714 route).
> **Tarih:** 2026-09-28 · Flutter sürümü `1.0.623+674`

Mobil entegrasyonun tek kaynağı yine [`FLUTTER_ENTegrasyon_KILAVUZU.md`](FLUTTER_ENTegrasyon_KILAVUZU.md)'dur. Bu dosya, backend dokümanlarındaki her konunun Flutter'da nerede karşılandığını ve kontrol sonuçlarını gösterir.

## Tekrarlanabilir kontrol

```bash
git clone https://github.com/mesutbyrm/canlifal /tmp/canlifal
git -C /tmp/canlifal checkout docs/backend-flutter-parity-2026-09
python3 scripts/backend-route-parity.py /tmp/canlifal/nextjs_space --used-only
```

Betik Flutter'daki tüm `/api/...` yollarını backend route dosyalarıyla karşılaştırır ve backend'de karşılığı olmayanları listeler (`/api/v1/*` → `/api/*` middleware yeniden yazımı dahil).

## Doküman → Flutter dosyası

| Backend dokümanı | Flutter karşılığı |
|---|---|
| `AUTHENTICATION.md` (mobil JWT, 7 gün / 30 gün) | `lib/core/network/` auth interceptor, `/api/auth/mobile-login`, `/api/auth/mobile-refresh` |
| `REALTIME_SSE.md` | `lib/core/network/sse/base_sse_service.dart` (40 sn heartbeat zaman aşımı, üstel geri çekilme) |
| ↳ `/api/chat/rooms/{id}/stream` (10 sn) | `features/voice_hub/data/services/chat_room_sse_service.dart` |
| ↳ `/api/notifications/stream` (15 sn) | `features/notifications/data/services/notifications_sse_service.dart` |
| ↳ `/api/video-streams/{id}/stream` (15 sn) | `features/live/data/services/video_stream_sse_service.dart` (45 sn) |
| ↳ `/api/room/{sessionId}/stream` (15 sn) | `features/live_psychics/data/services/psychic_room_sse_service.dart` |
| ↳ `/api/admin/payments/stream` | `features/admin/data/services/admin_payments_sse_service.dart` |
| `LIVE_ROOMS.md` (12 adım) | `features/voice_hub/data/datasources/chat_room_remote_datasource.dart` |
| ↳ Çıkış: `DELETE /presence` + `POST leave-room` | `chat_room_remote_datasource.dart` → `leaveVoiceSession` |
| ↳ Heartbeat | `presenceHeartbeatInterval` = 15 sn |
| `PK_BATTLE.md` | `features/live/data/pk/pk_room_remote_datasource.dart`, `features/voice_hub/data/datasources/pk_battle_remote_datasource.dart` |
| ↳ Davet yoklaması `GET /api/pk/me/invites` | `features/live/presentation/widgets/live_pk_invite_listener.dart` |
| `TRTC_INTEGRATION.md` | `features/trtc/data/datasources/trtc_remote_datasource.dart` (`/api/trtc/token`, `/api/trtc/usersig`) |
| `SEAT_MANAGEMENT.md` | `features/voice_hub/` koltuk sağlayıcıları |
| `GIFT_SYSTEM.md` | `features/gifts/` |
| `MUSIC_SYSTEM.md` | `features/voice_hub/` müzik/DJ bloc'ları |

## Bu turda düzeltilenler (Flutter)

| Sorun | Düzeltme |
|---|---|
| Başka kullanıcının profilinde takipçi/takip listesi **kendi** listeni gösteriyordu (`/api/user/followers` `userId` olmadan çağrılıyordu; `/api/users/{id}/followers` backend'de yok) | `profile_remote_datasource.dart` → `?userId=` ile tek gerçek uç |
| Yönetici üyelik sayfası hiç yüklenmiyordu (`membership_tiers` / `membership_features` → backend `membership-tiers` / `membership-features`); kademe güncellemede `key` gövdede değil query'de gidiyordu; hücre durumu `rows` alanından okunmuyordu | `api_endpoints.dart` + `admin_membership_management_page.dart` |
| Ajans canlı takibi her zaman boştu (`/api/agency/presence` yok; zarf `data.members` okunmuyordu) | `/api/agency/live-status` + `statusLabel` |
| Falcı ve video yayın SSE watchdog'u zaman aşımında geri çekilmesiz yeniden bağlanıyordu (`REALTIME_SSE.md` kuralı) | `_scheduleReconnect()` üzerinden üstel geri çekilme |

## Backend'de karşılığı olmayan, hâlâ çağrılan yollar

Hepsi ya yedek zincirindedir (önce doğru uç denenir) ya da backend'de özellik hiç yoktur. Backend'e route eklenmeden mobilde yapılacak bir şey yok:

| Yol | Durum |
|---|---|
| `/api/broadcasters/weekly-competition` | Backend'de yok — haftalık yayıncı yarışması kutusu veri alamaz |
| `/api/short-videos/{id}/gifts`, `/analytics` | Backend'de yok — kısa videoya hediye / analitik çalışmaz |
| `/api/user/cosmetics*`, `/api/user/profile/cosmetics/equip` | Backend'de yok (yalnız `/api/profile-frames`, `/api/mic-frames`) |
| `/api/agency/applications` | Backend'de yok — ajans başvuru listesi boş gelir |
| `/api/admin/users/{id}/overview|activity|agency|earnings|moderation|reports|spending`, `/api/admin/pk/bans` | Yönetici; backend `.../360` ve `.../full` sunar |
| `/api/chat/rooms/{id}` (PATCH), `/api/leaderboard`, `/api/platform-stats`, `/api/games/history`, `/api/games/room/{id}/join`, `/api/short-videos/hashtags/{tag}`, `/api/video-streams/{id}/fortune-requests/{id}` | Yedek — önce doğru uç çağrılıyor |

## 1.0.623 — backend'e bağlanan modüller ve menü yerleri

| Modül | Backend ucu | Flutter | Menü |
|---|---|---|---|
| Burç uyumu | `POST /api/compatibility` `{sign1, sign2}` → `{analysis}` (HTML) | `features/astrology/` | Fal sekmesi → hızlı erişim |
| Rüya yarışması | `GET /api/dream-contest`, `GET/POST …/{id}/entries` `{interpretation}`, `POST …/{id}/vote` `{entryId}` | `features/dreams/` | Fal sekmesi, Rüya Merkezi |
| Futbol | `GET /api/football?action=matches|standings|scorers` | `features/football/` | Ana sayfa şeridi, `/futbol` |
| Ajans haftalık görev | `GET /api/agency/tasks` → `{currentTask, pastTasks}` | `features/agency/…/agency_weekly_tasks_page.dart` | Ajans paneli |
| Ortak yayın davetleri | `GET /api/user/co-broadcast-invites`, `PATCH /api/video-streams/{id}/co-broadcast` `{action}` | `features/live/…/co_broadcast_invites_page.dart` | Ayarlar → Canlı Yayın & Ses |
| Ses ayarları | — (TRTC SDK, cihazda) | `features/trtc/domain/voice_audio_settings.dart` | Ayarlar → Canlı Yayın & Ses |

Backend'de olmadığı için eklenmeyenler: futbol bahis/tahmin ve liderlik, ajans görev oluşturma/atama, kısa video remix, sunucu tarafı ses kaydı.

## Backend tarafında açık kalanlar (mobil düzeltemez)

1. **Hayalet katılımcı** — oda SSE varlık penceresi `lastSeen >= now - 300000` (5 dk). Flutter çıkışta `DELETE /presence` gönderiyor ve 15 sn'de bir heartbeat atıyor; backend penceresi 45–60 sn'ye indirilmeli (`app/api/chat/rooms/[roomId]/stream/route.ts`).
2. **PK daveti** — üç PK ucunun yanıt biçimi farklı; Flutter hem oda SSE `pk` olayını hem `GET /api/pk/me/invites` yoklamasını dinliyor. Uçtan uca iki hesapla test gerekli.
3. **Güvenlik** — `lib/mobile-auth.ts` zayıf JWT varsayılanı; `TRTC_WEBHOOK_KEY` yoksa webhook imzası atlanıyor.
