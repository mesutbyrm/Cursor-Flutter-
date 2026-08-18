# FAZ 2 — Profile parity özeti

**Tarih:** 2026-08-18  
**Kaynak:** Kılavuz §9.2 `UserRepository` vs `mobile/lib/features/profile/`  
**Durum:** Hazırlık — geniş implementasyon mevcut; tam PASS FAZ 1 sonrası

---

## Kılavuz §9.2 — kapsam

| Metot | Endpoint | Flutter | Not |
|-------|----------|---------|-----|
| getMe | `/api/me` | ✅ | auth + profile hub |
| getProfile | `/api/user/profile` | ✅ | `ProfileExtendedEntity` |
| updateProfile | PATCH `/api/user/profile` | ✅ | avatar presigned R2 |
| getCredits | `/api/user/credits` | ✅ | |
| getStats / getStatistics | `/api/user/stats`, `/statistics` | ✅ | |
| getFollowers / getFollowing | `/api/user/followers`, `/following` | ✅ | pagination |
| followUser | POST `/api/user/{id}/follow` | ✅ | |
| getFollowStatus | GET follow-status | ✅ | |
| getOtherUser | `/api/users/{id}` | ✅ | + username lookup |
| blockUser | `/api/user/blocked` | ✅ | `userBlock` yedek uç |
| getWallet | `/api/wallet` | ✅ | jeton/CFC/credits |
| getReferralInfo | `/api/referral` | ✅ | invite_friends_page |
| getAchievements | `/api/user/achievements` | ✅ | |
| getUserTheme | `/api/user/theme` | ✅ | |
| dailyLogin / dailyMissions | `/api/daily-login`, `/daily-missions` | 🔄 | kısmen — daily-tasks uçları |
| getPresence | POST `/api/presence` | ✅ | global presence |
| watchAd | `/api/user/watch-ad` | ✅ | |

---

## Ek (kılavuz dışı / genişletilmiş)

| Alan | Uç | Durum |
|------|-----|--------|
| Ödeme talepleri | `/api/payments/requests` | ✅ jeton/CFC/üyelik |
| Üyelik | `/api/memberships/*` | ✅ Gold hub |
| Referral geniş | `/api/referral/me`, ledger, earnings | ✅ |
| Yayın geçmişi | `/api/user/broadcast-history` | ✅ |

---

## Açık noktalar (FAZ 2 iş listesi)

1. **Skeleton UI** — yavaş profil sekmelerinde tutarlı loading
2. **Paralel API azaltma** — profile hub çoklu çağrı birleştirme
3. **daily-missions** vs `daily-tasks` isim uyumu (backend doğrulama)
4. **Jeton satın alma** — test hesabı jeton=0 (M5/M7 ile ortak bloker)

---

## Komutlar

```bash
cd mobile && flutter test test/features/profile/ 2>/dev/null || dart analyze lib/features/profile/
grep -r "ApiEndpoints\." mobile/lib/features/profile/ | head
```
