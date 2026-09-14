import 'package:flutter/material.dart';

import '../theme/app_theme_extensions.dart';

/// CDS tipografi — tema textTheme + kontrollü ölçek (12–32).
abstract final class CdsTypography {
  static TextStyle display(BuildContext context) =>
      context.text.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ) ??
      const TextStyle(fontSize: 28, fontWeight: FontWeight.w800);

  static TextStyle title(BuildContext context) =>
      context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800) ??
      const TextStyle(fontSize: 20, fontWeight: FontWeight.w800);

  static TextStyle body(BuildContext context) =>
      context.text.bodyMedium ?? const TextStyle(fontSize: 15);

  static TextStyle label(BuildContext context) =>
      context.text.labelLarge?.copyWith(fontWeight: FontWeight.w700) ??
      const TextStyle(fontSize: 13, fontWeight: FontWeight.w700);

  static TextStyle caption(BuildContext context) =>
      context.text.bodySmall?.copyWith(
            color: context.colors.onSurfaceMuted,
          ) ??
      TextStyle(fontSize: 12, color: context.colors.onSurfaceMuted);
}
