import 'package:equatable/equatable.dart';

class LiveStreamChatMessage extends Equatable {
  const LiveStreamChatMessage({
    required this.id,
    required this.content,
    required this.createdAt,
    this.userId,
    this.userName,
    this.userImage,
    this.isSystem = false,
    this.isVip = false,
    this.isModerator = false,
    this.isFortuneTeller = false,
    this.level,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final String? userId;
  final String? userName;
  final String? userImage;
  final bool isSystem;
  final bool isVip;
  final bool isModerator;
  final bool isFortuneTeller;
  final int? level;

  static bool _flag(dynamic v) =>
      v == true || v == 1 || v == 'true' || v == '1';

  static int? _level(dynamic v) {
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '');
  }

  factory LiveStreamChatMessage.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    Map<String, dynamic>? um;
    if (user is Map) um = Map<String, dynamic>.from(user);
    final created = json['createdAt']?.toString();
    final isVip = _flag(json['isVip'] ?? json['vip'] ?? um?['isVip'] ?? um?['vip']);
    final isMod = _flag(
      json['isModerator'] ?? um?['isModerator'] ?? um?['isMod'] ?? um?['mod'],
    );
    final isFal = _flag(
      json['isFortuneTeller'] ??
          um?['isFortuneTeller'] ??
          um?['isPsychic'] ??
          um?['isFalci'],
    );
    final level = _level(json['level'] ?? um?['level'] ?? um?['userLevel']);
    return LiveStreamChatMessage(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: created != null
          ? DateTime.tryParse(created) ?? DateTime.now()
          : DateTime.now(),
      userId: um?['id']?.toString(),
      userName: um?['name']?.toString() ??
          um?['displayName']?.toString() ??
          um?['nickname']?.toString(),
      userImage: um?['image']?.toString() ?? um?['avatarUrl']?.toString(),
      isSystem: json['kind']?.toString() == 'system',
      isVip: isVip,
      isModerator: isMod,
      isFortuneTeller: isFal,
      level: level,
    );
  }

  String get displayName => userName?.trim().isNotEmpty == true
      ? userName!.trim()
      : (isSystem ? 'Sistem' : 'Misafir');

  @override
  List<Object?> get props => [
        id,
        content,
        createdAt,
        userId,
        userName,
        isSystem,
        isVip,
        isModerator,
        isFortuneTeller,
        level,
      ];
}
