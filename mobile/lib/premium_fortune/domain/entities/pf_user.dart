import 'package:equatable/equatable.dart';

class PfUser extends Equatable {
  const PfUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.birthDate,
    this.zodiacSign,
    this.credits = 0,
    this.points = 0,
    this.badges = const [],
    this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime? birthDate;
  final String? zodiacSign;
  final int credits;
  final int points;
  final List<String> badges;
  final DateTime? createdAt;

  PfUser copyWith({
    String? displayName,
    String? photoUrl,
    DateTime? birthDate,
    String? zodiacSign,
    int? credits,
    int? points,
    List<String>? badges,
  }) {
    return PfUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      birthDate: birthDate ?? this.birthDate,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      credits: credits ?? this.credits,
      points: points ?? this.points,
      badges: badges ?? this.badges,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        birthDate,
        zodiacSign,
        credits,
        points,
        badges,
        createdAt,
      ];
}
