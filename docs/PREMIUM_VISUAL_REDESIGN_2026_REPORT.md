# Canlifal Premium Visual Redesign 2026 — rapor

**Dal:** `cursor/premium-visual-redesign-dfca` · **Sürüm:** `1.0.761+814`

## Envanter özeti (tarama)

| Kategori | Konum | Adet (webp/png) | Durum |
|----------|--------|-----------------|--------|
| Ana sayfa hızlı erişim | `assets/tiles/home-*.webp` | 10 | **Yenilendi** |
| Fal türleri | `assets/fortune/` | 19 | **Yenilendi** |
| Burçlar | `assets/zodiac/` | 12 | **Yenilendi** |
| Gold üyelik | `assets/membership/` | 5 | **Yenilendi** |
| Tüm Özellikler grid | `assets/tiles/feature-*.webp` | ~45 | Eski stil (Faz 2) |
| Oyunlar | `assets/games/` | 33 | Eski stil (Faz 2) |
| Arka planlar | `assets/backgrounds/` | 1+ | Faz 2 |
| Hediye Lottie/SVGA | `assets/gifts/` | dinamik | Dokunulmadı (envanter) |
| Ağ görselleri | Unsplash / CDN | çok | Fal hero yedek katmanı; kullanıcı içeriği değil |

**Görsel kullanım tipleri:** statik asset (yenilendi), sunucu URL (hediye, profil, yayın — değiştirilmedi), Lottie/SVGA (hediye animasyon).

## Yenilenen görsel sayısı

**46** ayrı AI üretimi kare ikon (1024 kaynak → WebP ~90–200 KB).

Premium kopya: `mobile/assets/images/premium/{home,fortune,zodiac,membership}/`  
Legacy uyum: aynı dosyalar `assets/fortune|zodiac|membership|tiles/` üzerine yazıldı.

## Yeni / güncellenen dosyalar

### Asset

- `mobile/assets/images/premium/home/*.webp` (10)
- `mobile/assets/images/premium/fortune/*.webp` (19)
- `mobile/assets/images/premium/zodiac/*.webp` (12)
- `mobile/assets/images/premium/membership/*.webp` (5)

### Flutter

- `mobile/lib/core/visual/premium/premium_asset_paths.dart`
- `mobile/lib/core/visual/premium/premium_glass_image.dart`
- `mobile/lib/features/home/presentation/widgets/approved/home_ref_quick_access.dart`
- `mobile/lib/features/fortune/presentation/data/fortune_type_images.dart`
- `mobile/lib/features/fortune/presentation/widgets/fortune_type_cover_image.dart`
- `mobile/lib/features/membership/presentation/widgets/membership_tier_art.dart`
- `mobile/lib/features/home/presentation/data/section_visual_catalog.dart`
- `mobile/lib/features/web_parity/presentation/pages/feature_hub_page.dart`
- `mobile/test/core/visual/premium_asset_paths_test.dart`

### Araçlar

- `scripts/premium-install-generated-assets.sh`
- JPG kaynak: `/opt/cursor/artifacts/assets/*.jpg` (GenerateImage)

## Henüz yenilenmeyen (Faz 2)

1. **`assets/tiles/feature-*.webp`** (~45) — Tüm Özellikler alt menüleri  
2. **`assets/games/*.webp`** (33)  
3. **Sosyal Fal & Tarot** sabit banner / boş durum (kodda çoğunlukla fal asset veya gradient)  
4. **Bana Özel** — kartlar çoğunlukla API + fal slug görselleri (fal seti yenilendi)  
5. **Boş / hata / yükleme** illüstrasyonları (Material ikon ağırlıklı)  
6. **Canlı / sesli oda** statik arka plan preset’leri (`login-night-sky.webp` vb.)

**Neden:** Tek oturumda 100+ ayrı üretim; öncelik ana menü + fal + burç + üyelik. Faz 2 için aynı referans görsel + `scripts/premium-install-generated-assets.sh` genişletilebilir.

## Test

- `flutter test test/core/visual/premium_asset_paths_test.dart`
- `dart analyze` (mobil paket)
- Manuel: ana sayfa 10 kutu, burç şeridi, fal hub, Gold üyelik, Fal & Tarot sosyal grid, açık/koyu tema, küçük geniş ekran

## Cihazda kontrol

- Ana sayfa karelerinde metin **görsel içinde değil**, alt etiket olarak kalmalı  
- Fal kartlarında metin okunaklı (overlay korundu)  
- APK boyutu: ~46 yeni WebP + legacy kopya — CI release gate sonrası `docs/LATEST_APK_BUILD.md`

## Tasarım ailesi

Referans: kullanıcı kolajı (Liquid Glass 3D, kozmik koyu zemin, mor/altın/turkuaz).  
Ortak widget: cam kenar + kontrollü glow (`PremiumGlassImage`).
