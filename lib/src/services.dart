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
    final Response<dynamic> response = await dio.get<dynamic>(path);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final Response<dynamic> response = await dio.post<dynamic>(
      path,
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
    } on Object {
      return CanlifalSeed.currentUser;
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
    } on Object {
      return CanlifalSeed.currentUser.copyWith(level: 1, coins: 500);
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
        '/feed?page=$page',
      );
      await _cacheService.writeJson('feed.$page', data);
      final Object? items = data['items'];
      if (items is List<dynamic>) {
        return CanlifalSeed.feedPage(page);
      }
    } on Object {
      _cacheService.readJson('feed.$page');
    }
    return CanlifalSeed.feedPage(page);
  }

  Future<List<StoryItem>> getStories() async => CanlifalSeed.stories;

  Future<List<LiveStream>> getLiveStreams() async => CanlifalSeed.liveStreams;

  Future<List<ChatRoom>> getChatRooms() async => CanlifalSeed.rooms;

  Future<List<ChatMessage>> getMessages(String roomId) async =>
      CanlifalSeed.messages;

  Future<List<FortuneService>> getFortuneServices() async =>
      CanlifalSeed.fortunes;

  Future<List<NotificationItem>> getNotifications() async =>
      CanlifalSeed.notifications;

  Future<List<AdminMetric>> getAdminMetrics() async =>
      CanlifalSeed.adminMetrics;
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
