/// Canlı yayın sohbet satırı.
class LiveRoomChatMessage {
  const LiveRoomChatMessage({
    required this.user,
    required this.text,
    this.isSystem = false,
  });

  final String user;
  final String text;
  final bool isSystem;
}
