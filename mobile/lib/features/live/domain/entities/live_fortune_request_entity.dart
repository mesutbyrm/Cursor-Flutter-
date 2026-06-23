import 'package:equatable/equatable.dart';

import '../../../../core/util/json_util.dart';

/// Canlı yayın fal isteği öncelik seviyesi.
enum LiveFortunePriority {
  standard,
  priority,
  vip,
  superFal,
  urgent,
}

/// Fal isteği durumu — yayıncı paneli.
enum LiveFortuneRequestStatus {
  pending,
  held,
  reviewing,
  answered,
  cancelled,
}

extension LiveFortunePriorityX on LiveFortunePriority {
  int get jetonCost => switch (this) {
        LiveFortunePriority.standard => 500,
        LiveFortunePriority.priority => 1000,
        LiveFortunePriority.urgent => 1500,
        LiveFortunePriority.vip => 2500,
        LiveFortunePriority.superFal => 2500,
      };

  int get queueWeight => switch (this) {
        LiveFortunePriority.standard => 1,
        LiveFortunePriority.priority => 2,
        LiveFortunePriority.urgent => 3,
        LiveFortunePriority.vip => 4,
        LiveFortunePriority.superFal => 5,
      };

  String get label => switch (this) {
        LiveFortunePriority.standard => 'Standart',
        LiveFortunePriority.priority => 'Öncelikli',
        LiveFortunePriority.urgent => 'Acil',
        LiveFortunePriority.vip => 'VIP',
        LiveFortunePriority.superFal => 'Süper Fal',
      };

  static LiveFortunePriority fromWire(String? raw) {
    final v = raw?.trim().toLowerCase() ?? '';
    return switch (v) {
      'priority' || 'oncelikli' || 'öncelikli' => LiveFortunePriority.priority,
      'vip' => LiveFortunePriority.vip,
      'super' || 'super_fal' || 'superfal' => LiveFortunePriority.superFal,
      'urgent' || 'acil' => LiveFortunePriority.urgent,
      _ => LiveFortunePriority.standard,
    };
  }
}

extension LiveFortuneRequestStatusX on LiveFortuneRequestStatus {
  String get label => switch (this) {
        LiveFortuneRequestStatus.pending => 'Beklemede',
        LiveFortuneRequestStatus.held => 'Bekletildi',
        LiveFortuneRequestStatus.reviewing => 'İnceleniyor',
        LiveFortuneRequestStatus.answered => 'Yanıtlandı',
        LiveFortuneRequestStatus.cancelled => 'İptal',
      };

  static LiveFortuneRequestStatus fromWire(String? raw) {
    final v = raw?.trim().toLowerCase() ?? '';
    return switch (v) {
      'held' || 'hold' || 'beklet' || 'on_hold' => LiveFortuneRequestStatus.held,
      'reviewing' || 'inceleniyor' || 'in_progress' || 'accepted' =>
        LiveFortuneRequestStatus.reviewing,
      'answered' || 'completed' || 'yanitlandi' => LiveFortuneRequestStatus.answered,
      'cancelled' || 'canceled' || 'rejected' => LiveFortuneRequestStatus.cancelled,
      _ => LiveFortuneRequestStatus.pending,
    };
  }
}

/// Canlı yayın fal isteği — `displayName` yayıncıya görünür, `username` gizli.
class LiveFortuneRequestEntity extends Equatable {
  const LiveFortuneRequestEntity({
    required this.id,
    required this.streamId,
    required this.userId,
    required this.displayName,
    required this.question,
    required this.fortuneType,
    required this.priority,
    required this.status,
    required this.jetonCost,
    required this.createdAt,
    this.username,
  });

  final String id;
  final String streamId;
  final String userId;
  final String? username;
  final String displayName;
  final String question;
  final String fortuneType;
  final LiveFortunePriority priority;
  final LiveFortuneRequestStatus status;
  final int jetonCost;
  final DateTime createdAt;

  bool get isPremiumTier =>
      priority == LiveFortunePriority.vip ||
      priority == LiveFortunePriority.superFal ||
      priority == LiveFortunePriority.urgent;

  factory LiveFortuneRequestEntity.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt']?.toString() ??
        json['created_at']?.toString() ??
        DateTime.now().toIso8601String();
    return LiveFortuneRequestEntity(
      id: json['id']?.toString() ?? '',
      streamId: json['streamId']?.toString() ?? json['stream_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      username: json['username']?.toString(),
      displayName: json['displayName']?.toString() ??
          json['display_name']?.toString() ??
          'Misafir',
      question: json['question']?.toString() ??
          json['fortuneQuestion']?.toString() ??
          '',
      fortuneType: json['fortuneType']?.toString() ??
          json['type']?.toString() ??
          json['fortune_type']?.toString() ??
          'general',
      priority: LiveFortunePriorityX.fromWire(
        json['priority']?.toString() ?? json['priorityType']?.toString(),
      ),
      status: LiveFortuneRequestStatusX.fromWire(json['status']?.toString()),
      jetonCost: asInt(json['jetonCost'] ?? json['jeton_cost'] ?? json['cost']),
      createdAt: DateTime.tryParse(created) ?? DateTime.now(),
    );
  }

  LiveFortuneRequestEntity copyWith({
    LiveFortuneRequestStatus? status,
  }) {
    return LiveFortuneRequestEntity(
      id: id,
      streamId: streamId,
      userId: userId,
      username: username,
      displayName: displayName,
      question: question,
      fortuneType: fortuneType,
      priority: priority,
      status: status ?? this.status,
      jetonCost: jetonCost,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, streamId, status, priority, createdAt];
}

/// Kuyruk sıralaması: VIP > Öncelikli > Standart; aynı seviyede FIFO.
int compareFortuneRequestQueue(
  LiveFortuneRequestEntity a,
  LiveFortuneRequestEntity b,
) {
  final w = b.priority.queueWeight.compareTo(a.priority.queueWeight);
  if (w != 0) return w;
  return a.createdAt.compareTo(b.createdAt);
}

List<LiveFortuneRequestEntity> sortFortuneRequestQueue(
  Iterable<LiveFortuneRequestEntity> items,
) {
  final list = items.toList()
    ..sort(compareFortuneRequestQueue);
  return list;
}
