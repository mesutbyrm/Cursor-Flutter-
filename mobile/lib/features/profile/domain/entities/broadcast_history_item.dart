import 'package:equatable/equatable.dart';

/// `GET /api/user/broadcast-history` satırı.
class BroadcastHistoryItem extends Equatable {
  const BroadcastHistoryItem({
    required this.id,
    required this.title,
    this.status,
    this.thumbnailUrl,
    this.startedAt,
    this.endedAt,
    this.viewerCount,
  });

  final String id;
  final String title;
  final String? status;
  final String? thumbnailUrl;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? viewerCount;

  @override
  List<Object?> get props =>
      [id, title, status, thumbnailUrl, startedAt, endedAt, viewerCount];
}
