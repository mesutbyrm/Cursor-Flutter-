# Ana sayfa bölüm envanteri

Kayıt: `mobile/lib/features/home/presentation/widgets/home_page_sections.dart`  
Sürüm notları: `mobile/CHANGELOG.md` (faz 1–11)

## Yükleme katmanları

| Katman | Açıklama |
|--------|----------|
| **Anında** | `RepaintBoundary` — header, ticker, butonlar |
| **Gecikmeli** | `HomeDeferredSection` — `StartupPerf` gecikmesi ile mount |
| **Viewport** | `HomeViewportSection` — kaydırma yakınına gelince mount + API |

Yenileme: `refreshHomeData()` + `invalidateHomeKeepAliveProviders()` (`home_providers.dart`).

## Bölüm sırası (üst → alt)

| # | Widget | API / kaynak | Lazy |
|---|--------|--------------|------|
| 1 | `HomeHeader` | Cüzdan, bildirim, arama | — |
| 2 | `HomeTickerStrip` | `GET /api/homepage-ticker` | — |
| 3 | `HomePromoPopupBanner` | `GET /api/popups` | deferred |
| 4 | `HomePlatformStatsSection` | `GET /api/public-stats` | — |
| 5 | `HomeSocialStripSection` | `public-stats.recentLogins`, `GET /api/user/likers` | deferred |
| 6 | `HomeBannerCarousel` | Banner compound | deferred |
| 7 | `HomeHomepageButtonsRow` | `GET /api/homepage-buttons` | — |
| 8 | `HomeQuickActions` | İlk 3 homepage-button | — |
| 9 | `TrendingVideoSection` | Kısa video keşfet | deferred |
| 10 | `HomeTrendingTopicsSection` | `GET /api/trends` | deferred |
| 11 | `StoriesSection` | Hikayeler | deferred |
| 12 | `LiveBroadcastSection` | Canlı yayınlar | deferred |
| 13 | `HomeBroadcastImagesSection` | `GET /api/broadcast-images` | deferred + viewport |
| 14 | `VoiceRoomSection` | Sesli odalar | deferred |
| 15 | `PsychicsHomeSection` | Canlı falcılar | deferred |
| 16 | `HomeAdvisorsRow` | Danışmanlar | deferred |
| 17 | `FortuneSection` | `GET /api/homepage-fortune-cards` | deferred |
| 18 | `HomeFortuneRequestTypesSection` | `GET /api/fortune-request-types` | deferred |
| 19 | `HomeOnlineFalSection` | `GET /api/online-fal` | deferred + viewport |
| 20 | `MoreFortunesButton` | Fal hub yönlendirme | deferred |
| 21 | `HomeGamesRow` | `GET /api/games` | deferred |
| 22 | `HomeGameCenterSection` | Oyun liderliği önizleme | deferred + viewport |
| 23 | `HomeLeaderboardsSection` | Hediye / PK / ajans liderliği | deferred + viewport |
| 24 | `HomeGrowthTeasersSection` | Görevler, davet, reklam | deferred + viewport |
| 25 | `HomeCelebritiesSection` | `GET /api/celebrities` | deferred + viewport |
| 26 | `FanClubSection` | `GET /api/fan-clubs` | deferred + viewport |
| 27 | `HomeFootballSection` | `GET /api/football` | deferred + viewport |
| 28 | `HomeHoroscopeSection` | `POST /api/horoscope/daily` | deferred + viewport |
| 29 | `HomeBlogRecentSection` | `GET /api/blog/recent` | deferred + viewport |
| 30 | `DiscoverSection` | Keşfet kartları | deferred + viewport |
| 31 | `GoldSection` | Gold üyelikler | deferred + viewport |

## Birleştirilmiş bölümler (faz 9–10)

- **Liderlik:** `HomeGiftLeaderboardSection` + `HomePkLeaderboardSection` + `HomeAgencyLeaderboardSection` → `HomeLeaderboardsSection`
- **Sosyal:** `HomeRecentLoginsSection` + `HomeUserLikersSection` → `HomeSocialStripSection`
- **İstatistik:** `HomePlatformStatsStrip` + `HomePlatformStatsGrid` → `HomePlatformStatsSection`
- **Büyüme:** `HomeDailyMissionsTeaser` + `HomeInviteReferralTeaser` + `HomeWatchAdTeaser` → `HomeGrowthTeasersSection`

## Kaldırılan / kullanılmayan (faz 11)

Eski mockup veya yinelenen widget'lar silindi; yerine `approved/` altındaki sürümler kullanılır:

- `HomeVoiceRoomsRow` → `VoiceRoomSection`
- `HomeLiveStreamsRow` → `LiveBroadcastSection`
- `HomeStoriesSection` → `StoriesSection`
- `HomeFortuneGrid` → `FortuneSection`
- `HomeDiscoverGrid` → `DiscoverSection`
- `HomeTrendVideosRow` → `TrendingVideoSection`
- `HomeGoldMembershipsRow` → `GoldSection`
- `DiscoverPremiumHomeSection` — bilinçli olarak kaldırıldı (CHANGELOG 1.0.176)
- `home_header.dart` (kök) → `approved/home_header.dart`

## Ortak yardımcılar

| Dosya | Kullanım |
|-------|----------|
| `home_section_header.dart` | Oyunlar, danışmanlar, oyun merkezi başlıkları |
| `home_mystic_cover.dart` | Trend video ve premium kart kapakları |
| `premium_2026/premium_home_glass_card.dart` | Keşfet ve Gold kartları |
| `approved/home_section_title.dart` | Birleşik şerit başlıkları |
