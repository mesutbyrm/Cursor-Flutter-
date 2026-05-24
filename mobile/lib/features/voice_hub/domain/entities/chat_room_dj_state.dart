import 'chat_room_message.dart';

class ChatRoomDjState {
  const ChatRoomDjState({
    this.djUsers = const [],
    this.activeDjId,
    this.ownerPresent = false,
    this.canPlayMusic = false,
    this.isOwner = false,
    this.musicUrl,
    this.playing = false,
  });

  factory ChatRoomDjState.fromJson(Map<String, dynamic> json) {
    final users = <ChatRoomUserRef>[];
    final raw = json['djUsers'];
    if (raw is List) {
      for (final u in raw) {
        if (u is Map) {
          users.add(ChatRoomUserRef.fromJson(Map<String, dynamic>.from(u)));
        }
      }
    }
    return ChatRoomDjState(
      djUsers: users,
      activeDjId: json['activeDjId']?.toString(),
      ownerPresent: json['ownerPresent'] == true,
      canPlayMusic: json['canPlayMusic'] == true,
      isOwner: json['isOwner'] == true,
      musicUrl: json['musicUrl']?.toString(),
      playing: json['playing'] == true,
    );
  }

  final List<ChatRoomUserRef> djUsers;
  final String? activeDjId;
  final bool ownerPresent;
  final bool canPlayMusic;
  final bool isOwner;
  final String? musicUrl;
  final bool playing;

  int get djCount => djUsers.length;
}
