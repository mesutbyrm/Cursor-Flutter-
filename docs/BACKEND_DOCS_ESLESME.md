# Backend dokümanları ↔ Flutter eşleşmesi

> **Kaynak:** [`mesutbyrm/canlifal` PR #1](https://github.com/mesutbyrm/canlifal/pull/1) — dal `docs/backend-flutter-parity-2026-09` (HEAD `fdd5e62`), `nextjs_space/app/api/**/route.ts` (714 route).
> **Tarih:** 2026-09-29 · Flutter sürümü `1.0.646+697` · özet: [`BACKEND_FLUTTER_PARITY_2026-09_STATUS.md`](BACKEND_FLUTTER_PARITY_2026-09_STATUS.md)

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

## Yanlış uç / yanlış HTTP metodu taraması (özellik dalı, sürüm yükseltilmedi)

`python3 scripts/backend-method-parity.py <canlifal>/nextjs_space` her Flutter çağrısının **metodunu** backend `route.ts` export'larıyla karşılaştırır (değişken yolları, `for (final path in [...])` listelerini ve yardımcı yol fonksiyonlarını çözer). Önce: 31 hatalı çağrı · şimdi: 0 (kalan 2 satır bilinen yanlış alarm: fal slug'ı ve `_postPaymentRequest(path)` parametresi).

| Sorun (backend'de gerçekte olan) | Düzeltme |
|---|---|
| **Koltuk kilitle / kilidi aç / koltuktan at** `{action: lock|kick, seatIndex}` gönderiyordu; `PATCH /seats` `action` okumaz → **işlemi yapan kişi o koltuğa oturuyordu** | Tek sözleşme `PATCH /seats {seatIndex, targetUserId?}`; koltuktan at = oturanı `seatIndex: -1`; kilit ucu yok → açık hata |
| Koltuk al/değiştir/kalk önce POST deniyordu (405) → her işlemde fazladan tur; "koltuk dolu"da bir alt koltuğa oturtma yedeği | Doğrudan PATCH; yanlış koltuk yedeği kaldırıldı |
| Müzik "geç" 400, sil/temizle/tamamla/sırala ölü uçlar | `DELETE /music` (geç), `DELETE /song/{id}`, `POST /music/stop`; sıralama (backend'de yok) kaldırıldı |
| DM engelleme 405 | `POST /api/user/block` aç/kapa + `blocked` doğrulaması |
| Takip/takibi bırak toggle riski (çift istek = geri alma) | `isFollowing` doğrulamalı tek POST |
| Site animasyon varsayılanları PUT (405) | Giriş başına `POST {membershipTier, category, animationId}` |
| Ödeme talebi iptali `PATCH` (405); her ödeme öncesi tüm sayfaları gezen iptal döngüsü | Backend'de iptal yok → açık mesaj; döngüler kaldırıldı |
| Turnuvaya katıl `POST /api/tournaments` (405) | `POST /api/tournaments/join {tournamentId}` |
| Fal kaydı `POST /api/user/fortunes` (405), detay `GET /api/user/fortunes/{id}` (405); geçmiş ikinci sayfada aynı kayıtları tekrarlıyordu | Kayıt fal ucunda sunucuda oluşur; detay listeden; sayfalama `total` yoksa kapalı |
| Kısa video `suggest-metadata` / `live-clip`, `auto-fortune`, seans dışı falcı bahşişi (`POST /api/teller/gifts`) | Backend'de yok → yerel öneri / galeri / `POST /api/social/posts`; istek atılmıyor |
| Yayın bitirme DELETE yedeği, `/api/live` listesi, mesaj silme web yolu, `/api/users/me/activity` PATCH, admin ödeme PATCH yedeği, hediye hedefi kapatma (4 ölü istek) | Gerçek uçlar / istek yok |
| Yönetici canlı yayın kontrolü `/api/live/admin/*` (yok) | Aktif liste `GET /api/video-streams`, sonlandır `PATCH /api/video-streams/{id} {status: ended}`; uyarı/askı yalnız web |
| Yönetici gelişmiş rapor `/api/admin/users/reports/*` (yok) | `GET /api/admin/platform-analytics` (mobil JWT, `analytics.view`) |

## 1.0.624 — kalan eksiklerin bağlanması

`backend-route-parity.py --used-only` sonucu: **0** (önce 34). Bilinen yanlış alarmlar betikte süzülür (`api_path_v1.dart`, `api_cache_policy.dart` önek kuralı, slug'ı `_apiSlugFor` ile gerçek `/api/fortunes/<tür>`'e eşlenen `fortuneReading`). Hiçbir yerde kullanılmayan 172 ölü sabit `api_endpoints.dart`'tan silindi.

| Önceki (backend'de yok) | Şimdi |
|---|---|
| `/api/user/cosmetics*` | Yuva başına: `/api/profile-frames` `{frameId}`, `/api/mic-frames`, `/api/chat-bubbles`, `/api/name-effects` (key), `/api/entrance-effects`, `/api/avatar-accessories` (çoklu) — `POST {id}`; katalog backend + yerleşik birleşik. Profil efekti ve rozet cihazda |
| `/api/admin/users/{id}/overview…reports` | `/api/admin/users/{id}/360?section=general|activity|agency|earnings|spending|moderation|reports`. **Sahte ajans/moderasyon/şikayet verisi gösteriliyordu → kaldırıldı** |
| `/api/admin/pk/bans` | Kullanıcı `canPK == false` (`section=general`) |
| `/api/reports` (şikayet gönderme) | `POST /api/user/report` (içerik şikayeti sahibine), sesli oda `POST /api/chat/rooms/{id}/report`. **Önceden hiçbir şikayet backend'e ulaşmıyordu** |
| `/api/reports` (yönetici kuyruğu) | Backend'de genel liste yok, `/api/admin/moderation` yalnız web oturumu → web panele yönlendirme |
| `/api/short-videos/{id}/gifts` | `POST /api/gifts/send {recipientUsername: video sahibi, giftTypeId, type: gift}` + Idempotency-Key. **Önceden kısa videoya hediye gönderilemiyordu** |
| `/api/short-videos/{id}/analytics` | `GET /api/short-videos/{id}` sayaçları |
| `/api/short-videos/{id}/stream` | Kaldırıldı (oynatıcı önce bu ölü adresi deniyordu) |
| `/api/short-videos/hashtags/{tag}` | `GET /api/short-videos/explore?q=#etiket` (imleçli) |
| `/api/broadcasters/weekly-competition` | CFC Arena: `GET /api/cfc-arena?status=active` → `broadcaster` (weekly öncelikli) → `GET /api/cfc-arena/{id}` leaderboard |
| `/api/agency/applications` | `GET /api/agency/members` → `leaveRequests`; karar `POST /api/agency/leave {action, requestId, reviewNote}` |
| `/api/games/mini-scores` | `POST /api/games/play {gameSlug, score, result}`; test amaçlı "skor 0 kaydet" düğmesi kaldırıldı (sunucu CFC ödülü verir) |
| `/api/games/history`, `/api/games/room/{id}/join` | Kullanıcı bazlı geçmiş ucu yok → istek atılmıyor; katılım `POST /api/games/room/{id}` |
| `/api/chat/rooms/{id}` (GET/PATCH) | GET → `/state` (`data.room`); PATCH yedeği kaldırıldı (`/settings`, `/background` gerçek) |
| `/api/leaderboard`, `/api/platform-stats`, `/api/payment/*`, fal isteği PATCH yedeği, SSO `/api/mobile/auth/web-session`, `/api/admin/mobile-auth` | Ölü yedekler kaldırıldı |

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
