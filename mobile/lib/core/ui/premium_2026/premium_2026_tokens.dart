import 'package:flutter/material.dart';

/// Material 3 + Liquid Glass — 2026 premium token seti.
@immutable
class Premium2026Tokens extends ThemeExtension<Premium2026Tokens> {
  const Premium2026Tokens({
    required this.radiusLiquid,
    required this.radiusSheet,
    required this.radiusPill,
    required this.glassFill,
    required this.glassFillElevated,
    required this.glassBorder,
    required this.glassHighlight,
    required this.shadowAmbient,
    required this.shadowFloating,
    required this.meshTop,
    required this.meshMid,
    required this.meshBottom,
    required this.navFloater,
  });

  final double radiusLiquid;
  final double radiusSheet;
  final double radiusPill;
  final Color glassFill;
  final Color glassFillElevated;
  final Color glassBorder;
  final Color glassHighlight;
  final List<BoxShadow> shadowAmbient;
  final List<BoxShadow> shadowFloating;
  final Gradient meshTop;
  final Gradient meshMid;
  final Gradient meshBottom;
  final Gradient navFloater;

  static const dark = Premium2026Tokens(
    radiusLiquid: 32,
    radiusSheet: 28,
    radiusPill: 999,
    glassFill: Color(0x38FFFFFF),
    glassFillElevated: Color(0x4DFFFFFF),
    glassBorder: Color(0x55FFFFFF),
    glassHighlight: Color(0x18FFFFFF),
    shadowAmbient: [
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 40,
        offset: Offset(0, 16),
      ),
    ],
    shadowFloating: [
      BoxShadow(
        color: Color(0x55FE2C55),
        blurRadius: 32,
        spreadRadius: -8,
        offset: Offset(0, 12),
      ),
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
    meshTop: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1E1038),
        Color(0xFF0B0B1E),
        Color(0xFF0A1528),
      ],
      stops: [0.0, 0.45, 1.0],
    ),
    meshMid: RadialGradient(
      center: Alignment(0.85, -0.2),
      radius: 0.9,
      colors: [
        Color(0x40B832FF),
        Colors.transparent,
      ],
    ),
    meshBottom: RadialGradient(
      center: Alignment(-0.7, 1.1),
      radius: 0.75,
      colors: [
        Color(0x35FE2C55),
        Colors.transparent,
      ],
    ),
    navFloater: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xCC14141C),
        Color(0xF014141C),
      ],
    ),
  );

  static const light = Premium2026Tokens(
    radiusLiquid: 32,
    radiusSheet: 28,
    radiusPill: 999,
    glassFill: Color(0xBFFFFFFF),
    glassFillElevated: Color(0xD9FFFFFF),
    glassBorder: Color(0x66FFFFFF),
    glassHighlight: Color(0x40FFFFFF),
    shadowAmbient: [
      BoxShadow(
        color: Color(0x1A000000),
        blurRadius: 32,
        offset: Offset(0, 12),
      ),
    ],
    shadowFloating: [
      BoxShadow(
        color: Color(0x33E91E63),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
    meshTop: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFF3E8FF),
        Color(0xFFF8F8FC),
        Color(0xFFE8F4FF),
      ],
    ),
    meshMid: RadialGradient(
      center: Alignment(1, -0.3),
      radius: 0.8,
      colors: [Color(0x33E91E63), Colors.transparent],
    ),
    meshBottom: RadialGradient(
      center: Alignment(-0.5, 1.2),
      radius: 0.7,
      colors: [Color(0x289C27B0), Colors.transparent],
    ),
    navFloater: LinearGradient(
      colors: [Color(0xF5FFFFFF), Color(0xFFFFFFFF)],
    ),
  );

  @override
  Premium2026Tokens copyWith({
    double? radiusLiquid,
    double? radiusSheet,
    double? radiusPill,
    Color? glassFill,
    Color? glassFillElevated,
    Color? glassBorder,
    Color? glassHighlight,
    List<BoxShadow>? shadowAmbient,
    List<BoxShadow>? shadowFloating,
    Gradient? meshTop,
    Gradient? meshMid,
    Gradient? meshBottom,
    Gradient? navFloater,
  }) {
    return Premium2026Tokens(
      radiusLiquid: radiusLiquid ?? this.radiusLiquid,
      radiusSheet: radiusSheet ?? this.radiusSheet,
      radiusPill: radiusPill ?? this.radiusPill,
      glassFill: glassFill ?? this.glassFill,
      glassFillElevated: glassFillElevated ?? this.glassFillElevated,
      glassBorder: glassBorder ?? this.glassBorder,
      glassHighlight: glassHighlight ?? this.glassHighlight,
      shadowAmbient: shadowAmbient ?? this.shadowAmbient,
      shadowFloating: shadowFloating ?? this.shadowFloating,
      meshTop: meshTop ?? this.meshTop,
      meshMid: meshMid ?? this.meshMid,
      meshBottom: meshBottom ?? this.meshBottom,
      navFloater: navFloater ?? this.navFloater,
    );
  }

  @override
  Premium2026Tokens lerp(ThemeExtension<Premium2026Tokens>? other, double t) {
    if (other is! Premium2026Tokens) return this;
    return Premium2026Tokens(
      radiusLiquid: radiusLiquid,
      radiusSheet: radiusSheet,
      radiusPill: radiusPill,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassFillElevated:
          Color.lerp(glassFillElevated, other.glassFillElevated, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassHighlight: Color.lerp(glassHighlight, other.glassHighlight, t)!,
      shadowAmbient: shadowAmbient,
      shadowFloating: shadowFloating,
      meshTop: meshTop,
      meshMid: meshMid,
      meshBottom: meshBottom,
      navFloater: navFloater,
    );
  }
}

extension Premium2026TokensX on BuildContext {
  Premium2026Tokens get p26 =>
      Theme.of(this).extension<Premium2026Tokens>() ?? Premium2026Tokens.dark;
}
