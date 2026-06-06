/// Canlı yayın sohbet satırı.
class LiveRoomChatMessage {
  const LiveRoomChatMessage({
    this.id,
    required this.user,
    required this.text,
    this.isSystem = false,
  });

  final String? id;
  final String user;
  final String text;
  final bool isSystem;
}
