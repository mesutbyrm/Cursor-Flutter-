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
    final Map<String, dynamic> data = _asMap(json['data'], fallback: json);
    return AuthSession(
      accessToken: _asString(data['accessToken'] ?? data['access_token']),
      refreshToken: _asString(data['refreshToken'] ?? data['refresh_token']),
      user: AppUser.fromJson(_asMap(data['user'])),
    );
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.followers,
    required this.following,
    required this.likes,
    required this.isGold,
    required this.coinBalance,
  });

  final String id;
  final String name;
  final String username;
  final String avatarUrl;
  final int followers;
  final int following;
  final int likes;
  final bool isGold;
  final int coinBalance;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: _asString(json['id'] ?? json['_id']),
      name: _asString(
        json['name'] ?? json['displayName'],
        fallback: 'Kullanıcı',
      ),
      username: _asString(json['username'], fallback: '@kullanici'),
      avatarUrl: _asString(
        json['image'] ?? json['avatarUrl'] ?? json['avatar'],
      ),
      followers: _asInt(json['followers'] ?? json['followersCount']),
      following: _asInt(json['following'] ?? json['followingCount']),
      likes: _asInt(json['likes'] ?? json['likesCount']),
      isGold:
          _asBool(json['isGold'] ?? json['gold']) ||
          _asString(json['membership']) == 'gold',
      coinBalance: _asInt(
        json['jetonBalance'] ?? json['coinBalance'] ?? json['coins'],
      ),
    );
  }
}

class FeedPostModel {
  const FeedPostModel({
    required this.id,
    required this.authorName,
    required this.username,
    required this.text,
    required this.mediaUrl,
    required this.likes,
    required this.comments,
  });

  final String id;
  final String authorName;
  final String username;
  final String text;
  final String mediaUrl;
  final int likes;
  final int comments;

  factory FeedPostModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> user = _asMap(json['user'] ?? json['author']);
    final Map<String, dynamic> count = _asMap(json['_count']);
    return FeedPostModel(
      id: _asString(json['id'] ?? json['_id']),
      authorName: _asString(
        user['name'] ?? json['authorName'],
        fallback: 'Canlı Kullanıcı',
      ),
      username: _asString(
        user['username'] ?? json['username'],
        fallback: '@live',
      ),
      text: _asString(json['text'] ?? json['content'] ?? json['description']),
      mediaUrl: _asString(
        json['mediaUrl'] ?? json['videoUrl'] ?? json['imageUrl'],
      ),
      likes: _asInt(count['likes'] ?? json['likeCount'] ?? json['likes']),
      comments: _asInt(
        count['comments'] ?? json['commentCount'] ?? json['comments'],
      ),
    );
  }
}

class LiveStreamModel {
  const LiveStreamModel({
    required this.id,
    required this.title,
    required this.hostName,
    required this.viewerCount,
    required this.roomId,
    required this.coverUrl,
  });

  final String id;
  final String title;
  final String hostName;
  final int viewerCount;
  final String roomId;
  final String coverUrl;

  factory LiveStreamModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> host = _asMap(json['host'] ?? json['user']);
    return LiveStreamModel(
      id: _asString(json['id'] ?? json['_id'] ?? json['streamId']),
      title: _asString(json['title'], fallback: 'Canlı yayın'),
      hostName: _asString(
        host['name'] ?? json['hostName'],
        fallback: 'Yayıncı',
      ),
      viewerCount: _asInt(json['viewerCount'] ?? json['viewers']),
      roomId: _asString(json['roomId'] ?? json['trtcRoomId']),
      coverUrl: _asString(json['coverUrl'] ?? json['thumbnail']),
    );
  }
}

class AudioRoomModel {
  const AudioRoomModel({
    required this.id,
    required this.title,
    required this.listenerCount,
    required this.speakerCount,
    required this.roomId,
    required this.isGoldOnly,
  });

  final String id;
  final String title;
  final int listenerCount;
  final int speakerCount;
  final String roomId;
  final bool isGoldOnly;

  factory AudioRoomModel.fromJson(Map<String, dynamic> json) {
    return AudioRoomModel(
      id: _asString(json['id'] ?? json['_id'] ?? json['roomId']),
      title: _asString(
        json['title'] ?? json['nameTr'] ?? json['name'],
        fallback: 'Sesli oda',
      ),
      listenerCount: _asInt(
        json['listenerCount'] ?? json['onlineCount'] ?? json['listeners'],
      ),
      speakerCount: _asInt(json['speakerCount'] ?? json['speakers']),
      roomId: _asString(json['roomId'] ?? json['trtcRoomId']),
      isGoldOnly: _asBool(json['isGoldOnly'] ?? json['goldOnly']),
    );
  }
}

class GiftTypeModel {
  const GiftTypeModel({
    required this.id,
    required this.name,
    required this.price,
    required this.iconUrl,
    required this.icon,
    required this.animationUrl,
    required this.soundUrl,
  });

  final String id;
  final String name;
  final int price;
  final String iconUrl;
  final String icon;
  final String animationUrl;
  final String soundUrl;

  factory GiftTypeModel.fromJson(Map<String, dynamic> json) {
    return GiftTypeModel(
      id: _asString(json['id'] ?? json['_id']),
      name: _asString(json['name'], fallback: 'Hediye'),
      price: _asInt(json['price'] ?? json['coinPrice'] ?? json['coins']),
      iconUrl: _asString(json['iconUrl'] ?? json['imageUrl']),
      icon: _asString(json['icon']),
      animationUrl: _asString(json['animationUrl']),
      soundUrl: _asString(json['soundUrl']),
    );
  }
}

class TrtcCredentials {
  const TrtcCredentials({
    required this.sdkAppId,
    required this.userId,
    required this.userSig,
    required this.roomId,
  });

  final int sdkAppId;
  final String userId;
  final String userSig;
  final String roomId;

  factory TrtcCredentials.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = _asMap(json['data'], fallback: json);
    return TrtcCredentials(
      sdkAppId: _asInt(data['sdkAppId'] ?? data['SDKAppID']),
      userId: _asString(data['userId']),
      userSig: _asString(data['userSig']),
      roomId: _asString(data['roomId']),
    );
  }
}

List<Map<String, dynamic>> jsonList(dynamic value) {
  final dynamic data = value is Map<String, dynamic>
      ? value['data'] ??
            value['items'] ??
            value['results'] ??
            value['posts'] ??
            value['rooms'] ??
            value['notifications'] ??
            value['stories'] ??
            value['trends']
      : value;
  if (data is List) {
    return data.whereType<Map<String, dynamic>>().toList();
  }
  if (data is Map<String, dynamic>) {
    final dynamic nested =
        data['items'] ??
        data['results'] ??
        data['data'] ??
        data['posts'] ??
        data['rooms'] ??
        data['notifications'] ??
        data['stories'] ??
        data['trends'];
    if (nested is List) {
      return nested.whereType<Map<String, dynamic>>().toList();
    }
  }
  return <Map<String, dynamic>>[];
}

Map<String, dynamic> _asMap(dynamic value, {Map<String, dynamic>? fallback}) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  return fallback ?? <String, dynamic>{};
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  final String result = value.toString();
  return result.isEmpty ? fallback : result;
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  return value?.toString() == 'true' || value?.toString() == '1';
}
