import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

/// Premium tipografi — display / headline / label hiyerarşisi.
abstract final class PremiumTypography {
  static TextStyle _base(TextStyle? from, TextStyle fallback) {
    try {
      return GoogleFonts.plusJakartaSans(textStyle: from ?? fallback);
    } catch (_) {
      return from ?? fallback;
    }
  }

  static TextStyle displayLarge(BuildContext context) => _base(
        Theme.of(context).textTheme.displayLarge,
        const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          height: 1.1,
          color: AppColors.textPrimary,
        ),
      );

  static TextStyle displayMedium(BuildContext context) => _base(
        Theme.of(context).textTheme.displayMedium,
        const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          height: 1.15,
          color: AppColors.textPrimary,
        ),
      );

  static TextStyle headline(BuildContext context) => _base(
        Theme.of(context).textTheme.headlineSmall,
        const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: AppColors.textPrimary,
        ),
      );

  static TextStyle title(BuildContext context) => _base(
        Theme.of(context).textTheme.titleMedium,
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.textPrimary,
        ),
      );

  static TextStyle body(BuildContext context) => _base(
        Theme.of(context).textTheme.bodyMedium,
        const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.45,
          color: AppColors.textSecondary,
        ),
      );

  static TextStyle label(BuildContext context) => _base(
        Theme.of(context).textTheme.labelSmall,
        const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.textMuted,
        ),
      );

  static TextStyle navLabel(BuildContext context, {required bool selected}) =>
      _base(
        null,
        TextStyle(
          fontSize: 10,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          letterSpacing: selected ? 0.2 : 0,
          color: selected ? AppColors.textPrimary : AppColors.textMuted,
        ),
      );
}
