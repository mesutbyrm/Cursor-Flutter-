import 'package:flutter/material.dart';

/// Telefon / tablet için ortalanmış içerik genişliği.
abstract final class ResponsiveLayout {
  static const double maxContentWidth = 560;
  static const double wideBreakpoint = 720;
  static const double tabletBreakpoint = 480;

  static double horizontalInset(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w <= maxContentWidth) return 16;
    return (w - maxContentWidth) / 2;
  }

  static EdgeInsets pagePadding(
    BuildContext context, {
    double top = 0,
    double bottom = 0,
  }) {
    final h = horizontalInset(context);
    return EdgeInsets.fromLTRB(h, top, h, bottom);
  }

  /// Jeton paket grid sütun sayısı.
  static int gridColumns(double width) {
    if (width >= wideBreakpoint) return 4;
    if (width >= tabletBreakpoint) return 3;
    return 2;
  }

  static double gridAspectRatio(int columns) {
    return columns >= 4 ? 1.2 : 1.35;
  }
}

/// İçeriği büyük ekranda ortalar; küçük ekranda tam genişlik.
class ResponsiveConstrained extends StatelessWidget {
  const ResponsiveConstrained({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveLayout.maxContentWidth,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
