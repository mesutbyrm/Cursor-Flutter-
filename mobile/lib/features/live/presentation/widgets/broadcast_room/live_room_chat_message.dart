/// Canlı yayın sohbet satırı.
class LiveRoomChatMessage {
  const LiveRoomChatMessage({
    this.id,
    this.userId,
    required this.user,
    required this.text,
    this.isSystem = false,
  });

  final String? id;
  final String? userId;
  final String user;
  final String text;
  final bool isSystem;
}
