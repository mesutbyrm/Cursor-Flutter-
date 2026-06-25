import 'package:equatable/equatable.dart';

/// `GET /api/video-streams/{id}/viewers` satırı.
class LiveStreamViewer extends Equatable {
  const LiveStreamViewer({
    required this.id,
    required this.displayName,
    this.username,
    this.avatarUrl,
    this.isVip = false,
    this.isModerator = false,
    this.isBroadcaster = false,
    this.isFollowing = false,
    this.lastSeen,
  });

  final String id;
  final String displayName;
  final String? username;
  final String? avatarUrl;
  final bool isVip;
  final bool isModerator;
  final bool isBroadcaster;
  final bool isFollowing;
  final DateTime? lastSeen;

  factory LiveStreamViewer.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : json;
    final id = (user['id'] ?? user['userId'] ?? json['id'] ?? '').toString();
    final name = (user['displayName'] ??
            user['name'] ??
            user['username'] ??
            json['displayName'] ??
            'İzleyici')
        .toString();
    final role = (json['role'] ?? user['role'] ?? '').toString().toLowerCase();
    final badges = json['badges'] ?? user['badges'];
    var isMod = json['isModerator'] == true ||
        user['isModerator'] == true ||
        role.contains('mod');
    var isVip = json['isVip'] == true ||
        user['isVip'] == true ||
        role.contains('vip');
    var isHost = json['isBroadcaster'] == true ||
        user['isBroadcaster'] == true ||
        role.contains('host') ||
        role.contains('broadcaster');
    if (badges is List) {
      for (final b in badges) {
        final s = b.toString().toLowerCase();
        if (s.contains('vip')) isVip = true;
        if (s.contains('mod')) isMod = true;
        if (s.contains('host') || s.contains('broadcaster')) isHost = true;
      }
    }
    DateTime? seen;
    final rawSeen = json['lastSeen'] ?? user['lastSeen'] ?? json['joinedAt'];
    if (rawSeen != null) {
      seen = DateTime.tryParse(rawSeen.toString());
    }
    return LiveStreamViewer(
      id: id,
      displayName: name,
      username: (user['username'] ?? json['username'])?.toString(),
      avatarUrl: (user['image'] ?? user['avatarUrl'] ?? json['avatarUrl'])
          ?.toString(),
      isVip: isVip,
      isModerator: isMod,
      isBroadcaster: isHost,
      isFollowing: json['isFollowing'] == true || user['isFollowing'] == true,
      lastSeen: seen,
    );
  }

  @override
  List<Object?> get props => [id, displayName, isVip, isModerator, isBroadcaster];
}
