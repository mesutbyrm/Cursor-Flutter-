import 'package:equatable/equatable.dart';

import '../../../../core/auth/voice_staff_rank.dart';
import '../voice_official_join.dart';

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
      id: json['id']?.toString() ??
          json['userId']?.toString() ??
          json['_id']?.toString() ??
          '',
      name: json['name']?.toString() ??
          json['displayName']?.toString() ??
          json['nickname']?.toString() ??
          json['username']?.toString() ??
          'Kullanıcı',
      nickname: json['nickname']?.toString() ?? json['username']?.toString(),
      image: json['image']?.toString() ??
          json['avatar']?.toString() ??
          json['avatarUrl']?.toString() ??
          json['profileImage']?.toString(),
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

  /// Görünen ad — kullanıcı adı değil, site `displayName` / `name` öncelikli.
  String get displayName {
    final n = name.trim();
    if (n.isNotEmpty && n.toLowerCase() != (nickname?.trim().toLowerCase() ?? '')) {
      return n;
    }
    return nickname?.trim().isNotEmpty == true ? nickname!.trim() : name;
  }

  bool get isBroadcaster =>
      chatRole == 'superadmin' ||
      chatRole == 'founder' ||
      chatRole == 'sop' ||
      chatRole == 'op' ||
      chatRole == 'admin' ||
      chatRole == 'owner' ||
      chatRole == 'broadcaster';

  VoiceStaffRank get staffRank => VoiceStaffRankParser.resolve(
        username: nickname ?? name,
        chatRole: chatRole,
      );

  String get displayWithPrefix {
    final sym = roleSymbol ?? VoiceStaffRankParser.prefixSymbol(staffRank);
    final n = displayName;
    if (sym != null && sym.isNotEmpty && !n.startsWith(sym)) {
      return '$sym$n';
    }
    return n;
  }

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
    this.giftJeton,
    this.giftTargetName,
  });

  factory ChatRoomMessage.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content']?.toString() ??
        json['body']?.toString() ??
        json['message']?.toString() ??
        json['text']?.toString() ??
        '';
    final content = rawContent.trim();
    final userJson = json['user'] ?? json['sender'];
    ChatRoomUserRef? user;
    if (userJson is Map) {
      final um = Map<String, dynamic>.from(userJson);
      if (um['name'] == null && um['displayName'] != null) {
        um['name'] = um['displayName'];
      }
      user = ChatRoomUserRef.fromJson(um);
    }

    var kind = ChatMessageKind.text;
    String? giftEmoji;
    int? giftCount;
    int? giftJeton;
    String? giftTarget;

    if (isSystemProtocol(content) ||
        content.startsWith('[SYSTEM_VIP_JOIN:') ||
        VoiceOfficialJoin.isOfficialEntrance(content)) {
      kind = ChatMessageKind.systemJoin;
    } else if (content.startsWith('[SYSTEM_BAN]')) {
      kind = ChatMessageKind.systemLeave;
    } else if (content.startsWith('[SYSTEM_LEAVE]')) {
      kind = ChatMessageKind.systemLeave;
    } else if (_looksLikeGiftMessage(content)) {
      kind = ChatMessageKind.gift;
      giftEmoji = '🌹';
      final m = RegExp(r'x(\d+)').firstMatch(content);
      giftCount = m != null ? int.tryParse(m.group(1)!) : 1;
      final jm = RegExp(r'(\d+)\s*jeton', caseSensitive: false).firstMatch(content);
      giftJeton = jm != null ? int.tryParse(jm.group(1)!) : null;
    }

    final id = json['id']?.toString() ??
        '${json['createdAt'] ?? json['sentAt']}_${content.hashCode}';

    return ChatRoomMessage(
      id: id,
      content: _displayContent(content, kind),
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ??
                json['sentAt']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      user: user,
      kind: kind,
      giftEmoji: giftEmoji,
      giftCount: giftCount,
      giftJeton: giftJeton,
      giftTargetName: giftTarget,
    );
  }

  static bool _looksLikeGiftMessage(String content) {
    final lower = content.toLowerCase();
    if (!lower.contains('gönderdi') && !lower.contains('hediye')) return false;
    return RegExp(r'[🌹🎁💎✨🎉]|x\d+', caseSensitive: false).hasMatch(content);
  }

  static bool isSystemProtocol(String raw) {
    final c = raw.trim();
    if (c.isEmpty) return false;
    return c.startsWith('[SYSTEM_') ||
        c.contains('[SYSTEM_VIP_JOIN') ||
        c.contains('[SYSTEM_LEAVE]');
  }

  /// Ham protokol satırını kullanıcı dostu metne çevirir.
  static String formatDisplay(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('[SYSTEM_VIP_JOIN:')) {
      return _formatVipJoin(trimmed);
    }
    if (trimmed.startsWith('[SYSTEM_LEAVE]')) {
      final who = trimmed.replaceFirst('[SYSTEM_LEAVE]', '').trim();
      final name = _cleanName(who);
      return name.isNotEmpty ? '$name odadan ayrıldı' : 'Bir kullanıcı odadan ayrıldı';
    }
    if (trimmed.startsWith('[SYSTEM_BAN]')) {
      return 'Bir kullanıcı odadan uzaklaştırıldı';
    }
    return trimmed;
  }

  static String _formatVipJoin(String raw) {
    var inner = raw.replaceFirst('[SYSTEM_VIP_JOIN:', '').trim();
    if (inner.endsWith(']')) {
      inner = inner.substring(0, inner.length - 1);
    }
    // ADMIN]%Admin · ADMIN:Ali · ADMIN]Ali
    final match = RegExp(r'^([A-Za-z_]+)([\]%:])(.*)$').firstMatch(inner);
    if (match != null) {
      final who = _cleanName(match.group(3) ?? '');
      if (who.isNotEmpty) return '$who odaya katıldı';
    }
    final parts = inner.split(':');
    if (parts.length > 1) {
      final who = _cleanName(parts.sublist(1).join(':'));
      if (who.isNotEmpty) return '$who odaya katıldı';
    }
    final fallback = _cleanName(inner);
    if (fallback.isNotEmpty) return '$fallback odaya katıldı';
    return 'Bir kullanıcı odaya katıldı';
  }

  static String _cleanName(String raw) {
    return raw
        .replaceAll(']', '')
        .replaceFirst(RegExp(r'^[%@~&]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _displayContent(String raw, ChatMessageKind kind) {
    if (kind == ChatMessageKind.systemJoin) {
      if (isSystemProtocol(raw) || raw.startsWith('[SYSTEM_VIP_JOIN:')) {
        return formatDisplay(raw);
      }
      if (!raw.contains('katıldı') && !raw.toUpperCase().contains('JOINED')) {
        return '${_cleanName(raw)} odaya katıldı';
      }
      return raw;
    }
    if (kind == ChatMessageKind.systemLeave) {
      if (raw.startsWith('[SYSTEM_LEAVE]')) {
        return formatDisplay(raw);
      }
      final who = _cleanName(raw);
      return who.isNotEmpty ? '$who odadan ayrıldı' : raw;
    }
    if (isSystemProtocol(raw)) {
      return formatDisplay(raw);
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
  final int? giftJeton;
  final String? giftTargetName;

  @override
  List<Object?> get props => [
      id, content, createdAt, user, kind, giftEmoji, giftCount, giftJeton, giftTargetName];
}
