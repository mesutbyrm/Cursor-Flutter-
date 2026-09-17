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

## Faz 2 (1.0.553+) — uygulandı

- Profil hub: header + stats entrance; istatistik `CanlifalValueBump`
- Sosyal feed: ilk 8 gönderi stagger entrance; beğeni `CanlifalBurstIcon`
- Tanış swipe: snap süresi merkezi motion token
- Gold hub: crown hero entrance

## Faz 3 (1.0.554+) — uygulandı

- Gold üyelik: anlık satın alma sonrası `showCanlifalPurchaseSuccessOverlay` (FX performans modunda sade)
- Fal hub: «Bugünün Kehaneti» vitrininde `CanlifalTarotFlipCard` (dokun → flip)
- Ana sayfa banner: `CanlifalEntranceFadeSlide`
- Sosyal: yorum sheet başlık + ilk 6 yorum stagger; yükleme skeleton; feed load-more skeleton
- `CdsPressableButton` + tarot/purchase motion export (kademeli CTA entegrasyonu)

## Uygulama planı (kalan)

1. `CdsPressableButton` — birincil CTA’larda kademeli (Material ripple ile çakışmayan yerler)
2. Design token migrasyonu — `HomeApprovedDesign` hardcode → CDS
3. Diğer satın alma yolları (jeton/CFC checkout) — aynı success overlay
4. Figma MCP + dosya URL varsa: `figma-implement-motion` / `figma-design-to-code` ile piksel hizalama

## Çakışma / risk

- PK/RTC dosyalarına import eklenmemeli.
- `CdsFxState.performanceMode` açıkken gold pulse / ekstra shimmer devre dışı.
