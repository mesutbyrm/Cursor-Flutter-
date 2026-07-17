import '../../domain/entities/chat_room_presence.dart';

/// PK daveti için rakip oda sahibi kullanıcı kimliği.
String? resolvePkGuestUserId({
  String? ownerId,
  List<ChatRoomPresence> presence = const [],
}) {
  final fromMeta = ownerId?.trim() ?? '';
  if (fromMeta.isNotEmpty) return fromMeta;
  if (presence.isEmpty) return null;

  for (final p in presence) {
    final role = p.chatRole?.toLowerCase() ?? '';
    if (role == 'owner' || role == 'founder' || role == 'broadcaster') {
      if (p.id.isNotEmpty) return p.id;
    }
  }

  for (final p in presence) {
    if (p.seatIndex == 1 && p.id.isNotEmpty) return p.id;
  }
  for (final p in presence) {
    if (p.seatIndex == 0 && p.id.isNotEmpty) return p.id;
  }

  final first = presence.firstWhere(
    (p) => p.id.isNotEmpty,
    orElse: () => presence.first,
  );
  return first.id.isNotEmpty ? first.id : null;
}
