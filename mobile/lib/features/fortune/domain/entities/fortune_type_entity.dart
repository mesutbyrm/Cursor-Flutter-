import 'package:flutter/material.dart';

/// Fal oturumu etkileşim türü.
enum FortuneSessionKind {
  tarotCards,
  loveHeart,
  coffeeCup,
  zodiacWheel,
  palmScan,
  numberInput,
  dreamText,
  yesNo,
  pendulum,
  runeStone,
  playingCards,
  angelCards,
  chineseCoins,
  generic,
}

class FortuneTypeEntity {
  const FortuneTypeEntity({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.emoji,
    required this.accent,
    required this.kind,
    required this.ctaLabel,
    this.isDaily = false,
    this.isPremium = false,
  });

  final String id;
  final String slug;
  final String title;
  final String description;
  final String emoji;
  final Color accent;
  final FortuneSessionKind kind;
  final String ctaLabel;
  final bool isDaily;
  final bool isPremium;
}

class FortuneReadingResult {
  const FortuneReadingResult({
    required this.type,
    required this.summary,
    required this.detail,
    this.luckyNumber,
    this.luckyColor,
    this.recordId,
  });

  final FortuneTypeEntity type;
  final String summary;
  final String detail;
  final int? luckyNumber;
  final String? luckyColor;

  /// Sunucuya kaydedilen fal kaydı (`POST /api/user/fortunes`).
  final String? recordId;
}
