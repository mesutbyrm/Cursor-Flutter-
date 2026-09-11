# Flutter-only endpoint denetimi (MATCH / YEDEK / KALDIR)

> **Generated:** 2026-09-11 21:20 UTC (`scripts/generate_flutter_only_endpoint_audit.py`)

OpenAPI `backend-docs/openapi.json` ile **normalize eşleşmeyen** `mobile/lib` `/api/` literal’leri.
Kılavuz: `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` (§9 mobil sözleşme, §10 opsiyonel/fallback).

## Özet

| Karar | Adet |
|-------|-----:|
| **MATCH** | 63 |
| **YEDEK** | 40 |
| **KALDIR** | 11 |
| **Toplam** | 114 |

- **MATCH:** Birincil üretim/kılavuz yolu (şablon farkı veya opsiyonel uç).
- **YEDEK:** Geriye dönük veya ikincil; kanonik uç başarısız olunca kullan.
- **KALDIR:** Ölü kod, log artefaktı veya yanlış auth prefix.

## Mobil hizalama (bu oturum)

| Alan | Birincil (OpenAPI/kılavuz) | Yedek |
|------|---------------------------|-------|
| Cüzdan | `GET /api/wallet` | `GET /api/user/wallet` |
| Fal erişim kontrol | `POST /api/fortune-access/check` | — |
| Fal erişim ayar | `GET /api/fortune-access/ip-status` | `GET /api/fortune-access/settings` |
| Referral özet | `GET /api/referral` | `/api/referral/stats`, `/me` |
| Referral kazanç | `GET /api/user/referral-earnings` | `/api/referral/earnings` |

## Tam liste

