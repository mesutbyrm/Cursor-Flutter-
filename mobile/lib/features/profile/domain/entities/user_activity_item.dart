import 'package:equatable/equatable.dart';

/// `GET /api/user/activity` satırı — site bildirim/aktivite akışı.
class UserActivityItem extends Equatable {
  const UserActivityItem({
    required this.id,
    required this.title,
    this.body,
    this.read = false,
    this.createdAt,
    this.type,
  });

  final String id;
  final String title;
  final String? body;
  final bool read;
  final DateTime? createdAt;
  final String? type;

  @override
  List<Object?> get props => [id, title, body, read, createdAt, type];
}
