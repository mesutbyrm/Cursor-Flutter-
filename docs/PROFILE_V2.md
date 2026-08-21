# PROFILE V2

Canlifal Flutter — Profil + Cüzdan + Jeton + Üyelik + Kullanıcı Hesabı (Aşama 6)

## Kullanılan API'ler

| Alan | Endpoint | Kaynak |
|------|----------|--------|
| Oturum / kullanıcı | `GET /api/me` | `AuthController`, `AuthRepository` |
| Profil güncelleme | `PATCH /api/me`, `PATCH /api/user/profile` | `ProfileRemoteDataSource.updateMe` |
| Genişletilmiş profil | `GET /api/user/profile` | `profileExtendedProvider` |
| İstatistikler | `GET /api/user/stats`, `/api/me/stats` | `profileStatsProvider` |
| Cüzdan | `GET /api/me` → `GET /api/user/credits` (mobil JWT) | `walletBalancesProvider` |
| Jeton paketleri | `GET /api/jeton` | `jetonPackagesProvider` |
| Üyelik paketleri | `GET /api/memberships/packages` | `membershipCatalogProvider` |
| Ödeme | `GET /api/payments/config`, `/api/payments/methods` | `paymentConfigProvider` |
| İşlem geçmişi | profil transactions route | `profile/transactions` |

## Auth

- JWT Bearer — `flutter_secure_storage`
- 401 → `POST /api/auth/mobile-refresh` → başarısızsa logout
- Logout: token + HTTP cache + `clearAuthenticatedUserCache()` (profil/cüzdan/üyelik provider'ları)

## User Model

`UserEntity` — `id`, `username`, `displayName`, `avatarUrl`, `bio`, `followersCount`, `followingCount`, `isVerified`, `coinBalance` (yalnızca ilk seed)

Genişletilmiş: `ProfileExtendedEntity` — `zodiacSign`, `favoriteTeam`, `birthDate`, `isOnline`, `dailyStreak`, `coverImage`

## Wallet

- **Tek kaynak:** `walletBalancesProvider` (`WalletBalancesNotifier`)
- Parse: `jetonBalance`, `cfcBalance`, `membership`, `membershipExpiresAt`, `favoriteTeam`
- Ana sayfa jeton pill, profil, canlı yayın, sesli oda, hediye, fal, oyun — aynı provider
- Auth `coinBalance` yalnızca cüzdan API gelene kadar geçici seed

## Jeton

- Gösterim: `walletBalancesProvider.valueOrNull?.jeton`
- Satın alma: `/jeton-store` (`openJetonStore`)
- CFC ayrı alan — karıştırılmaz

## Membership

- Backend `membership` + `membershipExpiresAt` → `profileMembershipInfoProvider`
- Ücretli tier yoksa rozet gösterilmez
- Satın alma: `/premium-membership`
- Fallback katalog yalnızca API boşsa (`membership_catalog_fallback.dart`)

## Profile Edit

- `/profile/edit` — ad, kullanıcı adı, bio, şehir, burç, takım, avatar
- Kaydet → `PATCH /api/me` + `refreshProfileHub()`
- Backend desteklemediği alan eklenmez

## Navigation

| Aksiyon | Route |
|---------|-------|
| Profil tab | `/profile` |
| Düzenle | `/profile/edit` |
| Cüzdan | `/wallet` |
| Jeton satın al | `/jeton-store` |
| Üyelik | `/premium-membership` |
| İşlemler | `/profile/transactions` |
| Ayarlar | `/settings` |
| Bildirimler | `/notifications` |
| Mesajlar | `/messages` |

## Cache

- `ref.keepAlive()` — profil/cüzdan provider'ları
- Logout → `clearAuthenticatedUserCache(ref)`
- Hesap değişimi → `WalletBalancesNotifier` auth id listener ile sıfırlama
- Retry profil → `invalidateProfileData(ref)` (ana sayfa dokunulmaz)

## Loading

- `PremiumProfileSkeleton` — avatar, isim, balance alanları
- Cüzdan kartı — jeton/CFC için ayrı wallet skeleton
- Tam ekran spinner yok

## Error

- Auth hatası: "Profil bilgileri yüklenemedi" + Tekrar Dene
- Extended profil hatası: `ProfileHubErrorBanner` + `invalidateProfileData`

## Empty

- Bio/takım/burç yoksa satır gizlenir — uydurulmaz

## Responsive

- `ResponsiveConstrained` max 1200px
- Meta chip'ler `Wrap` + ellipsis
- Test genişlikleri: 360–412 px

## Testler

- `test/features/profile/profile_extended_parse_test.dart`
- `test/features/wallet/wallet_balances_parse_test.dart`
- `test/features/auth/auth_session_cache_test.dart`
- `test/features/profile/profile_navigation_test.dart`
- Mevcut `test/features/profile/*` hub testleri

## Manuel Test

Cloud ortamında emülatör yok — gerçek cihazda doğrulanmalı:

- Login → profil avatar/ad/jeton
- Jeton değişince tüm ekranlarda aynı bakiye
- Profil düzenleme kaydı
- Logout → başka kullanıcıda eski veri görünmemeli
- Üyelik rozeti yalnızca backend tier varsa

## Backend Eksikleri

1. `liveStreamId` / canlı yayın profil alanı — profil header'da "Canlı" butonu için endpoint alanı net değil
2. Fal geçmişi — ayrı liste endpoint'i profil hub'da yok (istatistikler `/api/user/statistics` ile sınırlı)
3. `PATCH /api/me` vs `/api/user/profile` — çift path; mobil `updateMe` öncelikli

## Fake/Hardcoded Veri

- Production profil UI'da sabit jeton (981614 vb.) yok
- `jeton_packages_catalog.dart` — yalnızca `/api/jeton` başarısız olursa
- `membership_catalog_fallback.dart` — yalnızca API boşsa
- `payment_defaults.dart` — ödeme config fallback (web-only bilgiler)

## Değişen Dosyalar

- `mobile/lib/core/bootstrap/session_data_refresh.dart`
- `mobile/lib/core/providers/auth_selectors.dart`
- `mobile/lib/features/auth/presentation/providers/auth_providers.dart`
- `mobile/lib/features/profile/presentation/providers/profile_providers.dart`
- `mobile/lib/features/profile/presentation/providers/profile_hub_providers.dart`
- `mobile/lib/features/profile/presentation/profile_hub/profile_hub_header.dart`
- `mobile/lib/features/profile/presentation/profile_hub/profile_hub_currency_card.dart`
- `mobile/lib/features/profile/presentation/profile_hub/profile_hub_layout.dart`
- `mobile/lib/features/profile/presentation/profile_hub/profile_hub_error_banner.dart`
- `mobile/lib/features/profile/presentation/profile_hub/profile_meta_helpers.dart`
- `mobile/lib/features/profile/presentation/pages/profile_page.dart`
- `mobile/test/features/profile/*`, `mobile/test/features/wallet/*`, `mobile/test/features/auth/*`
- `mobile/pubspec.yaml`, `mobile/CHANGELOG.md`
