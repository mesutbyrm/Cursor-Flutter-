import 'entities/chat_room_presence.dart';

/// Canonical participant kimliği — backend userId öncelikli.
String canonicalPresenceIdFromJson(Map<String, dynamic> json) {
  for (final key in const [
    'userId',
    'id',
    '_id',
    'uid',
    'realCid',
    'gcid',
    'sub',
  ]) {
    final v = json[key]?.toString().trim();
    if (v != null && v.isNotEmpty) return v;
  }
  return '';
}

String canonicalPresenceId(ChatRoomPresence presence) =>
    presence.id.trim();

/// Aynı kullanıcıyı tek kayıtta birleştir — server reconciliation için.
List<ChatRoomPresence> dedupePresencesById(List<ChatRoomPresence> list) {
  final byId = <String, ChatRoomPresence>{};
  for (final p in list) {
    final id = canonicalPresenceId(p);
    if (id.isEmpty) continue;
    final prev = byId[id];
    if (prev == null) {
      byId[id] = p;
      continue;
    }
    byId[id] = ChatRoomPresence(
      id: id,
      name: p.name.trim().isNotEmpty ? p.name : prev.name,
      nickname: (p.nickname?.trim().isNotEmpty == true)
          ? p.nickname
          : prev.nickname,
      image: (p.image?.trim().isNotEmpty == true) ? p.image : prev.image,
      chatRole: (p.chatRole?.trim().isNotEmpty == true)
          ? p.chatRole!
          : (prev.chatRole ?? 'listener'),
      roleSymbol: p.roleSymbol ?? prev.roleSymbol,
      membership: p.membership ?? prev.membership,
      seatIndex: p.seatIndex ?? prev.seatIndex,
      isSpeaking: p.isSpeaking,
      isMuted: p.isMuted && prev.isMuted,
      micOn: p.micOn ?? prev.micOn,
    );
  }
  return byId.values.toList();
}

/// Sunucu listesi canonical — local fazlalıkları düşür, eksikleri ekle.
List<ChatRoomPresence> reconcilePresenceWithServer({
  required List<ChatRoomPresence> local,
  required List<ChatRoomPresence> server,
}) {
  return dedupePresencesById(server);
}

/// Etkin online sayısı — backend count öncelikli.
int resolveRoomOnlineCount({
  int? backendCount,
  required int participantCount,
}) {
  if (backendCount != null && backendCount >= 0) return backendCount;
  return participantCount;
}
