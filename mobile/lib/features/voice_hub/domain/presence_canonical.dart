import 'entities/chat_room_presence.dart';

/// Tam liste replace kaynakları — merge/append yok.
const kPresenceReplaceSources = {
  'sse',
  'state_snapshot',
  'join',
  'sse_room_update',
  'socket_snapshot',
  'resync',
  'sse_user_join',
};

bool isPresenceReplaceSource(String source) =>
    kPresenceReplaceSources.contains(source);

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
///
/// Boş sunucu listesi = odada kimse yok (hayalet tutma).
List<ChatRoomPresence> reconcilePresenceWithServer({
  required List<ChatRoomPresence> local,
  required List<ChatRoomPresence> server,
}) {
  return replacePresenceSnapshot(previous: local, incoming: server);
}

/// Canonical snapshot: CURRENT = incoming IDs only.
///
/// Önceki kayıttan yalnızca boş görünen ad/avatar/rol doldurulur.
/// [seatIndex] ve konuşma durumu incoming'den gelir — eski koltuk taşınmaz.
List<ChatRoomPresence> replacePresenceSnapshot({
  required List<ChatRoomPresence> previous,
  required List<ChatRoomPresence> incoming,
}) {
  final server = dedupePresencesById(incoming);
  if (previous.isEmpty || server.isEmpty) return server;
  final prevById = <String, ChatRoomPresence>{
    for (final p in previous) canonicalPresenceId(p): p,
  };
  return [
    for (final p in server)
      enrichPresenceDisplayFromPrevious(p, prevById[canonicalPresenceId(p)]),
  ];
}

/// Aynı kullanıcı için görünen alanları zenginleştir; koltuk/mic server kazanır.
ChatRoomPresence enrichPresenceDisplayFromPrevious(
  ChatRoomPresence incoming,
  ChatRoomPresence? previous,
) {
  if (previous == null) return incoming;
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
    seatIndex: incoming.seatIndex,
    isSpeaking: incoming.isSpeaking,
    isMuted: incoming.isMuted,
    micOn: incoming.micOn ?? previous.micOn,
  );
}

/// Etkin online sayısı — backend count öncelikli, yoksa canonical üye sayısı.
int resolveRoomOnlineCount({
  int? backendCount,
  required int participantCount,
}) {
  if (backendCount != null && backendCount >= 0) return backendCount;
  return participantCount;
}

/// GET /seats boş dizi genelde hata/yarış; dolu dizi (hepsi boş koltuk dahil) canonical.
bool shouldApplyCanonicalSeats(Iterable<Object?> incoming) =>
    incoming.isNotEmpty;
