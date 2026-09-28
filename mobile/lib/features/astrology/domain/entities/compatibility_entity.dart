import 'zodiac_sign.dart';

class CompatibilityScore {
  final ZodiacSign sign1;
  final ZodiacSign sign2;
  final int overallScore; // 0-100
  final int emotionalScore;
  final int intellectualScore;
  final int physicalScore;
  final String description;

  CompatibilityScore({
    required this.sign1,
    required this.sign2,
    required this.overallScore,
    required this.emotionalScore,
    required this.intellectualScore,
    required this.physicalScore,
    required this.description,
  });

  String getCompatibilityLevel() {
    if (overallScore >= 85) return 'Mükemmel';
    if (overallScore >= 70) return 'Çok İyi';
    if (overallScore >= 55) return 'İyi';
    if (overallScore >= 40) return 'Orta';
    return 'Zayıf';
  }
}

class DailyCompatibility {
  final ZodiacSign sign1;
  final ZodiacSign sign2;
  final DateTime date;
  final int dailyScore;
  final String daytip;
  final String bestHours;

  DailyCompatibility({
    required this.sign1,
    required this.sign2,
    required this.date,
    required this.dailyScore,
    required this.daytip,
    required this.bestHours,
  });
}
