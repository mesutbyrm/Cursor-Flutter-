import '../../core/constants/api_paths.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/cache_service.dart';
import '../../domain/entities/entities.dart';

class SocialRemoteDatasource {
  SocialRemoteDatasource({
    required ApiClient apiClient,
    required CacheService cacheService,
  }) : _apiClient = apiClient,
       _cacheService = cacheService;

  final ApiClient _apiClient;
  final CacheService _cacheService;

  Future<List<ContentPost>> getFeedPage(int page) async {
    try {
      final Map<String, dynamic> data = await _apiClient.getJson(
        '${ApiPaths.trendVideos}?page=$page',
      );
      await _cacheService.writeJson('feed.$page', data);
      final Object? items = data['items'] ?? data['videos'];
      if (items is List<dynamic>) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(ContentPost.fromTrendVideoJson)
            .toList();
      }
    } on Object {
      final Map<String, dynamic>? cached = _cacheService.readJson('feed.$page');
      final Object? videos = cached?['videos'] ?? cached?['items'];
      if (videos is List<dynamic>) {
        return videos
            .whereType<Map<String, dynamic>>()
            .map(ContentPost.fromTrendVideoJson)
            .toList();
      }
    }
    return <ContentPost>[];
  }

  Future<List<LiveStream>> getLiveStreams() async {
    try {
      final List<dynamic> items = await _apiClient.getList(ApiPaths.videoStreams);
      await _cacheService.writeJson('live-streams', <String, Object>{
        'items': items,
      });
      if (items.isNotEmpty) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(LiveStream.fromJson)
            .toList();
      }
    } on Object {
      _cacheService.readJson('live-streams');
    }
    return <LiveStream>[];
  }

  Future<List<ChatRoom>> getChatRooms() async {
    try {
      final List<dynamic> rooms = await _apiClient.getList(
        '${ApiPaths.chatRooms}?withCounts=true',
      );
      await _cacheService.writeJson('chat-rooms', <String, Object>{
        'rooms': rooms,
      });
      return rooms
          .whereType<Map<String, dynamic>>()
          .map(ChatRoom.fromJson)
          .toList();
    } on Object {
      final Object? rooms = _cacheService.readJson('chat-rooms')?['rooms'];
      if (rooms is List<dynamic>) {
        return rooms
            .whereType<Map<String, dynamic>>()
            .map(ChatRoom.fromJson)
            .toList();
      }
      return <ChatRoom>[];
    }
  }

  Future<List<ChatMessage>> getMessages(String roomId) async {
    try {
      final List<dynamic> items = await _apiClient.getList(
        ApiPaths.chatMessages(roomId),
      );
      return items.whereType<Map<String, dynamic>>().map((
        Map<String, dynamic> json,
      ) {
        return ChatMessage(
          id: json['id'] as String? ?? 'msg',
          sender: AppUser.fromJson(
            json['sender'] as Map<String, dynamic>? ?? <String, dynamic>{},
          ),
          body: json['body'] as String? ?? json['text'] as String? ?? '',
          sentAt: json['sentAt'] as String? ?? '',
          isGift: json['isGift'] as bool? ?? false,
        );
      }).toList();
    } on Object {
      return <ChatMessage>[];
    }
  }

  Future<List<FortuneService>> getFortuneServices() async {
    try {
      final Map<String, dynamic> data = await _apiClient.getJson(
        ApiPaths.fortuneTellers,
      );
      await _cacheService.writeJson('fortune-tellers', data);
      final Object? tellers = data['tellers'];
      if (tellers is List<dynamic>) {
        return tellers
            .whereType<Map<String, dynamic>>()
            .map(FortuneService.fromTellerJson)
            .toList();
      }
    } on Object {
      final Object? tellers = _cacheService.readJson(
        'fortune-tellers',
      )?['tellers'];
      if (tellers is List<dynamic>) {
        return tellers
            .whereType<Map<String, dynamic>>()
            .map(FortuneService.fromTellerJson)
            .toList();
      }
    }
    return <FortuneService>[];
  }

  Future<List<NotificationItem>> getNotifications() async {
    try {
      final Map<String, dynamic> data = await _apiClient.getJson(
        ApiPaths.announcements,
      );
      final Object? items = data['items'] ?? data['announcements'];
      if (items is List<dynamic>) {
        return items.whereType<Map<String, dynamic>>().map((
          Map<String, dynamic> item,
        ) {
          return NotificationItem(
            id: item['id'] as String? ?? 'announcement',
            title: item['title'] as String? ?? 'Canlifal',
            body: item['body'] as String? ?? item['message'] as String? ?? '',
            icon: item['icon'] as String? ?? '🔔',
            createdLabel: '',
            isRead: item['isRead'] as bool? ?? false,
          );
        }).toList();
      }
    } on Object {
      return <NotificationItem>[];
    }
    return <NotificationItem>[];
  }

  Future<List<AdminMetric>> getAdminMetrics() async {
    try {
      final Map<String, dynamic> stats = await _apiClient.getJson(
        ApiPaths.publicStats,
      );
      return <AdminMetric>[
        AdminMetric(
          title: 'Kullanıcı',
          value: '${(stats['users'] as Map<String, dynamic>?)?['total'] ?? 0}',
          delta: 'canlı',
        ),
        AdminMetric(
          title: 'Aktif yayın',
          value:
              '${(stats['video'] as Map<String, dynamic>?)?['activeStreams'] ?? 0}',
          delta: 'video',
        ),
        AdminMetric(
          title: 'Sohbet online',
          value:
              '${(stats['chat'] as Map<String, dynamic>?)?['totalOnline'] ?? 0}',
          delta: 'chat',
        ),
        AdminMetric(
          title: 'Toplam fal',
          value:
              '${(stats['fortunes'] as Map<String, dynamic>?)?['total'] ?? 0}',
          delta: 'fal',
        ),
      ];
    } on Object {
      return <AdminMetric>[];
    }
  }

  Future<List<ContentPost>> getExplorePosts() async {
    try {
      final Map<String, dynamic> data = await _apiClient.getJson(
        '${ApiPaths.celebrityPosts}?limit=30',
      );
      final Object? posts = data['posts'];
      if (posts is List<dynamic>) {
        return posts
            .whereType<Map<String, dynamic>>()
            .map(ContentPost.fromCelebrityPostJson)
            .toList();
      }
    } on Object {
      return <ContentPost>[];
    }
    return <ContentPost>[];
  }

  Future<AppUser> getProfile(String userId) async {
    final Map<String, dynamic> data = await _apiClient.getJson(
      ApiPaths.userProfile(userId),
    );
    return AppUser.fromJson(data);
  }

  Future<AppUser> followUser(String userId) async {
    final Map<String, dynamic> data = await _apiClient.postJson(
      ApiPaths.followUser(userId),
    );
    return AppUser.fromJson(data['user'] as Map<String, dynamic>? ?? data);
  }

  Future<AppUser> unfollowUser(String userId) async {
    final Map<String, dynamic> data = await _apiClient.deleteJson(
      ApiPaths.followUser(userId),
    );
    return AppUser.fromJson(data['user'] as Map<String, dynamic>? ?? data);
  }

  Future<int> getCoinBalance() async {
    try {
      final Map<String, dynamic> data = await _apiClient.getJson(
        ApiPaths.coinsBalance,
      );
      return (data['balance'] as num?)?.toInt() ??
          (data['coins'] as num?)?.toInt() ??
          0;
    } on Object {
      return 0;
    }
  }

  Future<int> spendCoins(int amount, {String? reason}) async {
    final Map<String, dynamic> data = await _apiClient.postJson(
      ApiPaths.coinsSpend,
      body: <String, dynamic>{
        'amount': amount,
        'reason': ?reason,
      },
    );
    return (data['balance'] as num?)?.toInt() ?? 0;
  }

  Future<Map<String, dynamic>> createLiveRoom({
    required String title,
    required String description,
  }) async {
    try {
      return _apiClient.postJson(
        ApiPaths.videoStreams,
        body: <String, dynamic>{'title': title, 'description': description},
      );
    } on Object {
      return <String, dynamic>{
        'message':
            'Canlı yayın başlatmak için API tarafında LiveKit oda token endpointi gerekir.',
      };
    }
  }

  Future<LiveStream?> getLiveStream(String id) async {
    final List<LiveStream> streams = await getLiveStreams();
    for (final LiveStream stream in streams) {
      if (stream.id == id) {
        return stream;
      }
    }
    return null;
  }
}