| Flutter literal | Karar | Kanonik / hedef | Not |
|-----------------|-------|-----------------|-----|
| `/api/admin/` | **YEDEK** | (çoklu `/api/admin/*`) | Dinamik admin prefix; her çağrı ilgili OpenAPI admin path ile doğrulanmalı |
| `/api/admin/chat/rooms/create-for-user` | **YEDEK** | `/api/admin/chat-rooms` (benzer) | Mobil admin kolaylığı |
| `/api/admin/mobile-auth` | **YEDEK** | `/api/auth/mobile-*` | Admin oturum köprüsü |
| `/api/admin/payment-notifications` | **YEDEK** | `/api/admin/cfc-payment-requests` | Ödeme bildirimleri |
| `/api/admin/payment-requests` | **YEDEK** | `GET/PATCH /api/admin/cfc-payment-requests` | OpenAPI kanonik |
| `/api/admin/payment-requests/dismiss-pending` | **YEDEK** | `/api/admin/cfc-payment-requests` | PATCH ile birleştir |
| `/api/admin/payments/stream` | **YEDEK** | SSE admin ödeme | Web/admin SSE |
| `/api/admin/site-animations` | **YEDEK** | (web admin) | OpenAPI’de site-animations yok |
| `/api/admin/site-animations/assign` | **YEDEK** | (web admin) | Yerel katalog fallback |
| `/api/admin/site-animations/bulk-assign` | **YEDEK** | (web admin) | Yerel katalog fallback |
| `/api/admin/site-animations/defaults` | **YEDEK** | (web admin) | Yerel katalog fallback |
| `/api/admin/site-animations/exit-defaults` | **YEDEK** | (web admin) | Yerel katalog fallback |
| `/api/admin/site-animations/stats` | **YEDEK** | (web admin) | Yerel katalog fallback |
| `/api/admin/users/credits` | **MATCH** | `/api/admin/users/{id}/credits` | Şablon farkı — normalize `{id}` |
| `/api/admin/users/grant-membership` | **YEDEK** | `/api/admin/memberships` | Admin üyelik |
| `/api/admin/users/stats` | **YEDEK** | `/api/admin/users` | Özet istatistik |
| `/api/admin/voice-room-backgrounds` | **YEDEK** | `/api/admin/voice-rooms` | Arka plan yönetimi |
| `/api/admin/voice-room-finance-audit` | **YEDEK** | `/api/admin/voice-room-finance` | Finans denetimi |
| `/api/admin/voice-room-settings` | **YEDEK** | `/api/platform/voice-room-settings` | Platform ayarı |
| `/api/advisors` | **MATCH** | `GET /api/advisors` | OpenAPI şablon farkı (literal prefix) |
| `/api/advisors/online` | **MATCH** | `GET /api/advisors/online` | Şablon |
| `/api/agency/invite-earnings` | **MATCH** | Kılavuz §10 opsiyonel | 404 → gizle |
| `/api/auth/` | **KALDIR** | `/api/auth/mobile-*` | Eski web auth prefix — mobilde kullanılmamalı |
| `/api/auth/google` | **KALDIR** | `POST /api/auth/mobile-google` | Legacy web |
| `/api/auth/login` | **KALDIR** | `POST /api/auth/mobile-login` | Legacy web |
| `/api/auth/me` | **KALDIR** | `GET /api/me` | Legacy web |
| `/api/auth/mobile-send-verification` | **YEDEK** | `POST /api/auth/mobile-verify-email` | Doğrulama akışı |
| `/api/auth/mobile-sessions` | **MATCH** | Kılavuz §9 Auth | Üretimde mobil oturumlar |
| `/api/auth/mobile-verify-email` | **MATCH** | Kılavuz §9 Auth | Üretim |
| `/api/auth/mobile/device-token` | **MATCH** | `POST /api/user/device-token` | Cihaz token alias |
| `/api/auth/refresh` | **KALDIR** | `POST /api/auth/mobile-refresh` | Legacy refresh |
| `/api/auth/register` | **KALDIR** | `POST /api/auth/mobile-register` | Legacy register |
| `/api/auth/tiktok` | **KALDIR** | `POST /api/auth/mobile-tiktok` | Legacy TikTok |
| `/api/banners` | **MATCH** | `GET /api/banners` | Ana sayfa |
| `/api/blog/recent` | **MATCH** | `GET /api/blog/recent` | Blog |
| `/api/celebrities` | **MATCH** | `GET /api/celebrities` | Keşfet |
| `/api/chat/music/popular` | **MATCH** | `GET /api/chat/music/popular` | Müzik |
| `/api/chat/rooms/` | **MATCH** | `/api/chat/rooms/{id}/*` | Dinamik oda prefix |
| `/api/currency-branding` | **MATCH** | Kılavuz §10 | OpenAPI’de olabilir; ekonomi v2 |
| `/api/daily-rewards` | **MATCH** | `GET /api/daily-rewards` | Günlük ödül |
| `/api/fan-clubs` | **MATCH** | `GET /api/fan-clubs` | Fan kulüp |
| `/api/fan-clubs/popular` | **MATCH** | `GET /api/fan-clubs/popular` | Fan kulüp |
| `/api/fortune-access/consume` | **YEDEK** | Fal POST / jeton düşümü | OpenAPI’de yok; 404 tolere |
| `/api/fortune-access/settings` | **YEDEK** | `GET /api/fortune-access/ip-status` | Settings 404; ip-status kanonik |
| `/api/games/history` | **MATCH** | `GET /api/games/history` | Oyun geçmişi |
| `/api/games/mini-scores` | **MATCH** | `GET /api/games/mini-scores` | Mini oyun |
| `/api/games/sos/create` | **MATCH** | Kılavuz §10 korunan | SOS oluştur |
| `/api/gifts/display-settings` | **MATCH** | `GET /api/gifts/display-settings` | Hediye UI |
| `/api/homepage` | **MATCH** | `GET /api/homepage` | Ana sayfa |
| `/api/leaderboard` | **MATCH** | `GET /api/leaderboard` | Liderlik |
| `/api/live` | **MATCH** | `/api/live/*` | Canlı prefix |
| `/api/live/fal-request/create` | **YEDEK** | `/api/video-streams/{id}/fortune-requests` | Legacy canlı fal |
| `/api/live/fal-requests` | **YEDEK** | `/api/video-streams/{id}/fortune-requests` | Legacy liste |
| `/api/messages/conversations` | **MATCH** | `GET /api/messages/conversations` | DM |
| `/api/me→isFortuneTeller` | **KALDIR** | (log string) | Gerçek endpoint değil |
| `/api/mobile/auth/web-session` | **YEDEK** | `/api/auth/mobile-*` | Web oturum köprüsü |
| `/api/notifications/payment` | **MATCH** | `GET /api/notifications/payment` | Ödeme bildirimi |
| `/api/notifications/unread` | **MATCH** | `GET /api/notifications/unread` | Okunmamış |
| `/api/pk` | **MATCH** | `/api/pk/*` (games host) | Router → games API |
| `/api/pk/` | **MATCH** | `/api/pk/*` | Router prefix |
| `/api/pk/admin/ban` | **YEDEK** | games PK admin | Games backend |
| `/api/pk/admin/bans` | **YEDEK** | games PK admin | Games backend |
| `/api/pk/battles` | **MATCH** | `GET /api/pk/battles` | Games host |
| `/api/pk/history` | **YEDEK** | `GET /api/pk/me/history` | Şablon/host |
| `/api/pk/me/history` | **YEDEK** | games `/api/pk/me/history` | Ana host 404 |
| `/api/pk/me/matches` | **YEDEK** | games PK | Ana host 404 |
| `/api/pk/me/stats` | **YEDEK** | games PK | Ana host 404 |
| `/api/pk/request` | **MATCH** | `POST /api/pk/request` | PK davet |
| `/api/pk/room` | **MATCH** | `/api/pk/room` | PK oda |
| `/api/platform-stats` | **MATCH** | `GET /api/platform-stats` | İstatistik |
| `/api/platform/voice-room-settings` | **MATCH** | `GET /api/platform/voice-room-settings` | Sesli oda |
| `/api/referral/earnings` | **YEDEK** | `GET /api/referral` + `/api/user/referral-earnings` | OpenAPI yalnız `/api/referral` |
| `/api/referral/invite-link` | **YEDEK** | `GET /api/referral` | shareUrl alanı |
| `/api/referral/ledger` | **YEDEK** | `GET /api/user/referral-earnings` | Komisyon kalemleri |
| `/api/referral/me` | **YEDEK** | `GET /api/referral` | Birleşik yanıt |
| `/api/referral/settings` | **YEDEK** | `GET /api/referral` | Ayarlar gömülü |
| `/api/referral/stats` | **YEDEK** | `GET /api/referral` | OpenAPI kanonik |
| `/api/referral/users` | **YEDEK** | `GET /api/referral` | referrals[] gömülü |
| `/api/reports` | **MATCH** | `POST /api/reports` | Şikayet |
| `/api/short-videos/explore/nearby` | **MATCH** | `GET /api/short-videos/explore/nearby` | Keşfet |
| `/api/short-videos/hashtags/search` | **MATCH** | `GET .../search` | Hashtag |
| `/api/short-videos/hashtags/trending` | **MATCH** | `GET .../trending` | Hashtag |
| `/api/short-videos/live-clip` | **MATCH** | `POST /api/short-videos/live-clip` | Klip |
| `/api/short-videos/music/recommend` | **MATCH** | `GET .../recommend` | Müzik |
| `/api/short-videos/recommend` | **MATCH** | `GET /api/short-videos/recommend` | Öneri |
| `/api/short-videos/suggest-metadata` | **MATCH** | `POST .../suggest-metadata` | Metadata |
| `/api/short-videos/viewed/me` | **MATCH** | `GET .../viewed/me` | İzleme geçmişi |
| `/api/site-animations/active` | **YEDEK** | Yerel asset katalog | Üretim 404; fallback |
| `/api/social/announcements` | **MATCH** | `GET /api/social/announcements` | Duyuru |
| `/api/social/posts/auto-fortune` | **MATCH** | `POST .../auto-fortune` | Sosyal fal |
| `/api/social/public-stats` | **MATCH** | `GET /api/social/public-stats` | İstatistik |
| `/api/social/stories` | **MATCH** | `GET /api/social/stories` | Hikaye |
| `/api/teller/gifts` | **MATCH** | `GET /api/teller/gifts` | Falcı hediye |
| `/api/teller/reviews` | **MATCH** | `GET /api/teller/reviews` | Yorum |
| `/api/tournaments/join` | **MATCH** | `POST /api/tournaments/join` | Turnuva |
| `/api/user/cosmetics` | **MATCH** | `GET /api/user/cosmetics` | Kozmetik |
| `/api/user/cosmetics/equip` | **MATCH** | `POST .../equip` | Kozmetik |
| `/api/user/cosmetics/loadout` | **MATCH** | `GET .../loadout` | Loadout |
| `/api/user/daily-tasks` | **MATCH** | `GET /api/user/daily-tasks` | Görevler |
| `/api/user/device-token` | **MATCH** | `POST /api/user/device-token` | FCM |
| `/api/user/favorites` | **MATCH** | `GET /api/user/favorites` | Favori |
| `/api/user/profile/cosmetics/equip` | **YEDEK** | `/api/user/cosmetics/equip` | Alias |
| `/api/user/profile→isFortuneTeller` | **KALDIR** | (log string) | Gerçek endpoint değil |
| `/api/user/referral-earnings` | **MATCH** | Kılavuz §10 birincil (404→`/api/referral`) | Ekonomi ekranı |
| `/api/user/story` | **MATCH** | `GET/POST /api/user/story` | Hikaye |
| `/api/user/wallet` | **YEDEK** | `GET /api/wallet` | Kılavuz §9/§10; OpenAPI kanonik wallet |
| `/api/users/me/activity` | **MATCH** | `GET /api/users/me/activity` | Aktivite |
| `/api/users/me/broadcast-history` | **MATCH** | `GET .../broadcast-history` | Yayın |
| `/api/users/me/gifts-received` | **MATCH** | `GET .../gifts-received` | Hediye |
| `/api/users/me/profile-visitors` | **MATCH** | `GET .../profile-visitors` | Ziyaretçi |
| `/api/users/me/stats` | **MATCH** | `GET /api/users/me/stats` | İstatistik |
| `/api/v1` | **KALDIR** | Yerel mirror / Invidious | Üretim API değil |
| `/api/v1/` | **KALDIR** | Yerel mirror | Üretim API değil |
| `/api/video` | **MATCH** | `/api/video/*` prefix | Video modülü |

## Komut

```bash
python3 scripts/generate_flutter_only_endpoint_audit.py
python3 scripts/generate_cross_source_parity_report.py
```
