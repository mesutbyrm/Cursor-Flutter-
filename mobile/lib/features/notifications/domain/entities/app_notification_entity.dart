import 'package:equatable/equatable.dart';

class AppNotificationEntity extends Equatable {
  const AppNotificationEntity({
    required this.id,
    required this.title,
    this.body,
    this.read = false,
    this.createdAt,
    this.type,
    this.targetPath,
    this.targetId,
  });

  final String id;
  final String title;
  final String? body;
  final bool read;
  final DateTime? createdAt;
  final String? type;
  final String? targetPath;
  final String? targetId;

  @override
  List<Object?> get props =>
      [id, title, body, read, createdAt, type, targetPath, targetId];
}
