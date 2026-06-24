import '../../domain/entities/fortune_reading_section.dart';
import '../../domain/entities/fortune_type_entity.dart';

/// Fal sonucu enerji skorları (0–100).
class FortuneEnergyScores {
  const FortuneEnergyScores({
    required this.energy,
    required this.love,
    required this.money,
    required this.career,
    required this.luck,
  });

  final int energy;
  final int love;
  final int money;
  final int career;
  final int luck;

  factory FortuneEnergyScores.fromResult(FortuneReadingResult result) {
    final seed = (result.summary.hashCode ^ result.type.slug.hashCode).abs();
    int base(int offset) => 52 + ((seed + offset * 17) % 38);

    var love = base(1);
    var money = base(2);
    var career = base(3);
    var luck = base(4);
    var energy = base(0);

    for (final s in result.sections) {
      final boost = _sectionBoost(s);
      switch (s.key) {
        case FortuneSectionKeys.love:
          love = (love + boost).clamp(0, 100);
        case FortuneSectionKeys.money:
          money = (money + boost).clamp(0, 100);
        case FortuneSectionKeys.career:
          career = (career + boost).clamp(0, 100);
        case FortuneSectionKeys.advice:
          luck = (luck + boost ~/ 2).clamp(0, 100);
        case FortuneSectionKeys.general:
          energy = (energy + boost ~/ 2).clamp(0, 100);
      }
    }

    switch (result.type.slug) {
      case 'ask-fali':
      case 'katina':
        love = (love + 12).clamp(0, 100);
      case 'numeroloji':
      case 'yildiz-haritasi':
        luck = (luck + 10).clamp(0, 100);
      case 'kahve-fali':
        energy = (energy + 8).clamp(0, 100);
    }

    return FortuneEnergyScores(
      energy: energy,
      love: love,
      money: money,
      career: career,
      luck: luck,
    );
  }

  static int _sectionBoost(FortuneReadingSection section) {
    final len = section.body.length;
    if (len > 400) return 14;
    if (len > 200) return 10;
    return 6;
  }
}
