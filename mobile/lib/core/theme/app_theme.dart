import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../navigation/app_page_transitions.dart';
import 'app_palette.dart';
import 'app_spacing.dart';
import 'app_theme_colors.dart';
import '../ui/premium_2026/premium_2026_tokens.dart';
import 'canlifal_brand_colors.dart';
import 'canlifal_tokens.dart';

/// Material 3 — merkezi [AppThemeColors] ile light / dark / AMOLED.
class AppTheme {
  AppTheme._();

  static ThemeData? _lightCache;
  static ThemeData? _darkCache;
  static ThemeData? _amoledCache;

  // Geriye dönük sabitler (yeni kod: context.colors)
  static const Color background = CanlifalBrandColors.ink;
  static const Color surface = CanlifalBrandColors.anthracite;
  static const Color surfaceElevated = CanlifalBrandColors.anthraciteRaised;
  static const Color accent = CanlifalBrandColors.violet;
  static const Color accentSecondary = CanlifalBrandColors.turquoise;
  static const Color onBackground = CanlifalBrandColors.textPrimary;
  static const Color muted = CanlifalBrandColors.textMuted;

  static ThemeData dark() =>
      _darkCache ??= _build(AppThemeColors.dark, CanlifalTokens.dark);

  static ThemeData amoled() =>
      _amoledCache ??= _build(AppThemeColors.amoled, CanlifalTokens.dark);

  static ThemeData light() =>
      _lightCache ??= _build(AppThemeColors.light, CanlifalTokens.light);

  /// Test / hot-reload — tema önbelleğini temizler.
  @visibleForTesting
  static void clearCacheForTest() {
    _lightCache = null;
    _darkCache = null;
    _amoledCache = null;
  }

  static ThemeData _build(AppThemeColors c, CanlifalTokens tokens) {
    final palette = AppPalette(c);
    final isDark = c.isDark;
    final p26 = isDark ? Premium2026Tokens.dark : Premium2026Tokens.light;
    // Koyu zeminde düz mor küçük metinde zayıf kalır; metin vurgusu açık ton.
    final accentText = isDark ? CanlifalBrandColors.violetBright : c.primary;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : c.outlineVariant;
    final controlRadius = BorderRadius.circular(AppSpacing.radiusMd);

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: c.brightness,
      scaffoldBackgroundColor: c.scaffoldBackground,
      colorScheme: c.toColorScheme(),
      extensions: [tokens, p26, palette],
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          // Android: FadeUpwards / Cupertino geçişleri gri modal barrier bırakabiliyor.
          TargetPlatform.android: NoBarrierPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );

