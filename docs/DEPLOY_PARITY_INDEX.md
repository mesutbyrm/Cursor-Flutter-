# Web ↔ Flutter Parite — Deploy Sırası

Güncelleme: prod smoke test ile senkron.

| # | Madde | Belge | Prod | Flutter |
|---|-------|-------|------|---------|
| 1 | Müzik arama + TRTC | [DEPLOY_P0.md](./DEPLOY_P0.md) | music ✅401, TRTC ✅200, stream ✅200 | ✅ |
| 2 | Oda arka planları | [DEPLOY_P1_BACKGROUNDS.md](./DEPLOY_P1_BACKGROUNDS.md) | API ✅200, statik ✅ | ✅ katalog |
| 3 | FCM push token | [DEPLOY_P1_FCM.md](./DEPLOY_P1_FCM.md) | ✅401 (route var) | ✅ |
| 4 | PK Battle | [DEPLOY_P1_PK.md](./DEPLOY_P1_PK.md) | ❌404 | ✅ kod hazır |
| 5 | Üyelik paketleri | [DEPLOY_P1_MEMBERSHIP.md](./DEPLOY_P1_MEMBERSHIP.md) | ✅200 | ✅ prod JSON parse |
| 6 | Ana sayfa fal kartları | [DEPLOY_P2_FORTUNE_CARDS.md](./DEPLOY_P2_FORTUNE_CARDS.md) | ✅200 | ✅ API entegre |
| 7 | Sosyal stories | [DEPLOY_P2_SOCIAL_STORIES.md](./DEPLOY_P2_SOCIAL_STORIES.md) | `/stories` ✅ | ✅ |

**Doğrulama:** `bash scripts/verify-p0-endpoints.sh`

**Kalan prod gap:** yalnızca PK Battle REST (`/api/pk/*`).
