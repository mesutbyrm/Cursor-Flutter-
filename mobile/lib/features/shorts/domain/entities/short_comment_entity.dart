import 'package:equatable/equatable.dart';

import 'short_video_entity.dart';

class ShortCommentEntity extends Equatable {
  const ShortCommentEntity({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.author,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final ShortVideoAuthor author;

  @override
  List<Object?> get props => [id, content, createdAt, author];
}
