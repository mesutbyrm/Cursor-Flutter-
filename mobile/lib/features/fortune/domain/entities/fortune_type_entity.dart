import 'package:flutter/material.dart';

import 'fortune_reading_section.dart';

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
    this.imageUrl,
    this.visualAnalysis,
    this.sections = const [],
  });

  final FortuneTypeEntity type;
  final String summary;
  final String detail;
  final int? luckyNumber;
  final String? luckyColor;

  /// Sunucuya kaydedilen fal kaydı (`POST /api/user/fortunes`).
  final String? recordId;

  /// Kapak / vitrin görseli URL.
  final String? imageUrl;

  /// Görselden çıkarılan sembolik analiz metni.
  final String? visualAnalysis;

  /// Yapılandırılmış bölümler (boşsa [detail] kullanılır).
  final List<FortuneReadingSection> sections;

  bool get hasStructuredSections => sections.length >= 3;

  String get fullText {
    if (sections.isEmpty) return detail;
    return sections.map((s) => '${s.title}\n${s.body}').join('\n\n');
  }

  FortuneReadingResult copyWith({
    FortuneTypeEntity? type,
    String? summary,
    String? detail,
    int? luckyNumber,
    String? luckyColor,
    String? recordId,
    String? imageUrl,
    String? visualAnalysis,
    List<FortuneReadingSection>? sections,
  }) {
    return FortuneReadingResult(
      type: type ?? this.type,
      summary: summary ?? this.summary,
      detail: detail ?? this.detail,
      luckyNumber: luckyNumber ?? this.luckyNumber,
      luckyColor: luckyColor ?? this.luckyColor,
      recordId: recordId ?? this.recordId,
      imageUrl: imageUrl ?? this.imageUrl,
      visualAnalysis: visualAnalysis ?? this.visualAnalysis,
      sections: sections ?? this.sections,
    );
  }
}
