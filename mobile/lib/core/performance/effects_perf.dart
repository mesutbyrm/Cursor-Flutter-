import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme_extensions.dart';
import '../ui/platform_blur.dart';
import 'list_perf.dart';

/// Cam / blur / gölge katmanları — gereksiz yeniden oluşturma yok.
enum GlassTier {
  /// Blur ve cam yok — liste / grid satırları.
  static,

  /// Sabit chrome (header, dock, input bar).
  chrome,

  /// Sheet / modal.
  elevated,

  /// Kısa hero geçişi.
  hero,
}

/// Blur, shadow ve glass efekt performansı.
abstract final class EffectsPerf {
  static final _blurCache = <int, ImageFilter>{};

  /// [ImageFilter.blur] önbelleği — build() içinde yeni filter oluşturma.
  static ImageFilter blurFilter(double sigma) {
    if (sigma <= 0) {
      return ImageFilter.blur(sigmaX: 0, sigmaY: 0);
    }
    final key = (sigma * 10).round();
    return _blurCache.putIfAbsent(
      key,
      () => ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    );
  }

  static bool blurEnabled(BuildContext context) {
    return PlatformBlur.supportsBackdropBlur && context.colors.useGlassBlur;
  }

  static double sigma(GlassTier tier, BuildContext context) {
    if (!blurEnabled(context)) return 0;
    return switch (tier) {
      GlassTier.static => 0,
      GlassTier.chrome => 18,
      GlassTier.elevated => 22,
      GlassTier.hero => 12,
    };
  }

  /// Animasyonlu alt ağaçları izole eder.
  static Widget repaint(Widget child) => ListPerf.repaint(child);

  /// Tek blur katmanı + RepaintBoundary.
  static Widget backdrop({
    required Widget child,
    required double sigma,
    BorderRadius? borderRadius,
  }) {
    if (sigma <= 0) return repaint(child);

    Widget blurred = SafeBackdropFilter(
      filter: blurFilter(sigma),
      child: child,
    );

    if (borderRadius != null) {
      blurred = ClipRRect(borderRadius: borderRadius, child: blurred);
    } else {
      blurred = ClipRect(child: blurred);
    }

    return repaint(blurred);
  }

  /// Liste / grid satırı — gölge + fill, blur yok.
  static Widget listSurface({
    required Widget child,
    required BoxDecoration decoration,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
    BorderRadius? borderRadius,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    Widget content = Container(
      padding: padding,
      decoration: decoration.copyWith(borderRadius: radius),
      child: child,
    );
    content = repaint(content);
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: radius, child: content),
    );
  }

  /// Sohbet balonu — opak fill, blur yok (liste içinde BackdropFilter kullanma).
  static BoxDecoration chatBubble({
    Color fill = const Color(0x61000000),
    Color border = const Color(0x1AFFFFFF),
    double radius = 16,
  }) {
    return BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
    );
  }

  /// Sabit chrome bar — tek blur katmanı.
  static Widget chromeBar({
    required Widget child,
    required BuildContext context,
    double? sigma,
    BorderRadius? borderRadius,
    BoxDecoration? decoration,
  }) {
    final effectiveSigma = sigma ?? EffectsPerf.sigma(GlassTier.chrome, context);
    Widget bar = Container(
      decoration: decoration,
      child: child,
    );
    return backdrop(
      sigma: effectiveSigma,
      borderRadius: borderRadius,
      child: bar,
    );
  }

  /// Blur alt ağacını animasyon dışında tut — yalnızca [transform] ölçeklenir.
  static Widget pressScale({
    required Widget blurredChild,
    required bool pressed,
    double scaleDown = 0.98,
  }) {
    return AnimatedScale(
      scale: pressed ? scaleDown : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: blurredChild,
    );
  }

  /// Önbellekli gölge — aynı parametrelerle tekrar oluşturma.
  static final _shadowCache = <String, List<BoxShadow>>{};

  static List<BoxShadow> cachedShadow({
    required Color color,
    double blurRadius = 16,
    double spreadRadius = 0,
    Offset offset = Offset.zero,
  }) {
    final key =
        '${color.toARGB32()}_${blurRadius}_${spreadRadius}_${offset.dx}_${offset.dy}';
    return _shadowCache.putIfAbsent(
      key,
      () => [
        BoxShadow(
          color: color,
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
          offset: offset,
        ),
      ],
    );
  }
}
