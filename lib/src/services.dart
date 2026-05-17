import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:livekit_client/livekit_client.dart' as livekit;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'models.dart';

class AppConfig {
  const AppConfig({
    this.apiBaseUrl = 'https://canlifal.com/api',
    this.webSocketUrl = 'wss://canlifal.com/ws',
    this.liveKitUrl = '',
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      apiBaseUrl: String.fromEnvironment(
        'CANLIFAL_API_URL',
        defaultValue: 'https://canlifal.com/api',
      ),
      webSocketUrl: String.fromEnvironment(
        'CANLIFAL_WS_URL',
        defaultValue: 'wss://canlifal.com/ws',
      ),
      liveKitUrl: String.fromEnvironment('CANLIFAL_LIVEKIT_URL'),
    );
  }

  final String apiBaseUrl;
  final String webSocketUrl;
  final String liveKitUrl;
}

class AppBootstrap {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
    } on Object {
      // Firebase config is supplied per environment by native projects.
    }

    await PushNotificationService().initialize();
  }
}

class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _accessTokenKey = 'canlifal.access_token';
  static const String _refreshTokenKey = 'canlifal.refresh_token';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

class CacheService {
  CacheService(this._preferences);

  final SharedPreferences _preferences;

  Future<void> writeJson(String key, Object value) async {
    await _preferences.setString(key, jsonEncode(value));
  }

  Map<String, dynamic>? readJson(String key) {
    final String? value = _preferences.getString(key);
    if (value == null) {
      return null;
    }

    final Object? decoded = jsonDecode(value);
    return decoded is Map<String, dynamic> ? decoded : null;
  }
}

class ApiClient {
  ApiClient({
    required AppConfig config,
    required SecureTokenStorage tokenStorage,
  }) : _tokenStorage = tokenStorage,
       dio = Dio(
         BaseOptions(
           baseUrl: config.apiBaseUrl,
           connectTimeout: const Duration(seconds: 12),
           receiveTimeout: const Duration(seconds: 20),
           headers: const <String, Object?>{
             'Accept': 'application/json',
             'Content-Type': 'application/json',
           },
         ),
       ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (RequestOptions options, RequestInterceptorHandler handler) async {
              final String? token = await _tokenStorage.readAccessToken();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
      ),
    );
  }

  final Dio dio;
  final SecureTokenStorage _tokenStorage;

  Future<Map<String, dynamic>> getJson(String path) async {
    final Response<dynamic> response = await dio.get<dynamic>(_apiPath(path));
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final Response<dynamic> response = await dio.post<dynamic>(
      _apiPath(path),
      data: body,
    );
    return _asMap(response.data);
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }

  String _apiPath(String path) {
    if (path.startsWith('/api/')) {
      return path.substring('/api/'.length);
    }
    if (path.startsWith('/')) {
      return path.substring(1);
    }
    return path;
  }
}

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required SecureTokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final SecureTokenStorage _tokenStorage;

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      final Map<String, dynamic> data = await _apiClient.postJson(
        '/auth/login',
        body: <String, dynamic>{'email': email, 'password': password},
      );
      await _persistTokensIfPresent(data);
      return AppUser.fromJson(data['user'] as Map<String, dynamic>? ?? data);
    } on Object catch (error) {
      throw Exception('Giriş yapılamadı: $error');
    }
  }

  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await firebase_auth.FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
      }

      final Map<String, dynamic> data = await _apiClient.postJson(
        '/auth/register',
        body: <String, dynamic>{
          'email': email,
          'password': password,
          'displayName': displayName,
        },
      );
      await _persistTokensIfPresent(data);
      return AppUser.fromJson(data['user'] as Map<String, dynamic>? ?? data);
    } on Object catch (error) {
      throw Exception('Kayıt oluşturulamadı: $error');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(
          email: email,
        );
      }
      await _apiClient.postJson(
        '/auth/forgot-password',
        body: <String, dynamic>{'email': email},
      );
    } on Object {
      return;
    }
  }

  Future<void> signOut() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await firebase_auth.FirebaseAuth.instance.signOut();
      }
    } finally {
      await _tokenStorage.clear();
    }
  }

  Future<void> _persistTokensIfPresent(Map<String, dynamic> data) async {
    final String? accessToken = data['accessToken'] as String?;
    final String? refreshToken = data['refreshToken'] as String?;
    if (accessToken != null && refreshToken != null) {
      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }
  }
}

class CanlifalRepository {
  CanlifalRepository({
    required ApiClient apiClient,
    required CacheService cacheService,
  }) : _apiClient = apiClient,
       _cacheService = cacheService;

  final ApiClient _apiClient;
  final CacheService _cacheService;

