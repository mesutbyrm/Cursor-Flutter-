import 'entities/chat_room_presence.dart';

/// Bekleyen koltuk işlemi — presence snapshot yarışını yumuşatır.
enum VoiceSeatPendingKind { take, leave }

class VoiceSeatPendingAction {
  const VoiceSeatPendingAction({
    required this.userId,
    required this.kind,
    this.seatIndex,
    required this.expiresAt,
  });

  final String userId;
  final VoiceSeatPendingKind kind;
  final int? seatIndex;
  final DateTime expiresAt;

  bool get active => DateTime.now().isBefore(expiresAt);
}

/// Snapshot uygulanırken yalnızca pending kullanıcılar için eski koltuk korunur.
List<ChatRoomPresence> guardPresenceAgainstPendingSeatActions({
  required List<ChatRoomPresence> merged,
  required List<ChatRoomPresence> previous,
  required Map<String, VoiceSeatPendingAction> pendingByUser,
}) {
  if (pendingByUser.isEmpty) return merged;
  final activePending = <String, VoiceSeatPendingAction>{};
  for (final e in pendingByUser.entries) {
    if (e.value.active) activePending[e.key] = e.value;
  }
  if (activePending.isEmpty) return merged;

  final prevById = <String, ChatRoomPresence>{
    for (final p in previous) p.id.trim(): p,
  };

  return [
    for (final incoming in merged)
      _guardRow(
        incoming: incoming,
        previous: prevById[incoming.id.trim()],
        pending: activePending[incoming.id.trim()],
      ),
  ];
}

ChatRoomPresence _guardRow({
  required ChatRoomPresence incoming,
  required ChatRoomPresence? previous,
  required VoiceSeatPendingAction? pending,
}) {
  if (pending == null) return incoming;

  switch (pending.kind) {
    case VoiceSeatPendingKind.take:
      final expected = pending.seatIndex;
      if (expected == null || expected < 1) return incoming;
      if (incoming.seatIndex == expected) return incoming;
      if (previous != null && previous.seatIndex == expected) {
        return ChatRoomPresence(
          id: incoming.id,
          name: incoming.name.trim().isNotEmpty ? incoming.name : previous.name,
          nickname: (incoming.nickname?.trim().isNotEmpty == true)
              ? incoming.nickname
              : previous.nickname,
          image: (incoming.image?.trim().isNotEmpty == true)
              ? incoming.image
              : previous.image,
          chatRole: (incoming.chatRole?.trim().isNotEmpty == true)
              ? incoming.chatRole!
              : (previous.chatRole ?? 'listener'),
          roleSymbol: incoming.roleSymbol ?? previous.roleSymbol,
          membership: incoming.membership ?? previous.membership,
          seatIndex: expected,
          isSpeaking: incoming.isSpeaking,
          isMuted: incoming.isMuted,
          micOn: incoming.micOn ?? previous.micOn,
        );
      }
      return incoming;
    case VoiceSeatPendingKind.leave:
      if (incoming.seatIndex == null) return incoming;
      return ChatRoomPresence(
        id: incoming.id,
        name: incoming.name,
        nickname: incoming.nickname,
        image: incoming.image,
        chatRole: incoming.chatRole,
        roleSymbol: incoming.roleSymbol,
        membership: incoming.membership,
        seatIndex: null,
        isSpeaking: false,
        isMuted: incoming.isMuted,
        micOn: incoming.micOn,
      );
  }
}
