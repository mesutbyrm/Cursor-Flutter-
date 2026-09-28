import '../../domain/entities/zodiac_sign.dart';
import '../../domain/entities/compatibility_entity.dart';

class CompatibilityScoreDTO {
  final String sign1;
  final String sign2;
  final int overallScore;
  final int emotionalScore;
  final int intellectualScore;
  final int physicalScore;
  final String description;

  CompatibilityScoreDTO({
    required this.sign1,
    required this.sign2,
    required this.overallScore,
    required this.emotionalScore,
    required this.intellectualScore,
    required this.physicalScore,
    required this.description,
  });

  factory CompatibilityScoreDTO.fromJson(Map<String, dynamic> json) {
    return CompatibilityScoreDTO(
      sign1: json['sign1'] as String? ?? 'aries',
      sign2: json['sign2'] as String? ?? 'taurus',
      overallScore: json['overallScore'] as int? ?? 0,
      emotionalScore: json['emotionalScore'] as int? ?? 0,
      intellectualScore: json['intellectualScore'] as int? ?? 0,
      physicalScore: json['physicalScore'] as int? ?? 0,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'sign1': sign1,
    'sign2': sign2,
    'overallScore': overallScore,
    'emotionalScore': emotionalScore,
    'intellectualScore': intellectualScore,
    'physicalScore': physicalScore,
    'description': description,
  };

  CompatibilityScore toDomain() => CompatibilityScore(
    sign1: ZodiacSign.fromString(sign1) ?? ZodiacSign.aries,
    sign2: ZodiacSign.fromString(sign2) ?? ZodiacSign.taurus,
    overallScore: overallScore,
    emotionalScore: emotionalScore,
    intellectualScore: intellectualScore,
    physicalScore: physicalScore,
    description: description,
  );
}

class DailyCompatibilityDTO {
  final String sign1;
  final String sign2;
  final String date;
  final int dailyScore;
  final String daytip;
  final String bestHours;

  DailyCompatibilityDTO({
    required this.sign1,
    required this.sign2,
    required this.date,
    required this.dailyScore,
    required this.daytip,
    required this.bestHours,
  });

  factory DailyCompatibilityDTO.fromJson(Map<String, dynamic> json) {
    return DailyCompatibilityDTO(
      sign1: json['sign1'] as String? ?? 'aries',
      sign2: json['sign2'] as String? ?? 'taurus',
      date: json['date'] as String? ?? DateTime.now().toIso8601String(),
      dailyScore: json['dailyScore'] as int? ?? 0,
      daytip: json['daytip'] as String? ?? '',
      bestHours: json['bestHours'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'sign1': sign1,
    'sign2': sign2,
    'date': date,
    'dailyScore': dailyScore,
    'daytip': daytip,
    'bestHours': bestHours,
  };

  DailyCompatibility toDomain() => DailyCompatibility(
    sign1: ZodiacSign.fromString(sign1) ?? ZodiacSign.aries,
    sign2: ZodiacSign.fromString(sign2) ?? ZodiacSign.taurus,
    date: DateTime.parse(date),
    dailyScore: dailyScore,
    daytip: daytip,
    bestHours: bestHours,
  );
}
