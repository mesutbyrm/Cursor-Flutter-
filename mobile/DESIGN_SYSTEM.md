# Canlifal Premium Design System

TikTok × Bigo Live × Discord × Instagram karışımı — Material 3, koyu varsayılan, modüler Flutter UI.

## Mimari

- **Clean Architecture:** `features/<name>/{data,domain,presentation}`
- **State:** Riverpod (`Provider`, `FutureProvider`, `AsyncNotifier`)
- **Navigasyon:** `go_router` + `StatefulShellRoute`
- **Tema:** `AppTheme` + `CanlifalTokens` (ThemeExtension)

## Token katmanı

| Dosya | Kullanım |
|-------|----------|
| `lib/core/theme/app_colors.dart` | Renkler, gradientler |
| `lib/core/theme/app_spacing.dart` | Boşluk, radius, layout ölçüleri |
| `lib/core/theme/canlifal_tokens.dart` | `context.tokens` — M3 extension |
| `lib/core/theme/app_theme.dart` | `AppTheme.dark()` / `light()` |
| `lib/core/theme/app_design.dart` | Eski importlar (yavaşça kaldırılacak) |

## Premium UI kit

```dart
import 'package:canlifal_social/core/ui/premium/premium.dart';
```

| Bileşen | Amaç |
|---------|------|
| `PremiumScaffold` | Gradient arka plan + SafeArea |
| `PremiumCard` | Neon çerçeveli kart |
| `NeonButton` | Gradient CTA |
| `LiveBadge` | CANLI rozeti |
| `GradientFab` | Orta alt FAB |
| `PremiumNavBar` | Alt navigasyon (blur yok) |
| `PremiumSectionHeader` | Bölüm başlığı |

## Tema modu

```dart
ref.read(themeModeProvider.notifier).toggle();
```

Varsayılan: **dark**. `MaterialApp` hem `theme` hem `darkTheme` tanımlı.

## Ekran migrasyon sırası (önerilen)

1. ✅ Shell / nav bar / section header
2. ✅ Keşfet (`feed_page`, discover widgets)
3. ✅ Sosyal (`social_page`, stories rail, instagram widgets)
4. ✅ Canlı (`live_page`, prep, room, gifts)
5. ✅ Sesli oda / TRTC
6. ✅ Profil / auth / mesajlar / bildirimler

Her ekranda:

- `AppDesign` / hardcoded `Color(0x…)` → `Theme.of(context)` veya `AppColors`
- Derin `Column` içinde `Stack` → düz `ListView` / `Sliver`
- `Image.network` → `CachedNetworkImage` + `memCacheWidth`
- Ağır `BackdropFilter` → opak/semi-opak `DecoratedBox`
- Tekrarlayan UI → `core/ui/premium/`

## Performans kuralları

- `RepaintBoundary` animasyonlu / gradient ağır bölgelerde
- Liste öğelerinde `const` constructor mümkün olduğunca
- `flutter_animate` yalnızca hero/FAB/hediye — liste içinde dikkatli
- RTC / canlı odada `setState` periyodik → `ValueNotifier` / Riverpod

## Yeni özellik şablonu

```
features/foo/
  data/datasources/
  data/repositories/
  domain/entities/
  domain/repositories/
  presentation/pages/
  presentation/providers/
  presentation/widgets/
```
