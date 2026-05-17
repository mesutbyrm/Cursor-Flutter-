import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_models.dart';

const String kAppName = 'CanlifalTV';
const String kLogoAsset = 'assets/brand/vivalive_logo.png';

class SecureTokenStorage {
  const SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const String _accessKey = 'access_token';
  static const String _refreshKey = 'refresh_token';

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  Future<void> save(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

class CanlifalApi {
  CanlifalApi(this._tokens)
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'https://canlifal.com',
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (RequestOptions options, RequestInterceptorHandler handler) async {
              final token = await _tokens.readAccessToken();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
      ),
    );
  }

  final SecureTokenStorage _tokens;
  final Dio _dio;

  Future<AuthSession> login(String email, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/mobile-login',
      data: <String, String>{'email': email, 'password': password},
    );
    final session = AuthSession.fromJson(response.data ?? <String, dynamic>{});
    await _tokens.save(session.accessToken, session.refreshToken);
    return session;
  }

  Future<AuthSession> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required String birthDate,
    required String birthTime,
    String? referralCode,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/mobile-register',
      data: <String, String>{
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'birthDate': birthDate,
        'birthTime': birthTime,
        'preferredLanguage': 'tr',
        if (referralCode != null && referralCode.isNotEmpty)
          'referralCode': referralCode,
      },
    );
    final session = AuthSession.fromJson(response.data ?? <String, dynamic>{});
    await _tokens.save(session.accessToken, session.refreshToken);
    return session;
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post<void>(
      '/api/auth/forgot-password',
      data: <String, String>{'email': email},
    );
  }

  Future<AppUser> profile() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/user/profile');
    return AppUser.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<List<FeedPost>> feed({int page = 1}) async {
    final response = await _dio.get<dynamic>(
      '/api/social/posts',
      queryParameters: <String, Object>{'page': page, 'limit': 20},
    );
    return asList(response.data).map(FeedPost.fromJson).toList();
  }

  Future<List<LiveStream>> liveStreams() async {
    final response = await _dio.get<dynamic>('/api/video-streams');
    return asList(response.data).map(LiveStream.fromJson).toList();
  }

  Future<LiveStream> createLiveStream(String title, String description) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/video-streams',
      data: <String, String>{'title': title, 'description': description},
    );
    return LiveStream.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<void> joinLive(String streamId) =>
      _dio.post<void>('/api/video-streams/$streamId/join');

  Future<void> likeLive(String streamId) =>
      _dio.post<void>('/api/video-streams/$streamId/like');

  Future<void> commentLive(String streamId, String content) {
    return _dio.post<void>(
      '/api/video-streams/$streamId/comments',
      data: <String, String>{'content': content},
    );
  }

  Future<Map<String, dynamic>> trtcUserSig(String userId, String roomId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/trtc/usersig',
      data: <String, String>{'userId': userId, 'roomId': roomId},
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<List<ChatRoom>> rooms() async {
    final response = await _dio.get<dynamic>(
      '/api/chat/rooms',
      queryParameters: <String, Object>{'withCounts': true},
    );
    return asList(response.data).map(ChatRoom.fromJson).toList();
  }

  Future<void> enterRoom(String roomId) =>
      _dio.post<void>('/api/chat/rooms/$roomId/presence');

  Future<void> roomVoice(String roomId, bool enabled) {
    return _dio.post<void>(
      '/api/chat/rooms/$roomId/voice',
      data: <String, bool>{'enabled': enabled},
    );
  }

  Future<List<GiftType>> gifts() async {
    final response = await _dio.get<dynamic>('/api/gifts/types');
    return asList(response.data).map(GiftType.fromJson).toList();
  }

  Future<void> sendLiveGift(
    String streamId,
    String giftTypeId, {
    int quantity = 1,
  }) {
    return _dio.post<void>(
      '/api/video-streams/$streamId/gifts',
      data: <String, Object>{'giftTypeId': giftTypeId, 'quantity': quantity},
    );
  }

  Future<void> sendRoomGift(
    String roomId,
    String giftTypeId, {
    int quantity = 1,
  }) {
    return _dio.post<void>(
      '/api/chat/rooms/$roomId/gifts',
      data: <String, Object>{'giftTypeId': giftTypeId, 'quantity': quantity},
    );
  }

  Future<List<TrendItem>> trends() async {
    final response = await _dio.get<dynamic>(
      '/api/trends',
      queryParameters: <String, Object>{'limit': 20},
    );
    return asList(response.data).map(TrendItem.fromJson).toList();
  }

  Future<Map<String, dynamic>> coinInfo() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/jeton');
    return response.data ?? <String, dynamic>{};
  }
}

class FirebaseGateway {
  Future<void> configureIfAvailable() async {
    // Firebase project configuration files are environment-specific. The app
    // keeps this gateway isolated so Android/iOS builds do not crash when the
    // Firebase options are not shipped yet.
  }
}

class RealtimeGateway {
  Stream<String> connectNotifications() async* {
    // Backend WebSocket URL can be enabled here when production credentials are available.
  }
}
