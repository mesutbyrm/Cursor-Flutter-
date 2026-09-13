# Faz 3 — referral, short-videos, social, fan-clubs, celebrities

**Hedef:** 23 `extra_main` yolu (referral 7 + bu paket 16).

## Referral (7)

Prisma: `Referral`, `ReferralCommission` (`earnerId`). `lib/mobile-referral-handlers.ts`.

## Short-videos (6)

| Flutter | Strateji |
|---------|----------|
| `explore/nearby` | `explore` + `nearby=1`, lat/lng query |
| `hashtags/search` | → `/api/hashtags/search` |
| `hashtags/trending` | → `/api/hashtags/trending` |
| `music/recommend` | → `/api/short-videos/music` |
| `viewed/me` | `ShortVideoView` listesi |
| `{id}/subtitles/generate` | POST — boş SRT + bilgi mesajı (AI sonra) |

## Social (3)

Re-export: `announcements`, `public-stats`, `stories`.

## Fan-clubs (4)

`FanClub`, `FanClubMember`, `FanClubPost`, `FanClubPoll` — `lib/parity-fan-club-handlers.ts`.

## Celebrities (3)

`Celebrity`, `CelebrityFollow`, `CelebrityPost` — `lib/parity-celebrity-handlers.ts`.

Uygulama: `bash scripts/apply-backend-parity-to-nextjs.sh ./nextjs_space` → `yarn tsc --noEmit && yarn build`.
