import 'package:flutter/material.dart';

@immutable
class PremiumLiveStream {
  const PremiumLiveStream({
    required this.id,
    required this.streamerName,
    required this.categoryLabel,
    required this.viewers,
    required this.imageUrl,
    required this.avatarUrls,
    this.verified = true,
    this.extraAudienceCount = 0,
    this.heroBackdropColors = const [
      Color(0xFF2D1B69),
      Color(0xFF12081E),
      Color(0xFF0D0618),
    ],
  });

  final String id;
  final String streamerName;
  final String categoryLabel;
  final int viewers;
  final String imageUrl;
  final List<String> avatarUrls;
  final bool verified;
  /// Avatar yığınının yanında "+128" gibi gösterilen ek izleyici sayısı.
  final int extraAudienceCount;
  /// Ağ görseli yüklenemezse mockup’taki gibi dolu gradient zemin.
  final List<Color> heroBackdropColors;
}
