import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/user_entity.dart';

class SocialCommentEntity extends Equatable {
  const SocialCommentEntity({
    required this.id,
    required this.author,
    required this.text,
    this.createdAt,
  });

  final String id;
  final UserEntity author;
  final String text;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, author, text, createdAt];
}
