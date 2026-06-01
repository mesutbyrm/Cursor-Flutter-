import 'package:equatable/equatable.dart';

class UserFortuneEntity extends Equatable {
  const UserFortuneEntity({
    required this.id,
    required this.type,
    this.question,
    this.answer,
    this.createdAt,
  });

  final String id;
  final String type;
  final String? question;
  final String? answer;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, type, question, answer, createdAt];
}
