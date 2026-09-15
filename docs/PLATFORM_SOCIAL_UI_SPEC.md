# Platform sosyal — UI spesifikasyonu (Flutter)

> **Kit:** `mobile/lib/features/platform_social/presentation/widgets/platform_social_ui_kit.dart`  
> **Sürüm:** 1.0.523+564

## Renk paleti

| Token | Hex | Kullanım |
|--------|-----|----------|
| `bgTop` | `#0B0F1E` | Scaffold üst |
| `bgBottom` | `#15102B` | Gradient alt |
| `card` | `#1A1F35` | Cam kart |
| `accent` | `#B832FF` | Birincil CTA, vurgu |
| `accentSecondary` | `#448AFF` | Skor / link |
| `gold` | `#FFD54F` | Arena / sıralama |
| `success` | `#4ADE80` | Onay / online |
| `danger` | `#FF6B6B` | Beğen / red |

## Bileşenler

| Widget | Açıklama |
|--------|----------|
| `PlatformSocialScaffold` | Gradient arka plan + başlık/alt başlık |
| `PlatformSocialGlassCard` | 16px radius, ince border, gölge |
| `PlatformSocialSectionTitle` | Sol accent çizgili bölüm başlığı |
| `PlatformSocialStatusPill` | Durum rozeti (ton: neutral, accent, gold, …) |
| `PlatformSocialPrimaryButton` | Tam genişlik mor CTA |
| `PlatformSocialRankTile` | CFC / liderlik satırı |
| `PlatformSocialInteractionTile` | Tanış etkileşim satırı |
| `PlatformSocialEmptyState` | Boş liste |
| `AdminDiscoveryPermissionsCard` | Admin keşfet anahtarları kartı |
| `PlatformSocialStatTile` | İstatistik kutusu |
| `PlatformSocialInfoRow` | Etiket + değer |
| `PlatformSocialListRow` | Ajans liste satırı |
| `PlatformSocialCircleAction` | Keşif beğen/geç düğmesi |

## Ekranlar (uygulanan)

1. **Tanış** — profil sheet, Etkileşimler, keşif kartı + swipe destesi  
2. **CFC Arena** — hub liste + detay (sıralama, skor log)  
3. **Ajans** — talepler + tam panel (header, cüzdan, üyeler, kazanç, görev)  
4. **Admin** — Özet + Yetkiler keşfet kartı  
5. **Ses keşif** — oda kartında mesafe rozeti  

## Web (P6)

React iskelet: `backend-parity/.../UserCommandCenterModal.tsx` — üretimde aynı sekme isimleri ve mor accent ile hizalanmalı.
