import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/canlifal_brand_colors.dart';
import 'package:canlifal_social/features/home/presentation/theme/home_approved_design.dart';

double _luminance(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  const themes = {
    'dark': AppThemeColors.dark,
    'amoled': AppThemeColors.amoled,
    'light': AppThemeColors.light,
  };

  group('okunabilirlik (WCAG kontrast)', () {
    themes.forEach((name, c) {
      test('$name: ana metin zemin üzerinde >= 7:1', () {
        expect(contrast(c.onSurface, c.scaffoldBackground), greaterThan(7));
        expect(contrast(c.onSurface, c.surfaceElevated), greaterThan(7));
      });

      test('$name: ikincil ve soluk metin >= 4.5:1', () {
        expect(
          contrast(c.onSurfaceVariant, c.scaffoldBackground),
          greaterThan(4.5),
        );
        expect(
          contrast(c.onSurfaceMuted, c.scaffoldBackground),
          greaterThan(4.5),
        );
      });

      test('$name: dolgu üzerindeki metin (birincil/ikincil) >= 4.5:1', () {
        expect(contrast(c.onPrimary, c.primary), greaterThan(4.5));
        expect(contrast(c.onSecondary, c.secondary), greaterThan(4.5));
      });
    });

    test('koyu temada metin vurgusu (açık mor) zeminde >= 4.5:1', () {
      expect(
        contrast(CanlifalBrandColors.violetBright, AppThemeColors.dark.scaffoldBackground),
        greaterThan(4.5),
      );
    });
  });

  group('ColorScheme bütünlüğü', () {
    setUp(AppTheme.clearCacheForTest);

    test('container renkleri ana renkten ayrışır (düz dolgu değil)', () {
      for (final theme in [AppTheme.dark(), AppTheme.light(), AppTheme.amoled()]) {
        final s = theme.colorScheme;
        expect(s.primaryContainer, isNot(s.primary));
        expect(s.secondaryContainer, isNot(s.secondary));
        expect(
          contrast(s.onPrimaryContainer, s.primaryContainer),
          greaterThan(4.5),
        );
        expect(
          contrast(s.onSecondaryContainer, s.secondaryContainer),
          greaterThan(4.5),
        );
      }
    });

    test('yükseltilmiş yüzeylere renk tonu binmez', () {
      expect(AppTheme.dark().colorScheme.surfaceTint, Colors.transparent);
      expect(AppTheme.light().colorScheme.surfaceTint, Colors.transparent);
    });

    test('koyu tema derin siyah + antrasit, mor + turkuaz vurgu', () {
      final s = AppTheme.dark().colorScheme;
      expect(AppTheme.dark().scaffoldBackgroundColor, CanlifalBrandColors.ink);
      expect(s.primary, CanlifalBrandColors.violetStrong);
      expect(s.secondary, CanlifalBrandColors.turquoise);
    });

    test('açık ve koyu tema aynı marka rengini paylaşır', () {
      final light = AppTheme.light().colorScheme.primary;
      final dark = AppTheme.dark().colorScheme.primary;
      // İkisi de mor ailesinde (ton 255–275°).
      for (final c in [light, dark]) {
        final hue = HSLColor.fromColor(c).hue;
        expect(hue, inInclusiveRange(250, 280));
      }
    });
  });

  group('HomeApprovedDesign temaya duyarlı renkler', () {
    Future<Map<String, Color>> resolve(WidgetTester tester, ThemeData theme) async {
      late Map<String, Color> out;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              out = {
                'text': HomeApprovedDesign.textPrimaryOf(context),
                'bg': Theme.of(context).scaffoldBackgroundColor,
              };
              return const SizedBox();
            },
          ),
        ),
      );
      return out;
    }

    testWidgets('açık temada sayfa metni koyu ve okunur', (tester) async {
      final r = await resolve(tester, AppTheme.light());
      expect(contrast(r['text']!, r['bg']!), greaterThan(7));
    });

    testWidgets('koyu temada sayfa metni açık ve okunur', (tester) async {
      final r = await resolve(tester, AppTheme.dark());
      expect(r['text'], HomeApprovedDesign.textPrimary);
      expect(contrast(r['text']!, r['bg']!), greaterThan(7));
    });
  });
}
