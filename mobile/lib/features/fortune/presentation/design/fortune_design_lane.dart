import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/cds.dart';
import '../../../../core/performance/animation_perf.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../widgets/fortune_mystic_background.dart';
import '../widgets/ultra_premium/ultra_fortune_cosmic_background.dart';
import '../widgets/ultra_premium/ultra_fortune_tokens.dart';

/// Hub → Session → Result ortak motion (tarot / açılış animasyonları).
abstract final class FortuneLaneMotion {
  static const Duration cardEnter = CdsMotion.fast;
  static const Duration standard = CdsMotion.standard;
  static const Duration emphasis = CdsMotion.emphasis;

  static const Curve curve = Curves.easeOutCubic;
}

enum FortuneLaneSurface { hub, session, result }

/// Fal akışı ortak kart — CDS + mistik accent.
class FortuneLaneCard extends ConsumerWidget {
  const FortuneLaneCard({
    super.key,
    required this.child,
    this.onTap,
    this.accent,
    this.padding,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? accent;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = accent ?? context.colors.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CdsRadius.lg),
        border: Border.all(color: a.withValues(alpha: 0.28)),
      ),
      child: CdsCard(
        variant: CdsCardVariant.glass,
        onTap: onTap,
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Hub cosmic / session mystic / result düz arka plan.
class FortuneLaneBackdrop extends ConsumerWidget {
  const FortuneLaneBackdrop({
    super.key,
    required this.surface,
    required this.child,
    this.scrollParallax,
  });

  final FortuneLaneSurface surface;
  final Widget child;
  final ScrollParallaxNotifier? scrollParallax;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = ref.watch(cdsFxProvider).performanceMode;
    switch (surface) {
      case FortuneLaneSurface.hub:
        return UltraFortuneCosmicBackground(
          scrollParallax: scrollParallax,
          reduceMotion: reduceMotion,
          child: child,
        );
      case FortuneLaneSurface.session:
        return FortuneMysticBackground(child: child);
      case FortuneLaneSurface.result:
        return ColoredBox(
          color: UltraFortuneTokens.deepNight,
          child: child,
        );
    }
  }
}

/// Session yükleme ekranı — ortak lane dili.
class FortuneLaneSessionLoading extends ConsumerWidget {
  const FortuneLaneSessionLoading({
    super.key,
    required this.title,
    required this.accent,
  });

  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FortuneLaneBackdrop(
        surface: FortuneLaneSurface.session,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: accent),
              const SizedBox(height: CdsSpacing.lg),
              Text(
                '$title hazırlanıyor…',
                style: CdsTypography.title(context).copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