  Future<List<ContentPost>> getFeedPage(int page) async {
    try {
      final Map<String, dynamic> data = await _apiClient.getJson(
        '/trend-videos?page=$page',
      );
      await _cacheService.writeJson('feed.$page', data);
      final Object? items = data['items'];
      if (items is List<dynamic>) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(ContentPost.fromTrendVideoJson)
            .toList();
      }
      final Object? videos = data['videos'];
      if (videos is List<dynamic>) {
        return videos
            .whereType<Map<String, dynamic>>()
            .map(ContentPost.fromTrendVideoJson)
            .toList();
      }
    } on Object {
      final Map<String, dynamic>? cached = _cacheService.readJson('feed.$page');
      final Object? videos = cached?['videos'];
      if (videos is List<dynamic>) {
        return videos
            .whereType<Map<String, dynamic>>()
            .map(ContentPost.fromTrendVideoJson)
            .toList();
      }
    }
    return <ContentPost>[];
  }

  Future<List<StoryItem>> getStories() async {
    final List<FortuneService> tellers = await getFortuneServices();
    return tellers
        .where((FortuneService service) => service.isLive)
        .map(
          (FortuneService service) => StoryItem(
            id: service.id,
            title: service.advisor.displayName,
            imageUrl: service.advisor.avatarUrl,
            owner: service.advisor,
            isLive: service.isLive,
          ),
        )
        .toList();
  }

  Future<List<LiveStream>> getLiveStreams() async {
    try {
      final Response<dynamic> response = await _apiClient.dio.get<dynamic>(
        'video-streams',
      );
      final Object? data = response.data;
      final List<dynamic> items = data is List<dynamic>
          ? data
          : data is Map<String, dynamic> && data['items'] is List<dynamic>
          ? data['items'] as List<dynamic>
          : const <dynamic>[];
      await _cacheService.writeJson('live-streams', <String, Object>{
        'items': items,
      });
      if (items.isNotEmpty) {
        final List<LiveStream> streams = items
            .whereType<Map<String, dynamic>>()
            .map(LiveStream.fromJson)
            .toList();
        if (streams.isNotEmpty) {
          return streams;
        }
      }
    } on Object {
      _cacheService.readJson('live-streams');
    }
    return <LiveStream>[];
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

  Future<Map<String, dynamic>> createLiveRoom({
    required String title,
    required String description,
  }) async {
    try {
      return _apiClient.postJson(
        '/video-streams',
        body: <String, dynamic>{'title': title, 'description': description},
      );
    } on Object {
      return <String, dynamic>{
        'message':
            'Canlı yayın başlatmak için API tarafında LiveKit oda token endpointi gerekir.',
      };
    }
  }

  Future<List<ChatRoom>> getChatRooms() async {
    try {
      final Response<dynamic> response = await _apiClient.dio.get<dynamic>(
        'chat/rooms?withCounts=true',
      );
      final Object? data = response.data;
      final List<dynamic> rooms = data is List<dynamic>
          ? data
          : data is Map<String, dynamic> && data['rooms'] is List<dynamic>
          ? data['rooms'] as List<dynamic>
          : const <dynamic>[];
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

  Future<List<ChatMessage>> getMessages(String roomId) async => <ChatMessage>[];

  Future<List<FortuneService>> getFortuneServices() async {
    try {
      final Map<String, dynamic> data = await _apiClient.getJson(
        '/fortune-tellers',
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
        '/announcements',
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
        '/public-stats',
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
        '/celebrities/posts/latest?limit=30',
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
}

class RealtimeClient {
  RealtimeClient(this._config);

  final AppConfig _config;
  WebSocketChannel? _channel;

  Stream<dynamic> connect(String channel) {
    final Uri uri = Uri.parse('${_config.webSocketUrl}/$channel');
    _channel = WebSocketChannel.connect(uri);
    return _channel!.stream;
  }

  void send(Map<String, dynamic> payload) {
    _channel?.sink.add(jsonEncode(payload));
  }

  Future<void> dispose() async {
    await _channel?.sink.close();
  }
}

class LiveRtcService {
  livekit.Room? _room;

  Future<void> connect({required String url, required String token}) async {
    if (url.isEmpty || token.isEmpty) {
      return;
    }
    final livekit.Room room = livekit.Room();
    await room.connect(url, token);
    _room = room;
  }

  Future<void> disconnect() async {
    await _room?.disconnect();
    _room = null;
  }
}

class PushNotificationService {
  PushNotificationService({FlutterLocalNotificationsPlugin? localNotifications})
    : _localNotifications =
          localNotifications ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _localNotifications;

  Future<void> initialize() async {
    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(settings: settings);

    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseMessaging.instance.requestPermission();
        await FirebaseMessaging.instance.getToken();
      }
    } on Object {
      return;
    }
  }
}
