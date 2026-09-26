import 'package:flutter/material.dart';

/// Canlifal marka paletinin ham değerleri — tek kaynak.
///
/// Koyu tema: derin siyah zemin, antrasit yüzeyler, kontrollü mor + turkuaz
/// vurgu. `AppThemeColors`, `HomeApprovedDesign`, `PlatformSocialPalette` gibi
/// sabit sınıflar bu değerleri kullanır; ekranlar yine `context.colors` okur.
abstract final class CanlifalBrandColors {
  // Koyu yüzeyler (derinden yükseğe).
  static const ink = Color(0xFF09090D);
  static const anthracite = Color(0xFF121218);
  static const anthraciteContainer = Color(0xFF16161D);
  static const anthraciteRaised = Color(0xFF1C1C24);
  static const hairline = Color(0xFF262630);
  static const hairlineSoft = Color(0xFF1E1E27);

  // Koyu metin.
  static const textPrimary = Color(0xFFF5F5FA);
  static const textSecondary = Color(0xFFB6B6C6);
  static const textMuted = Color(0xFF7E7E90);

  // Vurgular.
  static const violet = Color(0xFF8B5CF6);
  static const violetBright = Color(0xFFA78BFA);
  static const violetDeep = Color(0xFF6D28D9);

  /// Beyaz metin taşıyan dolgular (buton, FAB) — beyazla >= 4.5:1.
  static const violetStrong = Color(0xFF7C3AED);
  static const turquoise = Color(0xFF2DD4BF);
  static const turquoiseDeep = Color(0xFF0F766E);

  // Açık tema.
  static const paper = Color(0xFFF6F6FA);
  static const paperRaised = Color(0xFFFFFFFF);
  static const paperContainer = Color(0xFFEFEFF5);
  static const inkText = Color(0xFF111118);
  static const inkTextSecondary = Color(0xFF3F3F52);
  static const inkTextMuted = Color(0xFF6B6B80);

  /// Birincil eylem gradyanı (buton, aktif sekme).
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, violetStrong, violetDeep],
    stops: [0.0, 0.55, 1.0],
  );

  /// Mor → turkuaz vurgu gradyanı (öne çıkan kart kenarı, rozet).
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, turquoise],
  );

  /// İzlenmemiş hikâye halkası.
  static const storyRingGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFFFF4D7E), violet, turquoise],
    stops: [0.0, 0.6, 1.0],
  );
}
