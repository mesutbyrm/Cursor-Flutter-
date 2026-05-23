import 'package:equatable/equatable.dart';

class ChatRoomUserRef extends Equatable {
  const ChatRoomUserRef({
    required this.id,
    required this.name,
    this.nickname,
    this.image,
    this.chatRole,
    this.roleSymbol,
    this.membership,
  });

  factory ChatRoomUserRef.fromJson(Map<String, dynamic> json) {
    return ChatRoomUserRef(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['nickname']?.toString() ?? 'Kullanıcı',
      nickname: json['nickname']?.toString(),
      image: json['image']?.toString(),
      chatRole: json['chatRole']?.toString(),
      roleSymbol: json['roleSymbol']?.toString(),
      membership: json['membership']?.toString(),
    );
  }

  final String id;
  final String name;
  final String? nickname;
  final String? image;
  final String? chatRole;
  final String? roleSymbol;
  final String? membership;

  String get displayName => (nickname?.trim().isNotEmpty == true)
      ? nickname!.trim()
      : name;

  bool get isBroadcaster =>
      chatRole == 'superadmin' ||
      chatRole == 'admin' ||
      chatRole == 'owner' ||
      chatRole == 'broadcaster';

  @override
  List<Object?> get props =>
      [id, name, nickname, image, chatRole, roleSymbol, membership];
}

enum ChatMessageKind { text, systemJoin, systemLeave, gift, unknown }

class ChatRoomMessage extends Equatable {
  const ChatRoomMessage({
    required this.id,
    required this.content,
    required this.createdAt,
    this.user,
    this.kind = ChatMessageKind.text,
    this.giftEmoji,
    this.giftCount,
    this.giftTargetName,
  });

  factory ChatRoomMessage.fromJson(Map<String, dynamic> json) {
    final content = json['content']?.toString() ?? '';
    final userJson = json['user'];
    ChatRoomUserRef? user;
    if (userJson is Map) {
      user = ChatRoomUserRef.fromJson(Map<String, dynamic>.from(userJson));
    }

    var kind = ChatMessageKind.text;
    String? giftEmoji;
    int? giftCount;
    String? giftTarget;

    if (content.startsWith('[SYSTEM_VIP_JOIN:')) {
      kind = ChatMessageKind.systemJoin;
    } else if (content.startsWith('[SYSTEM_LEAVE]')) {
      kind = ChatMessageKind.systemLeave;
    } else if (content.contains('gönderdi') || content.contains('Gül')) {
      kind = ChatMessageKind.gift;
      giftEmoji = '🌹';
      final m = RegExp(r'x(\d+)').firstMatch(content);
      giftCount = m != null ? int.tryParse(m.group(1)!) : 1;
    }

    return ChatRoomMessage(
      id: json['id']?.toString() ?? '',
      content: _displayContent(content, kind),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      user: user,
      kind: kind,
      giftEmoji: giftEmoji,
      giftCount: giftCount,
      giftTargetName: giftTarget,
    );
  }

  static String _displayContent(String raw, ChatMessageKind kind) {
    if (kind == ChatMessageKind.systemJoin) {
      final name = raw.replaceFirst('[SYSTEM_VIP_JOIN:', '').replaceAll(']', '');
      final parts = name.split(':');
      final who = parts.length > 1 ? parts.last : name;
      return '$who Sohbet sesli odasına katıldı! 🎤';
    }
    if (kind == ChatMessageKind.systemLeave) {
      final who = raw.replaceFirst('[SYSTEM_LEAVE]', '');
      return '$who odadan ayrıldı';
    }
    return raw;
  }

  final String id;
  final String content;
  final DateTime createdAt;
  final ChatRoomUserRef? user;
  final ChatMessageKind kind;
  final String? giftEmoji;
  final int? giftCount;
  final String? giftTargetName;

  @override
  List<Object?> get props =>
      [id, content, createdAt, user, kind, giftEmoji, giftCount, giftTargetName];
}
