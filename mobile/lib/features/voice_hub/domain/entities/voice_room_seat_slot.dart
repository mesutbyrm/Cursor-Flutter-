import 'package:equatable/equatable.dart';

/// Tek koltuk — `GET /api/chat/rooms/{roomId}/seats` (backend otoriter).
class VoiceRoomSeatSlot extends Equatable {
  const VoiceRoomSeatSlot({
    required this.index,
    this.userId,
    this.name,
    this.image,
    this.micOn,
  });

  final int index;
  final String? userId;
  final String? name;
  final String? image;
  final bool? micOn;

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
      );
    }
    return VoiceRoomSeatSlot(
      index: idx,
      userId: map['userId']?.toString() ?? map['id']?.toString(),
      name: map['name']?.toString() ?? map['displayName']?.toString(),
      image: map['image']?.toString() ?? map['avatarUrl']?.toString(),
      micOn: _bool(map['micOn'] ?? map['isMicOn']),
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
  List<Object?> get props => [index, userId, name, image, micOn];
}

/// 15 koltukluk harita — backend sırası korunur.
List<VoiceRoomSeatSlot> parseVoiceRoomSeatMap(dynamic raw) {
  if (raw is List) {
    final out = <VoiceRoomSeatSlot>[];
    for (var i = 0; i < raw.length; i++) {
      out.add(VoiceRoomSeatSlot.fromJson(raw[i], fallbackIndex: i));
    }
    while (out.length < 15) {
      out.add(VoiceRoomSeatSlot.empty(out.length));
    }
    return out.take(15).toList();
  }
  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    final seats = map['seats'] ?? map['items'] ?? map['slots'];
    if (seats is List) return parseVoiceRoomSeatMap(seats);
    final out = <VoiceRoomSeatSlot>[];
    for (var i = 0; i < 15; i++) {
      final entry = map['$i'] ?? map[i.toString()];
      out.add(VoiceRoomSeatSlot.fromJson(entry, fallbackIndex: i));
    }
    return out;
  }
  return List.generate(15, VoiceRoomSeatSlot.empty);
}
