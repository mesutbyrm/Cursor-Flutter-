import '../../../trtc/domain/entities/trtc_credentials.dart';
import 'chat_room_my_permissions.dart';
import 'chat_room_presence.dart';
import 'voice_room_seat_slot.dart';

/// `GET /api/chat/rooms/{roomId}/state` — tek kaynaklı oda anlık görüntüsü.
class VoiceRoomStateSnapshot {
  const VoiceRoomStateSnapshot({
    required this.roomId,
    this.ownerId,
    this.participants = const [],
    this.seats = const [],
    this.trtc,
    this.me,
    this.onlineCount,
    this.seatCount,
    this.maxUsers,
    this.rulesTr,
  });

  final String roomId;
  final String? ownerId;
  final List<ChatRoomPresence> participants;
  final List<VoiceRoomSeatSlot> seats;
  final TrtcCredentials? trtc;
  final ChatRoomMyPermissions? me;
  final int? onlineCount;
  final int? seatCount;
  final int? maxUsers;
  final String? rulesTr;

  factory VoiceRoomStateSnapshot.fromJson(
    Map<String, dynamic> json, {
    required String roomId,
  }) {
    final room = json['room'] is Map
        ? Map<String, dynamic>.from(json['room'] as Map)
        : json;
    final owner = room['ownerId']?.toString() ??
        room['owner']?.toString() ??
        json['ownerId']?.toString();

    final participantsRaw = json['participants'] ??
        json['presence'] ??
        json['users'] ??
        room['participants'];
    final participants = _parseParticipants(participantsRaw);

    final trtcRaw = json['trtc'] ?? json['trtcCredentials'] ?? json;
    TrtcCredentials? trtc;
    if (trtcRaw is Map) {
      trtc = TrtcCredentials.fromJson(
        Map<String, dynamic>.from(trtcRaw),
        requestedRoomId: roomId,
      );
      if (!trtc.isValid) trtc = null;
    }

    ChatRoomMyPermissions? me;
    final meRaw = json['me'] ?? json['myPermissions'];
    if (meRaw is Map) {
      me = ChatRoomMyPermissions.fromJson(Map<String, dynamic>.from(meRaw));
    }

    final online = _int(json['onlineCount'] ?? room['onlineCount']);
    final seatCount = _int(room['seatCount'] ?? json['seatCount']);
    final maxUsers = _int(room['maxUsers'] ?? json['maxUsers']);
    final rulesTr = room['rulesTr']?.toString() ??
        room['rules']?.toString() ??
        room['roomRules']?.toString() ??
        json['rulesTr']?.toString() ??
        json['rules']?.toString();

    final seatsRaw = json['seats'] ?? json['seatMap'] ?? room['seats'];
    final seats = parseVoiceRoomSeatMap(seatsRaw, targetCount: seatCount);

    return VoiceRoomStateSnapshot(
      roomId: roomId,
      ownerId: owner,
      participants: participants,
      seats: seats,
      trtc: trtc,
      me: me,
      onlineCount: online,
      seatCount: seatCount,
      maxUsers: maxUsers,
      rulesTr: rulesTr?.trim().isNotEmpty == true ? rulesTr!.trim() : null,
    );
  }

  static List<ChatRoomPresence> _parseParticipants(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ChatRoomPresence.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.id.isNotEmpty)
        .toList();
  }

  static int? _int(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
