import 'package:equatable/equatable.dart';

class PfDreamReading extends Equatable {
  const PfDreamReading({
    required this.id,
    required this.userId,
    required this.dreamText,
    required this.interpretation,
    required this.symbols,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String dreamText;
  final String interpretation;
  final List<String> symbols;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, userId, dreamText, interpretation, symbols, createdAt];
}
