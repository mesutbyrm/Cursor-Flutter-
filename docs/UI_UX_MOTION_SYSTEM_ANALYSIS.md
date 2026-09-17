# Canlifal — UI/UX & Motion System Analizi (2026-09-17)

## Mevcut mimari özeti

| Katman | Konum | Durum |
|--------|--------|--------|
| Theme (M3) | `lib/core/theme/app_theme.dart`, `app_theme_colors.dart`, `canlifal_tokens.dart` | Dark/AMOLED/light, Google Fonts |
| Premium 2026 tokens | `lib/core/ui/premium_2026/premium_2026_tokens.dart`, `premium_motion.dart` | Renk + süre/curve |
| CDS v1 | `lib/core/design_system/cds*.dart` | Button, card, spacing, typography, motion (minimal) |
| Sayfa geçişleri | `lib/core/navigation/app_page_transitions.dart` | fadeSlide, sharedAxis, NoBarrier Android |
| Router | `lib/app/router/app_router.dart` | `StatefulShellRoute` + 5 tab |
| Alt nav | `bottom_navigation_widget.dart`, `main_shell_page.dart` | AnimatedContainer 180ms |
| Skeleton/shimmer | `lib/core/ui/premium/premium_skeleton.dart` | `flutter_animate` shimmer |
| FX performans | `lib/core/design_system/cds_fx.dart` | performanceMode — dekoratif FX kapatma |
| Gold/VIP | `lib/features/vip_gold/` | `VipAvatarFrame`, `VipBadge`, `vip_gold_tokens` |
| Ana sayfa | `home_page.dart` + `home_page_sections.dart` | Deferred lazy sections |
| Canlı kartlar | `live_broadcast_section.dart` | InkWell, LiveBadge |
| Fal/Tarot | `lib/features/fortune/` ultra_premium widgets | Kart skeleton |
| Tanış | `tanis_kaynas_page.dart` | Swipe kartları (mevcut) |
| Sosyal | `lib/features/social/` | Feed + discovery |
| **Dokunulmayacak** | `live_broadcast_room_page`, PK providers, TRTC, SSE, gift API | İş mantığı |

## Tespit edilen boşluklar

1. **Motion parçalı** — `CdsMotion`, `PremiumMotion`, `flutter_animate` ayrı ayrı; tek sözlük yok.
2. **Micro-interaction tutarsız** — Bazı nav/button scale var, çoğu InkWell düz.
3. **Giriş animasyonları** — Ana sayfa bölümleri lazy ama staggered entrance yok.
4. **Gold ring** — Statik gradient; profil açılışında hafif pulse yok (performans modunda kapalı).
5. **Hard-coded renkler** — Home approved + premium theme’de; CDS’ye tam taşınmamış (kademeli).

## Uygulama planı (bu dalga)

1. `lib/core/motion/canlifal_motion_tokens.dart` — micro/normal/premium süreler
2. `lib/core/motion/canlifal_motion_widgets.dart` — Pressable, Entrance, Stagger, Gold ring pulse
3. CDS `cds_motion.dart` → token alias
4. Bottom nav + `CdsButton` + canlı kart press/entrance
5. Sonraki dalgalar: profil header, tarot flip, tanış swipe polish, gold satın alma hero (işlev aynı)

## Çakışma / risk

- PK/RTC dosyalarına import eklenmemeli.
- `CdsFxState.performanceMode` açıkken gold pulse / ekstra shimmer devre dışı.
