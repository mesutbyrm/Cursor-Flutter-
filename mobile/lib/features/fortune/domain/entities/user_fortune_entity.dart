import 'package:equatable/equatable.dart';

class UserFortuneEntity extends Equatable {
  const UserFortuneEntity({
    required this.id,
    required this.type,
    this.slug,
    this.question,
    this.answer,
    this.summary,
    this.detail,
    this.luckyNumber,
    this.luckyColor,
    this.createdAt,
  });

  final String id;
  final String type;
  final String? slug;
  final String? question;
  final String? answer;
  final String? summary;
  final String? detail;
  final int? luckyNumber;
  final String? luckyColor;
  final DateTime? createdAt;

  String get displayTitle =>
      type.isNotEmpty ? type : (slug ?? 'Fal');

  String get displayBody =>
      answer ?? summary ?? detail ?? question ?? '';

  @override
  List<Object?> get props =>
      [id, type, slug, question, answer, summary, detail, luckyNumber, luckyColor, createdAt];
}
