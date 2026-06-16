import 'package:equatable/equatable.dart';

enum PfTarotMode { daily, weekly, custom }

class PfTarotCard extends Equatable {
  const PfTarotCard({
    required this.id,
    required this.name,
    required this.meaning,
    this.imageAsset,
    this.isReversed = false,
  });

  final String id;
  final String name;
  final String meaning;
  final String? imageAsset;
  final bool isReversed;

  @override
  List<Object?> get props => [id, name, meaning, imageAsset, isReversed];
}

class PfTarotReading extends Equatable {
  const PfTarotReading({
    required this.id,
    required this.userId,
    required this.mode,
    required this.cards,
    required this.interpretation,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final PfTarotMode mode;
  final List<PfTarotCard> cards;
  final String interpretation;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, userId, mode, cards, interpretation, createdAt];
}
