import 'package:equatable/equatable.dart';

class PfHoroscopeReading extends Equatable {
  const PfHoroscopeReading({
    required this.sign,
    required this.daily,
    required this.weekly,
    required this.updatedAt,
  });

  final String sign;
  final String daily;
  final String weekly;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [sign, daily, weekly, updatedAt];
}

class PfBirthChart extends Equatable {
  const PfBirthChart({
    required this.id,
    required this.userId,
    required this.sunSign,
    required this.moonSign,
    required this.risingSign,
    required this.interpretation,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String sunSign;
  final String moonSign;
  final String risingSign;
  final String interpretation;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        userId,
        sunSign,
        moonSign,
        risingSign,
        interpretation,
        createdAt,
      ];
}
