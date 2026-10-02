import '../presentation/widgets/broadcast_room/live_room_chat_message.dart';

final _giftLine = RegExp(
  r"^(.+?), (.+?)'ye (\d+) (.+?) değerinde (.+?) gönderdi\.$",
);

/// Ardışık, aynı gönderen → aynı alıcı → aynı hediye sistem mesajlarını tek
/// satırda birleştirir: «🎁 Mert → Ayşe · Aslan x3 (1500 Jeton)».
/// Normal mesajlar ve farklı hediyeler olduğu gibi kalır.
List<LiveRoomChatMessage> mergeGiftChatMessages(
  List<LiveRoomChatMessage> messages,
) {
  final out = <LiveRoomChatMessage>[];
  String? key;
  var count = 0;
  var jeton = 0;
  String? sender, receiver, gift, label;
  LiveRoomChatMessage? first;

  void flush() {
    if (first == null) return;
    out.add(
      count <= 1
          ? first!
          : LiveRoomChatMessage(
              id: first!.id,
              userId: first!.userId,
              user: first!.user,
              isSystem: true,
              text: '🎁 $sender → $receiver · $gift x$count ($jeton $label)',
            ),
    );
    first = null;
    key = null;
    count = 0;
    jeton = 0;
  }

  for (final m in messages) {
    final match = m.isSystem ? _giftLine.firstMatch(m.text) : null;
    if (match == null) {
      flush();
      out.add(m);
      continue;
    }
    final k = '${match[1]}|${match[2]}|${match[5]}';
    if (k != key) {
      flush();
      key = k;
      first = m;
      sender = match[1];
      receiver = match[2];
      gift = match[5];
      label = match[4];
    }
    count++;
    jeton += int.tryParse(match[3] ?? '') ?? 0;
  }
  flush();
  return out;
}
