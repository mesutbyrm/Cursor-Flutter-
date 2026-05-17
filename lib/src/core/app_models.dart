class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.image,
    required this.coverImage,
    required this.bio,
    required this.followers,
    required this.following,
    required this.likes,
    required this.level,
    required this.coins,
    required this.membership,
    required this.badges,
  });

  final String id;
  final String name;
  final String username;
  final String email;
  final String image;
  final String coverImage;
  final String bio;
  final int followers;
  final int following;
  final int likes;
  final int level;
  final int coins;
  final String membership;
  final List<String> badges;

  bool get isPremium => membership.toLowerCase() == 'gold';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: _string(json['id'] ?? json['_id']),
      name: _string(json['name'], fallback: 'Canlifal Kullanıcısı'),
      username: _string(json['username'], fallback: 'canlifal'),
      email: _string(json['email']),
      image: _string(json['image'] ?? json['avatarUrl'] ?? json['avatar']),
      coverImage: _string(json['coverImage'] ?? json['coverUrl']),
      bio: _string(
        json['bio'],
        fallback: 'Canlı yayın, sosyal akış ve fal topluluğu.',
      ),
      followers: _int(json['followersCount'] ?? json['followers']),
      following: _int(json['followingCount'] ?? json['following']),
      likes: _int(json['likesCount'] ?? json['likes']),
      level: _int(json['level']),
      coins: _int(json['jetonBalance'] ?? json['coins'] ?? json['coinBalance']),
      membership: _string(json['membership'], fallback: 'basic'),
      badges: _stringList(json['badges']),
    );
  }

  static const guest = AppUser(
    id: 'guest',
    name: 'Misafir Kullanıcı',
    username: 'misafir',
    email: '',
    image: '',
    coverImage: '',
    bio: 'Misafir modunda uygulamayı inceliyor.',
    followers: 0,
    following: 0,
    likes: 0,
    level: 1,
    coins: 0,
    membership: 'basic',
    badges: <String>['Misafir'],
  );
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AppUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final data = _map(json['data'], fallback: json);
    return AuthSession(
      accessToken: _string(data['accessToken'] ?? data['access_token']),
      refreshToken: _string(data['refreshToken'] ?? data['refresh_token']),
      user: AppUser.fromJson(_map(data['user'])),
    );
  }
}

class FeedPost {
  const FeedPost({
    required this.id,
    required this.content,
    required this.type,
    required this.imageUrl,
    required this.author,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
  });

  final String id;
  final String content;
  final String type;
  final String imageUrl;
  final AppUser author;
  final int likeCount;
  final int commentCount;
  final int viewCount;

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    final count = _map(json['_count']);
    return FeedPost(
      id: _string(json['id'] ?? json['_id']),
      content: _string(json['content'] ?? json['text']),
      type: _string(json['postType'] ?? json['type'], fallback: 'text'),
      imageUrl: _string(json['imageUrl'] ?? json['mediaUrl']),
      author: AppUser.fromJson(_map(json['user'] ?? json['author'])),
      likeCount: _int(count['likes'] ?? json['likeCount']),
      commentCount: _int(count['comments'] ?? json['commentCount']),
      viewCount: _int(json['viewCount']),
    );
  }
}

class LiveStream {
  const LiveStream({
    required this.id,
    required this.title,
    required this.description,
    required this.host,
    required this.viewerCount,
    required this.likeCount,
    required this.commentCount,
    required this.roomId,
    required this.status,
  });

  final String id;
  final String title;
  final String description;
  final AppUser host;
  final int viewerCount;
  final int likeCount;
  final int commentCount;
  final String roomId;
  final String status;

  factory LiveStream.fromJson(Map<String, dynamic> json) {
    final id = _string(json['id'] ?? json['streamId']);
    return LiveStream(
      id: id,
      title: _string(json['title'], fallback: 'Canlı yayın'),
      description: _string(json['description']),
      host: AppUser.fromJson(_map(json['user'] ?? json['host'])),
      viewerCount: _int(json['viewerCount'] ?? json['viewers']),
      likeCount: _int(json['likeCount'] ?? json['likes']),
      commentCount: _int(json['commentCount'] ?? json['comments']),
      roomId: _string(json['roomId'] ?? json['trtcRoomId'], fallback: id),
      status: _string(json['status'], fallback: 'live'),
    );
  }
}

class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.name,
    required this.icon,
    required this.ownerName,
    required this.onlineCount,
    required this.speakerCount,
    required this.isPremium,
  });

  final String id;
  final String name;
  final String icon;
  final String ownerName;
  final int onlineCount;
  final int speakerCount;
  final bool isPremium;

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: _string(json['id'] ?? json['roomId']),
      name: _string(
        json['nameTr'] ?? json['name'] ?? json['title'],
        fallback: 'Sesli oda',
      ),
      icon: _string(json['icon'], fallback: '🔮'),
      ownerName: _string(_map(json['owner'])['name'], fallback: 'Canlifal'),
      onlineCount: _int(json['onlineCount'] ?? json['listenerCount']),
      speakerCount: _int(json['speakerCount']),
      isPremium: _bool(json['isPremium'] ?? json['goldOnly']),
    );
  }
}

class GiftType {
  const GiftType({
    required this.id,
    required this.name,
    required this.icon,
    required this.price,
    required this.imageUrl,
    required this.animationUrl,
    required this.soundUrl,
  });

  final String id;
  final String name;
  final String icon;
  final int price;
  final String imageUrl;
  final String animationUrl;
  final String soundUrl;

  factory GiftType.fromJson(Map<String, dynamic> json) {
    return GiftType(
      id: _string(json['id'] ?? json['_id']),
      name: _string(json['name'], fallback: 'Hediye'),
      icon: _string(json['icon'], fallback: '🎁'),
      price: _int(json['price'] ?? json['coinPrice']),
      imageUrl: _string(json['imageUrl'] ?? json['iconUrl']),
      animationUrl: _string(json['animationUrl']),
      soundUrl: _string(json['soundUrl']),
    );
  }
}

class TrendItem {
  const TrendItem({
    required this.title,
    required this.subtitle,
    required this.score,
  });

  final String title;
  final String subtitle;
  final int score;

  factory TrendItem.fromJson(Map<String, dynamic> json) {
    return TrendItem(
      title: _string(
        json['title'] ?? json['name'] ?? json['hashtag'],
        fallback: '#canlifal',
      ),
      subtitle: _string(
        json['description'] ?? json['category'],
        fallback: 'Trend içerik',
      ),
      score: _int(json['score'] ?? json['viewCount'] ?? json['likes']),
    );
  }
}

class FortuneCategory {
  const FortuneCategory({
    required this.name,
    required this.endpoint,
    required this.description,
    required this.icon,
  });

  final String name;
  final String endpoint;
  final String description;
  final String icon;
}

Map<String, dynamic> _map(dynamic value, {Map<String, dynamic>? fallback}) {
  if (value is Map<String, dynamic>) return value;
  return fallback ?? <String, dynamic>{};
}

List<Map<String, dynamic>> asList(dynamic value) {
  final data = value is Map<String, dynamic>
      ? value['data'] ??
            value['items'] ??
            value['results'] ??
            value['posts'] ??
            value['rooms'] ??
            value['trends'] ??
            value['notifications']
      : value;
  if (data is List) return data.whereType<Map<String, dynamic>>().toList();
  return <Map<String, dynamic>>[];
}

String _string(dynamic value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  return value?.toString() == 'true' || value?.toString() == '1';
}

List<String> _stringList(dynamic value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  return const <String>[];
}
