# Web ↔ Flutter Parite — Deploy Sırası

Öncelik sırasıyla canlifal.com web reposuna uygulanacak deploy adımları.

| # | Madde | Belge | Prod (2026-05-19) | Flutter |
|---|-------|-------|-------------------|---------|
| 1 | Müzik arama + TRTC | [DEPLOY_P0.md](./DEPLOY_P0.md) | music ✅401, TRTC ✅200, stream ❌404 | Hazır |
| 2 | Oda arka planları | [DEPLOY_P1_BACKGROUNDS.md](./DEPLOY_P1_BACKGROUNDS.md) | statik ✅, API ❌404 | ✅ katalog fallback |
| 3 | FCM push token | [DEPLOY_P1_FCM.md](./DEPLOY_P1_FCM.md) | ❌404 | ✅ sessiz fallback |
| 4 | PK Battle | [DEPLOY_P1_PK.md](./DEPLOY_P1_PK.md) | ❌404 | ✅ kod hazır |
| 5 | Üyelik paketleri | [DEPLOY_P1_MEMBERSHIP.md](./DEPLOY_P1_MEMBERSHIP.md) | ❌404 | ✅ fallback katalog |
| 6 | Ana sayfa fal kartları | [DEPLOY_P2_FORTUNE_CARDS.md](./DEPLOY_P2_FORTUNE_CARDS.md) | API ✅200 | ✅ entegre |
| 7 | Sosyal stories | [DEPLOY_P2_SOCIAL_STORIES.md](./DEPLOY_P2_SOCIAL_STORIES.md) | `/stories` ✅ | ✅ birincil path |

**Doğrulama:** `bash scripts/verify-p0-endpoints.sh`

**Next.js referansları:** `docs/nextjs/README.md`
