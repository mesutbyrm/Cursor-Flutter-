import 'package:flutter/material.dart';

import '../performance/effects_perf.dart';
import '../theme/app_theme_extensions.dart';
import 'cds_radius.dart';
import 'cds_shadows.dart';
import 'cds_spacing.dart';
import 'cds_fx.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CdsCardVariant { static, glass, interactive }

/// CDS kart yüzeyleri.
class CdsCard extends ConsumerWidget {
  const CdsCard({
    super.key,
    required this.child,
    this.variant = CdsCardVariant.static,
    this.onTap,
    this.padding,
  });

  final Widget child;
  final CdsCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perf = ref.watch(cdsFxProvider).performanceMode;
    final radius = BorderRadius.circular(CdsRadius.lg);
    final pad = padding ?? const EdgeInsets.all(CdsSpacing.lg);

    Widget content = Padding(padding: pad, child: child);

    final decoration = switch (variant) {
      CdsCardVariant.static => BoxDecoration(
          color: context.colors.surfaceElevated,
          borderRadius: radius,
          boxShadow: CdsShadows.elevation1(context),
          border: Border.all(color: context.colors.outlineVariant),
        ),
      CdsCardVariant.glass => BoxDecoration(
          color: context.colors.surfaceContainer.withValues(alpha: 0.72),
          borderRadius: radius,
          border: Border.all(color: context.colors.glassBorder),
          boxShadow: CdsShadows.elevation1(context),
        ),
      CdsCardVariant.interactive => BoxDecoration(
          color: context.colors.surfaceElevated,
          borderRadius: radius,
          boxShadow: CdsShadows.elevation2(context),
          border: Border.all(
            color: context.colors.primary.withValues(alpha: 0.35),
          ),
        ),
    };

    Widget card = DecoratedBox(decoration: decoration, child: content);

    if (variant == CdsCardVariant.glass && !perf) {
      card = EffectsPerf.backdrop(
        sigma: EffectsPerf.sigma(GlassTier.chrome, context),
        borderRadius: radius,
        child: card,
      );
    }

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: radius, child: card),
      );
    }

    return card;
  }
}
