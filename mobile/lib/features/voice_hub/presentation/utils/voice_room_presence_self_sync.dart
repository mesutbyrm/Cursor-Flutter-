import '../../domain/entities/chat_room_presence.dart';

/// Backend join onayı olmadan kendini presence listesine ekleme (sahte "odadayım").
bool shouldAugmentPresenceWithSelf({
  required bool backendJoinAcknowledged,
  required List<ChatRoomPresence> members,
  required String? selfId,
}) {
  if (!backendJoinAcknowledged) return false;
  if (selfId == null || selfId.trim().isEmpty) return false;
  return !members.any((p) => p.id == selfId);
}

List<ChatRoomPresence> augmentPresenceWithSelf({
  required bool backendJoinAcknowledged,
  required List<ChatRoomPresence> members,
  required ChatRoomPresence self,
}) {
  if (!shouldAugmentPresenceWithSelf(
    backendJoinAcknowledged: backendJoinAcknowledged,
    members: members,
    selfId: self.id,
  )) {
    return members;
  }
  return [...members, self];
}
