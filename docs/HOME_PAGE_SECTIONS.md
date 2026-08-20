# Ana sayfa bölüm envanteri

Kayıt: `mobile/lib/features/home/presentation/widgets/home_page_sections.dart`  
Sürüm notları: `mobile/CHANGELOG.md`  
Tasarım token'ları: `home_approved_design.dart`, `home_premium_design.dart`

## Yükleme katmanları

| Katman | Açıklama |
|--------|----------|
| **Anında** | `RepaintBoundary` — header, ticker |
| **Gecikmeli** | `HomeDeferredSection` — `StartupPerf` gecikmesi ile mount |
| **Viewport** | `HomeViewportSection` — kaydırma yakınına gelince mount + API |

Her bölüm bağımsız skeleton / hata / boş durum gösterir (`HomeSectionShell`, `PremiumSkeleton`).

Yenileme: `refreshHomeData()` + `invalidateHomeKeepAliveProviders()` (`home_providers.dart`).

## Bölüm sırası (üst → alt) — V1 premium (1.0.320+)

| # | Widget | API / kaynak | Lazy |
|---|--------|--------------|------|
| 1 | `HomeHeader` | Cüzdan, bildirim, mesaj, arama, Keşfet | — |
| 2 | `HomeTickerStrip` | `GET /api/homepage-ticker` | — |
| 3 | `HomePromoPopupBanner` | `GET /api/popups` | deferred |
| 4 | `HomeBannerCarousel` | Banner compound | deferred |
| 5 | `HomeQuickActions` | `GET /api/homepage-buttons` + Oyunlar/Hediyeler/Yayıncı Ol yedek | — |
| 6 | `StoriesSection` | `GET /api/stories` | deferred |
| 7 | `LiveBroadcastSection` | Canlı yayınlar | deferred |
| 8 | `VoiceRoomSection` | Sesli odalar + presence | deferred |
| 9 | `PsychicsHomeSection` | `GET /api/fortune-tellers` | deferred |
| 10 | `HomeAdvisorsRow` | `GET /api/advisors/online` | deferred |
| 11 | `FortuneSection` | `GET /api/homepage-fortune-cards` + katalog (14 tür) | deferred |
| 12 | `HomeBanaOzelSection` | `GET /api/bana-ozel` | deferred |
| 13 | `HomeFortuneRequestTypesSection` | `GET /api/fortune-request-types` | deferred |
| 14 | `HomeOnlineFalSection` | `GET /api/online-fal` | deferred + viewport |
| 15 | `MoreFortunesButton` | `/fortune/types` | deferred |
| 16 | `HomeGamesSection` | `GET /api/games`, oyun merkezi | deferred + viewport |
| 17 | `HomeHoroscopeSection` | 12 burç + profil burcu vurgusu | deferred + viewport |

## Sesli odalar (ana sayfa)

- `homeLiveVoiceRoomsProvider` VIP Gold hariç odaları listeler; popülerliğe göre sıralar.
- Online sayısı: SSE presence + API (`voiceRoomsPresenceProvider`).
- Oda açma maliyeti: `LiveRemoteDataSource.openRoomJetonCost` (hardcoded UI yok).

## Kaldırılan ana sayfa bölümleri (1.0.246+)

Aşağıdakiler ana sayfadan çıkarıldı (ilgili hub/rotalardan erişilebilir):

- Platform istatistikleri, sosyal şerit, homepage-buttons satırı
- Trend videolar, trend konular, yayın görselleri
- Liderlik tabloları, büyüme teaser'ları
- Ünlüler, fan kulüpleri, futbol, blog, keşfet grid, Gold üyelik

Widget dosyaları repoda durur; yalnızca `home_page_sections.dart` listesinden çıkarıldı.

## Ortak yardımcılar

| Dosya | Kullanım |
|-------|----------|
| `approved/home_section_title.dart` | Bölüm başlıkları (premium tipografi) |
| `premium_2026/home_section_shell.dart` | Skeleton / hata / boş durum kabuğu |
| `premium_2026/home_horizontal_list.dart` | Tutarlı yatay liste padding |
| `discover_premium_2026/discover_premium_room_card.dart` | Sesli oda kartı (online, PK, müzik) |
