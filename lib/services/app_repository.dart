import '../models/app_models.dart';
import 'api_client.dart';
import 'token_store.dart';

class AppRepository {
  AppRepository({ApiClient? apiClient, TokenStore? tokenStore})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStore = tokenStore ?? TokenStore();

  final ApiClient _apiClient;
  final TokenStore _tokenStore;

  bool get isConfigured => _apiClient.isConfigured;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final dynamic json = await _apiClient.post(
      '/api/auth/mobile-login',
      body: <String, String>{'email': email, 'password': password},
    );
    final AuthSession session = AuthSession.fromJson(
      json as Map<String, dynamic>,
    );
    await _tokenStore.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final dynamic json = await _apiClient.post(
      '/api/auth/mobile-register',
      body: <String, String>{
        'name': name,
        'email': email,
        'password': password,
      },
    );
    final AuthSession session = AuthSession.fromJson(
      json as Map<String, dynamic>,
    );
    await _tokenStore.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  Future<AuthSession> refreshToken() async {
    final String? refreshToken = await _tokenStore.readRefreshToken();
    final dynamic json = await _apiClient.post(
      '/api/auth/mobile-refresh',
      body: <String, String>{'refreshToken': refreshToken ?? ''},
    );
    final AuthSession session = AuthSession.fromJson(
      json as Map<String, dynamic>,
    );
    await _tokenStore.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  Future<List<FeedPostModel>> fetchFeed() async {
    if (!isConfigured) {
      return DemoData.feedPosts;
    }
    final dynamic json = await _apiClient.get(
      '/api/social/posts',
      query: <String, String>{'page': '1', 'limit': '20'},
    );
    return jsonList(json).map(FeedPostModel.fromJson).toList();
  }

  Future<List<LiveStreamModel>> fetchLiveStreams() async {
    if (!isConfigured) {
      return DemoData.liveStreams;
    }
    final dynamic json = await _apiClient.get('/api/video-streams');
    return jsonList(json).map(LiveStreamModel.fromJson).toList();
  }

  Future<List<AudioRoomModel>> fetchAudioRooms() async {
    if (!isConfigured) {
      return DemoData.audioRooms;
    }
    final dynamic json = await _apiClient.get(
      '/api/chat/rooms',
      query: <String, String>{'withCounts': 'true'},
    );
    return jsonList(json).map(AudioRoomModel.fromJson).toList();
  }

  Future<List<GiftTypeModel>> fetchGiftTypes() async {
    if (!isConfigured) {
      return DemoData.giftTypes;
    }
    final dynamic json = await _apiClient.get('/api/gifts/types');
    return jsonList(json).map(GiftTypeModel.fromJson).toList();
  }

  Future<TrtcCredentials> fetchTrtcUserSig({
    required String userId,
    required String roomId,
  }) async {
    final dynamic json = await _apiClient.post(
      '/api/trtc/usersig',
      body: <String, String>{'userId': userId, 'roomId': roomId},
    );
    return TrtcCredentials.fromJson(json as Map<String, dynamic>);
  }

  Future<void> sendStreamGift({
    required String streamId,
    required String giftTypeId,
    required int quantity,
  }) async {
    await _apiClient.post(
      '/api/video-streams/$streamId/gifts',
      body: <String, Object>{'giftTypeId': giftTypeId, 'quantity': quantity},
    );
  }

  Future<void> likeLiveStream(String streamId) async {
    await _apiClient.post('/api/video-streams/$streamId/like');
  }

  Future<void> sendStreamComment({
    required String streamId,
    required String content,
  }) async {
    await _apiClient.post(
      '/api/video-streams/$streamId/comments',
      body: <String, String>{'content': content},
    );
  }

  Future<void> sendProfileGift({
    required String recipientUsername,
    required String giftTypeId,
  }) async {
    await _apiClient.post(
      '/api/gifts/send',
      body: <String, String>{
        'recipientUsername': recipientUsername,
        'giftTypeId': giftTypeId,
        'type': 'gift',
      },
    );
  }

  Future<AppUser> fetchProfile() async {
    final dynamic json = await _apiClient.get('/api/user/profile');
    return AppUser.fromJson(json as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> fetchBalance() async {
    final dynamic json = await _apiClient.get('/api/jeton');
    return json is Map<String, dynamic> ? json : <String, dynamic>{};
  }

  Future<LiveStreamModel> createLiveStream({
    required String title,
    required String description,
  }) async {
    final dynamic json = await _apiClient.post(
      '/api/video-streams',
      body: <String, String>{'title': title, 'description': description},
    );
    return LiveStreamModel.fromJson(json as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> joinLiveStream(String streamId) async {
    final dynamic json = await _apiClient.post(
      '/api/video-streams/$streamId/join',
    );
    return json is Map<String, dynamic> ? json : <String, dynamic>{};
  }

  Future<void> leaveLiveStream({
    required String streamId,
    required String viewerId,
  }) async {
    await _apiClient.delete(
      '/api/video-streams/$streamId/join',
      query: <String, String>{'viewerId': viewerId},
    );
  }

  Future<void> sendRoomGift({
    required String roomId,
    required String giftTypeId,
    required int quantity,
  }) async {
    await _apiClient.post(
      '/api/chat/rooms/$roomId/gifts',
      body: <String, Object>{'giftTypeId': giftTypeId, 'quantity': quantity},
    );
  }

  Future<void> enterAudioRoom(String roomId) async {
    await _apiClient.post('/api/chat/rooms/$roomId/presence');
  }

  Future<void> enableRoomVoice({
    required String roomId,
    required bool enabled,
  }) async {
    await _apiClient.post(
      '/api/chat/rooms/$roomId/voice',
      body: <String, bool>{'enabled': enabled},
    );
  }
}

class DemoData {
  const DemoData._();

  static const List<FeedPostModel> feedPosts = <FeedPostModel>[
    FeedPostModel(
      id: 'demo-feed-1',
      authorName: 'Mina Live',
      username: '@mina',
      text:
          'Yeni canlı yayın odamız başladı. Hediye efekti, sesli sohbet ve özel FunClub odası açık!',
      mediaUrl: '',
      likes: 12400,
      comments: 842,
    ),
    FeedPostModel(
      id: 'demo-feed-2',
      authorName: 'Ege',
      username: '@egeplus',
      text:
          'Bugünün trendi: kısa video, ortak yayın, jeton görevleri ve arkadaş daveti.',
      mediaUrl: '',
      likes: 8100,
      comments: 391,
    ),
  ];

  static const List<LiveStreamModel> liveStreams = <LiveStreamModel>[
    LiveStreamModel(
      id: 'demo-live-1',
      title: 'Gece sohbeti',
      hostName: 'Lara',
      viewerCount: 21800,
      roomId: '1001',
      coverUrl: '',
    ),
    LiveStreamModel(
      id: 'demo-live-2',
      title: 'Ortak yayın',
      hostName: 'Deniz & Arda',
      viewerCount: 9400,
      roomId: '1002',
      coverUrl: '',
    ),
  ];

  static const List<AudioRoomModel> audioRooms = <AudioRoomModel>[
    AudioRoomModel(
      id: 'demo-room-1',
      title: 'Muhabbet Cafe',
      listenerCount: 248,
      speakerCount: 12,
      roomId: '2001',
      isGoldOnly: false,
    ),
    AudioRoomModel(
      id: 'demo-room-2',
      title: 'Oyun gecesi',
      listenerCount: 183,
      speakerCount: 6,
      roomId: '2002',
      isGoldOnly: false,
    ),
    AudioRoomModel(
      id: 'demo-room-3',
      title: 'Gold üyeler kulübü',
      listenerCount: 74,
      speakerCount: 4,
      roomId: '2003',
      isGoldOnly: true,
    ),
  ];

  static const List<GiftTypeModel> giftTypes = <GiftTypeModel>[
    GiftTypeModel(
      id: 'heart',
      name: 'Kalp',
      price: 10,
      iconUrl: '',
      icon: '🌹',
      animationUrl: '',
      soundUrl: '',
    ),
    GiftTypeModel(
      id: 'rocket',
      name: 'Roket',
      price: 250,
      iconUrl: '',
      icon: '🚀',
      animationUrl: '',
      soundUrl: '',
    ),
    GiftTypeModel(
      id: 'crown',
      name: 'Taç',
      price: 500,
      iconUrl: '',
      icon: '👑',
      animationUrl: '',
      soundUrl: '',
    ),
  ];
}
