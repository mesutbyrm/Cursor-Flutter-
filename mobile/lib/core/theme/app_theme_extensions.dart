import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_theme_colors.dart';

export 'app_palette.dart' show AppPalette, AppPaletteX;

/// Tema renklerine kısayol — yeni kodda bunu kullanın.
extension AppThemeContext on BuildContext {
  AppThemeColors get colors {
    final palette = Theme.of(this).extension<AppPalette>();
    if (palette != null) return palette.colors;
    return Theme.of(this).brightness == Brightness.dark
        ? AppThemeColors.dark
        : AppThemeColors.light;
  }

  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;

  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;

  TextTheme get text => Theme.of(this).textTheme;

  ColorScheme get scheme => Theme.of(this).colorScheme;

  Color get accentPink => AppThemeColors.accentPink;

  Color get accentPurple => AppThemeColors.accentPurple;

  Color get accentCyan => AppThemeColors.accentCyan;

  Color get liveRed => AppThemeColors.liveRed;

  Color get coinGold => AppThemeColors.coinGold;

  Color get onlineGreen => AppThemeColors.onlineGreen;
}
