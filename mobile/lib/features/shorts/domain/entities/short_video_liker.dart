import 'package:equatable/equatable.dart';

/// Videoyu beğenen kullanıcı (analytics yanıtından).
class ShortVideoLiker extends Equatable {
  const ShortVideoLiker({
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  String get label =>
      (displayName?.trim().isNotEmpty == true
              ? displayName
              : username)
          ?.trim() ??
      'Kullanıcı';

  factory ShortVideoLiker.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final m = user is Map ? Map<String, dynamic>.from(user) : json;
    return ShortVideoLiker(
      userId: (m['id'] ?? m['userId'] ?? m['_id'] ?? '').toString(),
      username: m['username']?.toString(),
      displayName: (m['displayName'] ?? m['name'] ?? m['nickname'])?.toString(),
      avatarUrl: (m['avatarUrl'] ?? m['avatar'] ?? m['image'])?.toString(),
    );
  }

  @override
  List<Object?> get props => [userId, username, displayName, avatarUrl];
}
