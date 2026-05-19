import 'package:equatable/equatable.dart';

class AppNotificationEntity extends Equatable {
  const AppNotificationEntity({
    required this.id,
    required this.title,
    this.body,
    this.read = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String? body;
  final bool read;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, title, body, read, createdAt];
}
