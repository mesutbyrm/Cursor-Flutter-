import 'package:equatable/equatable.dart';

const int _kMinVoiceSeatMapSize = 8;
const int _kMaxVoiceSeatMapSize = 15;
const int _kDefaultVoiceSeatMapSize = 12;

int _seatMapTargetCount({int? targetCount, int? fromListLength}) {
  final len = fromListLength ?? 0;
  final configured = targetCount ?? _kDefaultVoiceSeatMapSize;
  final resolved = len > configured ? len : configured;
  return resolved.clamp(_kMinVoiceSeatMapSize, _kMaxVoiceSeatMapSize);
}

/// Tek koltuk — `GET /api/chat/rooms/{roomId}/seats` (backend otoriter).
class VoiceRoomSeatSlot extends Equatable {
  const VoiceRoomSeatSlot({
    required this.index,
    this.userId,
    this.name,
    this.image,
    this.micOn,
    this.isLocked = false,
  });

  final int index;
  final String? userId;
  final String? name;
  final String? image;
  final bool? micOn;
  final bool isLocked;

  bool get isEmpty => userId == null || userId!.isEmpty;

  factory VoiceRoomSeatSlot.empty(int index) => VoiceRoomSeatSlot(index: index);

  factory VoiceRoomSeatSlot.fromJson(
    dynamic raw, {
    required int fallbackIndex,
  }) {
    if (raw == null) return VoiceRoomSeatSlot.empty(fallbackIndex);
    if (raw is! Map) return VoiceRoomSeatSlot.empty(fallbackIndex);
    final map = Map<String, dynamic>.from(raw);
    final idx = _int(map['index'] ?? map['seatIndex'] ?? fallbackIndex);
    final user = map['user'];
    if (user is Map) {
      final u = Map<String, dynamic>.from(user);
      return VoiceRoomSeatSlot(
        index: idx,
        userId: u['id']?.toString() ?? u['userId']?.toString(),
        name: u['name']?.toString() ?? u['displayName']?.toString(),
        image: u['image']?.toString() ?? u['avatarUrl']?.toString(),
        micOn: _bool(u['micOn'] ?? u['isMicOn']),
        isLocked: _bool(map['isLocked'] ?? map['locked']) ?? false,
      );
    }
    return VoiceRoomSeatSlot(
      index: idx,
      userId: map['userId']?.toString() ?? map['id']?.toString(),
      name: map['name']?.toString() ?? map['displayName']?.toString(),
      image: map['image']?.toString() ?? map['avatarUrl']?.toString(),
      micOn: _bool(map['micOn'] ?? map['isMicOn']),
      isLocked: _bool(map['isLocked'] ?? map['locked']) ?? false,
    );
  }

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static bool? _bool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }

  @override
  List<Object?> get props => [index, userId, name, image, micOn, isLocked];
}

/// Koltuk haritası — backend sırası korunur; `targetCount` = oda `seatCount`.
List<VoiceRoomSeatSlot> parseVoiceRoomSeatMap(
  dynamic raw, {
  int? targetCount,
}) {
  final resolvedTarget = _seatMapTargetCount(
    targetCount: targetCount,
    fromListLength: raw is List ? raw.length : null,
  );
  if (raw is List) {
    final out = <VoiceRoomSeatSlot>[];
    for (var i = 0; i < raw.length; i++) {
      out.add(VoiceRoomSeatSlot.fromJson(raw[i], fallbackIndex: i));
    }
    while (out.length < resolvedTarget) {
      out.add(VoiceRoomSeatSlot.empty(out.length));
    }
    return out.take(_kMaxVoiceSeatMapSize).toList();
  }
  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    final seats = map['seats'] ?? map['items'] ?? map['slots'];
    if (seats is List) {
      return parseVoiceRoomSeatMap(seats, targetCount: targetCount);
    }
    final out = <VoiceRoomSeatSlot>[];
    for (var i = 0; i < resolvedTarget; i++) {
      final entry = map['$i'] ?? map[i.toString()];
      out.add(VoiceRoomSeatSlot.fromJson(entry, fallbackIndex: i));
    }
    return out;
  }
  return List.generate(resolvedTarget, VoiceRoomSeatSlot.empty);
}
