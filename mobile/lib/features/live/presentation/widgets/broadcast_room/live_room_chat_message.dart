/// Canlı yayın sohbet satırı.
class LiveRoomChatMessage {
  const LiveRoomChatMessage({
    this.id,
    this.userId,
    required this.user,
    required this.text,
    this.isSystem = false,
    this.isVip = false,
    this.isModerator = false,
    this.isFortuneTeller = false,
    this.level,
  });

  final String? id;
  final String? userId;
  final String user;
  final String text;
  final bool isSystem;
  final bool isVip;
  final bool isModerator;
  final bool isFortuneTeller;
  final int? level;
}
