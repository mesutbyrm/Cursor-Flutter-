/// `GET /api/chat/rooms/{roomId}/moderation` — ban satırı.
class VoiceRoomBanEntry {
  const VoiceRoomBanEntry({
    required this.id,
    required this.userId,
    this.reason,
    this.userName,
    this.username,
    this.imageUrl,
    this.bannedByName,
  });

  final String id;
  final String userId;
  final String? reason;
  final String? userName;
  final String? username;
  final String? imageUrl;
  final String? bannedByName;

  String get displayName {
    final name = userName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final un = username?.trim();
    if (un != null && un.isNotEmpty) return un;
    return userId;
  }

  factory VoiceRoomBanEntry.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : null;
    final bannedBy = json['bannedByUser'];
    final bannedByMap =
        bannedBy is Map ? Map<String, dynamic>.from(bannedBy) : null;
    return VoiceRoomBanEntry(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ??
          userMap?['id']?.toString() ??
          '',
      reason: json['reason']?.toString(),
      userName: userMap?['name']?.toString(),
      username: userMap?['username']?.toString(),
      imageUrl: userMap?['image']?.toString(),
      bannedByName: bannedByMap?['name']?.toString(),
    );
  }
}
