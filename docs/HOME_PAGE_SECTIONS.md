# Ana sayfa bölüm envanteri

Kayıt: `mobile/lib/features/home/presentation/widgets/home_page_sections.dart`  
Sürüm notları: `mobile/CHANGELOG.md`

## Yükleme katmanları

| Katman | Açıklama |
|--------|----------|
| **Anında** | `RepaintBoundary` — header, ticker |
| **Gecikmeli** | `HomeDeferredSection` — `StartupPerf` gecikmesi ile mount |
| **Viewport** | `HomeViewportSection` — kaydırma yakınına gelince mount + API |

Yenileme: `refreshHomeData()` + `invalidateHomeKeepAliveProviders()` (`home_providers.dart`).

## Bölüm sırası (üst → alt) — sadeleştirilmiş (1.0.246+)

| # | Widget | API / kaynak | Lazy |
|---|--------|--------------|------|
| 1 | `HomeHeader` | Cüzdan, bildirim, arama | — |
| 2 | `HomeTickerStrip` | `GET /api/homepage-ticker` | — |
| 3 | `HomePromoPopupBanner` | `GET /api/popups` | deferred |
| 4 | `HomeBannerCarousel` | Banner compound | deferred |
| 5 | `HomeQuickActions` | Hızlı erişim kısayolları | — |
| 6 | `StoriesSection` | Hikayeler | deferred |
| 7 | `LiveBroadcastSection` | Canlı yayınlar | deferred |
| 8 | `VoiceRoomSection` | Dolu sesli odalar (`displayOnline > 0`) | deferred |
| 9 | `PsychicsHomeSection` | Canlı falcılar | deferred |
| 10 | `HomeAdvisorsRow` | Danışmanlar | deferred |
| 11 | `FortuneSection` | `GET /api/homepage-fortune-cards` | deferred |
| 12 | `HomeFortuneRequestTypesSection` | `GET /api/fortune-request-types` | deferred |
| 13 | `HomeOnlineFalSection` | `GET /api/online-fal` | deferred + viewport |
| 14 | `MoreFortunesButton` | Fal hub yönlendirme | deferred |
| 15 | `HomeGamesSection` | `GET /api/games`, oyun merkezi | deferred + viewport |
| 16 | `HomeHoroscopeSection` | `POST /api/horoscope/daily` | deferred + viewport |

## Sesli odalar (ana sayfa)

- `homeLiveVoiceRoomsProvider` yalnızca `displayOnline > 0` odaları listeler; boş odalar gizlenir.
- Online sayısı: `max(SSE presence, API onlineCount/userCount)`.
- Kart rozetleri backend alanlarından: `isPkLive`, `musicPlaying` / `activeDjId` / `djUserIds`.

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
| `approved/home_section_title.dart` | Tüm bölüm başlıkları (emoji + aksiyon) |
| `discover_premium_2026/discover_premium_room_card.dart` | Sesli oda kartı (online, PK, müzik) |