    final textTheme = _textTheme(base.textTheme, c);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      // Ripple, sparkle'a göre GPU'da ucuz; hafif dokunma geri bildirimi.
      splashFactory: InkRipple.splashFactory,
      splashColor: c.primary.withValues(alpha: isDark ? 0.14 : 0.10),
      highlightColor: Colors.transparent,
      hoverColor: c.onSurface.withValues(alpha: 0.04),
      focusColor: c.primary.withValues(alpha: 0.12),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: c.onSurface,
        iconTheme: IconThemeData(color: c.onSurface, size: 22),
        actionsIconTheme: IconThemeData(color: c.onSurface, size: 22),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: c.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: tokens.navBarBackground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.primary.withValues(alpha: isDark ? 0.20 : 0.12),
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? accentText : c.onSurfaceMuted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: fontFamily,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? c.onSurface : c.onSurfaceMuted,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: tokens.navBarBackground,
        indicatorColor: c.primary.withValues(alpha: isDark ? 0.20 : 0.12),
        indicatorShape: const StadiumBorder(),
        selectedIconTheme: IconThemeData(color: accentText),
        unselectedIconTheme: IconThemeData(color: c.onSurfaceMuted),
        selectedLabelTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: c.onSurface,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c.onSurfaceMuted,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.onSurface,
        unselectedLabelColor: c.onSurfaceMuted,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: c.primary,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: c.primary, width: 3),
          borderRadius: BorderRadius.circular(3),
        ),
        dividerColor: Colors.transparent,
        overlayColor: WidgetStatePropertyAll(c.primary.withValues(alpha: 0.06)),
        splashFactory: InkRipple.splashFactory,
      ),
      cardTheme: CardThemeData(
        color: c.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: cardBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.dialogBackground,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 8,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          side: isDark ? BorderSide(color: cardBorder) : BorderSide.none,
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          color: c.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: c.onSurfaceVariant,
          height: 1.45,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.bottomSheetBackground,
        modalBackgroundColor: c.bottomSheetBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: c.onSurfaceMuted.withValues(alpha: 0.45),
        dragHandleSize: const Size(40, 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.snackBarBackground,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: CanlifalBrandColors.violetBright,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: c.onSurfaceVariant,
        textColor: c.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        minVerticalPadding: AppSpacing.sm,
        shape: RoundedRectangleBorder(borderRadius: controlRadius),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: c.onSurface,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: c.onSurfaceMuted,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: controlRadius,
          side: BorderSide(color: cardBorder),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(color: c.onSurface),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(c.surfaceElevated),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: controlRadius,
              side: BorderSide(color: cardBorder),
            ),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceContainer,
        selectedColor: c.primary.withValues(alpha: isDark ? 0.24 : 0.14),
        disabledColor: c.surfaceContainer.withValues(alpha: 0.5),
        checkmarkColor: accentText,
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          color: c.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: fontFamily,
          color: accentText,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        side: BorderSide(color: c.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: const StadiumBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.xl,
          ),
          shape: RoundedRectangleBorder(borderRadius: controlRadius),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.onSurface.withValues(alpha: 0.10),
          disabledForegroundColor: c.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          shadowColor: c.primary.withValues(alpha: 0.4),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.xl,
          ),
          shape: RoundedRectangleBorder(borderRadius: controlRadius),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentText,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: c.outline),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.xl,
          ),
          shape: RoundedRectangleBorder(borderRadius: controlRadius),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentText,
          shape: RoundedRectangleBorder(borderRadius: controlRadius),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.onSurface,
          highlightColor: c.onSurface.withValues(alpha: 0.06),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const StadiumBorder(),
        extendedTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: AppThemeColors.liveRed,
        textColor: Colors.white,
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.snackBarBackground,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: c.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: const BorderSide(color: AppThemeColors.liveRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: const BorderSide(
            color: AppThemeColors.liveRed,
            width: 1.5,
          ),
        ),
        hintStyle: TextStyle(fontFamily: fontFamily, color: c.onSurfaceMuted),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          color: c.onSurfaceVariant,
        ),
        floatingLabelStyle: TextStyle(
          fontFamily: fontFamily,
          color: accentText,
        ),
        prefixIconColor: c.onSurfaceMuted,
        suffixIconColor: c.onSurfaceMuted,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withValues(alpha: 0.32),
        selectionHandleColor: c.primary,
      ),
      iconTheme: IconThemeData(color: c.onSurfaceVariant),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.primary.withValues(alpha: 0.16),
        circularTrackColor: Colors.transparent,
        refreshBackgroundColor: c.surfaceElevated,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.primary,
        inactiveTrackColor: c.primary.withValues(alpha: 0.18),
        thumbColor: isDark ? Colors.white : c.primary,
        overlayColor: c.primary.withValues(alpha: 0.14),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(c.onPrimary),
        side: BorderSide(color: c.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.primary;
          return c.outline;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? c.onSurfaceMuted : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.primary;
          return isDark ? c.surfaceElevated : c.outline;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return c.outline;
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return c.onPrimary;
            return c.onSurfaceVariant;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return c.primary;
            return c.surfaceContainer;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: c.outlineVariant)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: controlRadius),
          ),
        ),
      ),
    );
  }

  /// pubspec'te tüm ağırlıklarıyla paketli aile (bkz. assets/google_fonts/).
  static const fontFamily = 'PlusJakartaSans';

  static TextTheme _textTheme(TextTheme base, AppThemeColors c) {
    final themed = base.apply(
      fontFamily: fontFamily,
      bodyColor: c.onSurface,
      displayColor: c.onSurface,
    );
    TextStyle? tune(TextStyle? s, {double? tracking, FontWeight? weight}) =>
        s?.copyWith(letterSpacing: tracking, fontWeight: weight);
    return themed.copyWith(
      displayLarge: tune(
        themed.displayLarge,
        tracking: -1.2,
        weight: FontWeight.w800,
      ),
      displayMedium: tune(
        themed.displayMedium,
        tracking: -1.0,
        weight: FontWeight.w800,
      ),
      displaySmall: tune(
        themed.displaySmall,
        tracking: -0.8,
        weight: FontWeight.w800,
      ),
      headlineLarge: tune(
        themed.headlineLarge,
        tracking: -0.6,
        weight: FontWeight.w800,
      ),
      headlineMedium: tune(
        themed.headlineMedium,
        tracking: -0.5,
        weight: FontWeight.w800,
      ),
      headlineSmall: tune(
        themed.headlineSmall,
        tracking: -0.4,
        weight: FontWeight.w700,
      ),
      titleLarge: tune(
        themed.titleLarge,
        tracking: -0.3,
        weight: FontWeight.w700,
      ),
      titleMedium: tune(
        themed.titleMedium,
        tracking: -0.1,
        weight: FontWeight.w600,
      ),
      titleSmall: tune(themed.titleSmall, weight: FontWeight.w600),
      labelLarge: tune(themed.labelLarge, weight: FontWeight.w700),
      bodyMedium: themed.bodyMedium?.copyWith(height: 1.45),
      bodyLarge: themed.bodyLarge?.copyWith(height: 1.5),
      bodySmall: themed.bodySmall?.copyWith(color: c.onSurfaceVariant),
    );
  }
}
