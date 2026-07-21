import 'chat_room_message.dart';

class ChatRoomPresence extends ChatRoomUserRef {
  const ChatRoomPresence({
    required super.id,
    required super.name,
    super.nickname,
    super.image,
    super.chatRole,
    super.roleSymbol,
    super.membership,
    this.seatIndex,
    this.isSpeaking = false,
    this.isMuted = false,
    this.micOn,
  });

  factory ChatRoomPresence.fromJson(Map<String, dynamic> json) {
    final base = ChatRoomUserRef.fromJson(json);
    return ChatRoomPresence(
      id: base.id,
      name: base.name,
      nickname: base.nickname,
      image: base.image,
      chatRole: base.chatRole,
      roleSymbol: base.roleSymbol,
      membership: base.membership,
      seatIndex: _parseSeatIndex(
        json['seatIndex'] ??
            json['seat'] ??
            json['seat_index'] ??
            json['seatNumber'] ??
            json['seat_number'],
      ),
      isSpeaking: json['isSpeaking'] == true,
      isMuted: json['isMuted'] == true,
      micOn: _parseMicOn(json),
    );
  }

  static bool? _parseMicOn(Map<String, dynamic> json) {
    final raw = json['micOn'] ?? json['isMicOn'] ?? json['mic_on'];
    if (raw == null) return null;
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    final s = raw.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }

  final int? seatIndex;
  final bool isSpeaking;
  final bool isMuted;
  /// Backend `micOn` — tek kaynak.
  final bool? micOn;

  /// Mikrofon açık — backend `micOn` öncelikli.
  bool get micOpen {
    if (micOn != null) return micOn!;
    return seatIndex != null && !isMuted;
  }

  static int? _parseSeatIndex(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }
}
