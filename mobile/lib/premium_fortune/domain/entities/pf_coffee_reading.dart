import 'package:equatable/equatable.dart';

class PfCoffeeReading extends Equatable {
  const PfCoffeeReading({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.love,
    required this.money,
    required this.career,
    required this.health,
    required this.summary,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String imageUrl;
  final String love;
  final String money;
  final String career;
  final String health;
  final String summary;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        userId,
        imageUrl,
        love,
        money,
        career,
        health,
        summary,
        createdAt,
      ];
}
