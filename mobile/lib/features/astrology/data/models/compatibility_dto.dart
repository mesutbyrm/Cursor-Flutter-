import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/zodiac_sign.dart';
import '../../domain/entities/compatibility_entity.dart';

part 'compatibility_dto.g.dart';

@JsonSerializable()
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

  factory CompatibilityScoreDTO.fromJson(Map<String, dynamic> json) =>
      _$CompatibilityScoreDTOFromJson(json);

  Map<String, dynamic> toJson() => _$CompatibilityScoreDTOToJson(this);

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

@JsonSerializable()
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

  factory DailyCompatibilityDTO.fromJson(Map<String, dynamic> json) =>
      _$DailyCompatibilityDTOFromJson(json);

  Map<String, dynamic> toJson() => _$DailyCompatibilityDTOToJson(this);

  DailyCompatibility toDomain() => DailyCompatibility(
    sign1: ZodiacSign.fromString(sign1) ?? ZodiacSign.aries,
    sign2: ZodiacSign.fromString(sign2) ?? ZodiacSign.taurus,
    date: DateTime.parse(date),
    dailyScore: dailyScore,
    daytip: daytip,
    bestHours: bestHours,
  );
}
