# ranking_api.md — Sıralama, Liderlik Tabloları ve Turnuvalar

> Kaynak: üretim kodu taraması (2026-09-12).

## 1. Ana sıralama ucu

**`GET /api/leaderboards`** — mobil JWT. 30 saniyelik sunucu önbelleği (`getCached`).
Yanıt (kaynaktan): `{ ...data, ...community, currentUserRanks }` — burada `data` şu blokları içerir:

| Blok | İçerik |
|---|---|
| `topFortuneViewers` | ilk 10 · `{ id, name, username, image }` + sayaç |
| `mostPopular` | ilk 10 |
| `topStreamers` | ilk 10 |
| `topSpenders` | ilk 10 |

`community` bölümü `lib/services/leaderboard-service.ts` → `getCommunityLeaderboards()` çıktısıdır.
`currentUserRanks` çağıran kullanıcının kendi sıralarını verir.
Hata: `500 "Sıralama verileri alınamadı"`.

**`GET /api/leaderboards/top100`** — ilk 100 listesi (mobil JWT + web oturumu).

Diğer tablolar: `GET /api/pk/leaderboard`, `GET /api/agency/leaderboard`, `GET /api/games/leaderboard`, `GET /api/gifts/insights/leaderboard`.

## 2. Sıralama motoru (`lib/leaderboard-engine.ts`)

Tüm puanlama ve ödül dağıtımı **sunucudadır**:

| Fonksiyon | Görev |
|---|---|
| `getActiveConfigs()` | Aktif tablo yapılandırmaları (tür, periyot, ödüller) |
| `getOrCreateCurrentPeriod()` | Geçerli periyodu bulur/oluşturur |
| `incrementLeaderboardScore()` | Puan artışı — yalnız sunucu iç akışlarından çağrılır |
| `finalizeExpiredPeriods()` | Süresi dolan periyotları kapatır |
| `distributeRewards()` / `applyReward()` | Sıralara göre ödül dağıtır |

Ödül dağıtımı **idempotent**: `LeaderboardReward` tablosunda `unique(periodId, rank)` + `period.status === 'rewarded'` kontrolü. Her ödül `recordLedger` ile çift taraflı yazılır (`leaderboard_reward`; CFC ve jeton bacakları ayrı).

Periyot türleri, sıfırlama zamanı, saat dilimi ve eşitlik bozma kuralı **veritabanındaki yapılandırma kayıtlarından** okunur (`LeaderboardConfig`), kodda sabit değildir. Bu nedenle:
> **MISSING:** Sabit bir "saatlik/günlük/haftalık/aylık" listesi kaynak kodda gömülü değildir; aktif periyotlar `GET /api/leaderboards` yanıtından ve `/api/admin/leaderboards` yönetiminden okunur. Flutter bu değerleri **sunucudan almalı**, sabit kodlamamalıdır.

## 3. Turnuvalar

`GET /api/tournaments` (mobil JWT + web oturumu) · yönetim `/api/admin/tournaments`.

`lib/tournament-state.ts`: `TOURNAMENT_STATUSES`, `transitionTournament()`, `joinTournament()`, `incrementScore()`, `getLeaderboard()`, `snapshotRanks()`.
Ödül idempotency: `entry.rewarded` bayrağı + `transitionTournament('rewarded')`. Ledger kategorisi `tournament_reward`.

## 4. Takımlar ve destekçi seviyeleri

- `GET` · `POST /api/teams`, `GET` · `PATCH /api/teams/[teamId]` — takım puanları `lib/team-points.ts`
- `GET /api/supporter-levels` — destekçi seviyesi `lib/supporter-level.ts`
- Falcı seviyeleri `lib/teller-levels.ts`

## 5. Admin tarafı

`GET` / `POST /api/admin/leaderboards` — yapılandırma, periyot kapatma, manuel ödül.
Bu uç **§88 kritik onay guard'ı** ile korunur: eşik üstü işlemlerde `409 requiresConfirmation` döner, `confirm: true` ile tekrar gönderilmelidir. Tüm işlemler `recordAudit` ile denetim kaydına yazılır.

## 6. Flutter için kritik notlar

1. Puan artışı için **istemci ucu yoktur ve olmamalıdır.** Puan, hediye/yayın/oda akışlarından sunucuda üretilir.
2. Sıralama ekranı yalnız `GET` uçlarını tüketir; 30 sn önbellek nedeniyle daha sık istek atmak faydasızdır.
3. Periyot adı, bitiş zamanı ve ödül tablosu sunucudan gelir — istemcide sabitlemeyin.
4. Kullanıcının kendi sırası `currentUserRanks` içinde gelir; ayrı bir "benim sıram" ucu **yoktur (MISSING)**.

## 7. Tam endpoint tablosu (sıralama + turnuva + takım)

> Toplam **12** endpoint (path+method). Kaynak: üretim kodu taraması, 2026-09-12.

| METHOD | ENDPOINT | AUTH | ÖZELLİK | QUERY | BODY ALANLARI | KAYNAK DOSYA |
|---|---|---|---|---|---|---|
| `GET` | `/api/agency/leaderboard` | public | — | limit, period | — | `app/api/agency/leaderboard/route.ts` |
| `GET` | `/api/games/leaderboard` | mobil JWT | — | gameType, period, search | — | `app/api/games/leaderboard/route.ts` |
| `GET` | `/api/gifts/insights/leaderboard` | public | — | context, limit, period, scope, type | — | `app/api/gifts/insights/leaderboard/route.ts` |
| `GET` | `/api/leaderboards` | mobil JWT | — | — | — | `app/api/leaderboards/route.ts` |
| `GET` | `/api/leaderboards/top100` | mobil JWT + web oturum | — | key, limit, period, scope | — | `app/api/leaderboards/top100/route.ts` |
| `GET` | `/api/pk/leaderboard` | public | — | limit, metric, period | — | `app/api/pk/leaderboard/route.ts` |
| `GET` | `/api/supporter-levels` | web oturum | — | broadcasterId | — | `app/api/supporter-levels/route.ts` |
| `GET` | `/api/teams` | web oturum | — | — | — | `app/api/teams/route.ts` |
| `POST` | `/api/teams` | web oturum | — | — | — | `app/api/teams/route.ts` |
| `GET` | `/api/teams/[teamId]` | web oturum | — | — | — | `app/api/teams/[teamId]/route.ts` |
| `PATCH` | `/api/teams/[teamId]` | web oturum | — | — | — | `app/api/teams/[teamId]/route.ts` |
| `GET` | `/api/tournaments` | mobil JWT + web oturum | — | category, filter | — | `app/api/tournaments/route.ts` |
