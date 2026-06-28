import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/live_debug_log.dart';
import '../../../../core/util/json_util.dart';
import '../models/live_stream_dto.dart';
import '../../domain/entities/live_stream_chat_message.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../../domain/entities/voice_room_entity.dart';

class LiveRemoteDataSource {
  LiveRemoteDataSource(this._dio);

  final Dio _dio;

  static const int _pageSize = 30;

  Future<List<LiveStreamEntity>> fetch({int page = 1, String? category}) async {
    final query = <String, String>{
      'limit': '$_pageSize',
      'page': '$page',
      if (category != null && category.isNotEmpty) 'category': category,
    };
    if (Env.useMobileAuth) {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.videoStreams,
        query: query,
      );
      return _parseStreamList(res.data);
    }
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.liveStreams,
      query: {'page': page, 'limit': 30},
    );
    return _parseStreamList(res.data);
  }

  List<LiveStreamEntity> _parseStreamList(dynamic body) {
    dynamic list;
    if (body is Map<String, dynamic>) {
      if (body['success'] == true && body['data'] != null) {
        return _parseStreamList(body['data']);
      }
      list = pick(body, [
        'videoStreams',
        'streams',
        'items',
        'data',
        'results',
        'lives',
      ]);
    } else {
      list = body;
    }
    return asJsonList(list)
        .map((j) {
          final map = asJsonMap(j);
          final base = LiveStreamDto.fromApiMap(map).toEntity();
          final playback = LiveStreamDto.playbackUrlFrom(map);
          final tags = _parseTags(map);
          final isPk = _boolFlag(map, ['isPk', 'isPkLive', 'pkActive', 'inPk']);
          final isVip = _boolFlag(map, ['isVip', 'isVipHost', 'vipHost']);
          return LiveStreamEntity(
            id: base.id,
            title: base.title,
            streamerName: base.streamerName,
            thumbnailUrl: base.thumbnailUrl,
            category: base.category,
            viewerCount: base.viewerCount,
            isLive: base.isLive,
            hostUserId: base.hostUserId,
            playbackUrl: playback,
            tags: tags,
            isPkLive: isPk,
            isVipHost: isVip,
          );
        })
        .where((s) => s.id.isNotEmpty)
        .toList();
  }

  List<String> _parseTags(Map<String, dynamic> map) {
    final raw = pick(map, ['tags', 'labels']);
    if (raw is List) {
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    final single = pick(map, ['tag', 'subcategory'])?.toString();
    if (single != null && single.isNotEmpty) return [single];
    return const [];
  }

  bool _boolFlag(Map<String, dynamic> map, List<String> keys) {
    final v = pick(map, keys);
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }

  /// canlifal.com `/api/chat/rooms` — site ile aynı oda kartları.
  Future<List<VoiceRoomEntity>> fetchVoiceRooms() async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.chatRooms,
      query: const {'withCounts': 'true'},
    );
    final body = res.data;
    dynamic list = body;
    if (body is Map<String, dynamic>) {
      if (body['success'] == true && body['data'] != null) {
        final data = body['data'];
        list = data is Map ? pick(asJsonMap(data), ['rooms']) : data;
      } else {
        list = pick(body, ['rooms', 'items', 'data']) ?? body;
      }
    }
    if (list is! List) return const [];
    return asJsonList(list)
        .map(_mapVoiceRoom)
        .where((r) => r.apiRoomKey.isNotEmpty)
        .toList();
  }

  static const int voiceRoomNormalOpenJetonCost = 100;
  static const int voiceRoomVipOpenJetonCost = 5000;

  static int openRoomJetonCost({required bool vip, String? roomType}) {
    final t = roomType?.toLowerCase();
    if (t == 'free' || t == 'ucretsiz') return 0;
    return vip ? voiceRoomVipOpenJetonCost : voiceRoomNormalOpenJetonCost;
  }

  /// Web `roomType` enum — `FREE` | `NORMAL` | `VIP` (büyük harf).
  static String resolveRoomTypeEnum(String roomType, {bool vip = false}) {
    if (vip || roomType.toLowerCase() == 'vip') return 'VIP';
    switch (roomType.toLowerCase()) {
      case 'free':
      case 'ucretsiz':
      case 'ücretsiz':
        return 'FREE';
      case 'normal':
      case 'standard':
        return 'NORMAL';
      default:
        return 'NORMAL';
    }
  }

  /// Web ödeme yöntemi — `jeton` | `cfc` (küçük harf).
  static String normalizePaymentType(String? raw) {
    final v = raw?.trim().toLowerCase();
    if (v == 'cfc') return 'cfc';
    return 'jeton';
  }

  /// Üretim `POST /api/chat/rooms/create` — name, description ve icon zorunlu.
  static ({String name, String description, String icon}) voiceRoomCreateMetadata({
    required String roomType,
    String? roomName,
  }) {
    final t = roomType.toLowerCase();
    final isVip = t == 'vip';
    final isFree = t == 'free' || t == 'ucretsiz';
    final trimmed = roomName?.trim();
    final baseName =
        (trimmed != null && trimmed.isNotEmpty ? trimmed : 'Sohbet');
    final name = baseName.length > 40 ? baseName.substring(0, 40) : baseName;
    final description = isVip
        ? 'VIP sesli sohbet odası'
        : isFree
            ? 'Ücretsiz sesli sohbet odası'
            : 'Sesli sohbet odası';
    final icon = isVip ? '⭐' : isFree ? '🎙️' : '🎤';
    return (name: name, description: description, icon: icon);
  }

  /// Web ile birebir `POST /api/chat/rooms/create` gövdesi.
  static Map<String, dynamic> buildVoiceRoomCreatePayload({
    required String roomType,
    bool vip = false,
    String? roomName,
    String paymentType = 'jeton',
    String? description,
    String? icon,
  }) {
    final meta = voiceRoomCreateMetadata(
      roomType: roomType,
      roomName: roomName,
    );
    final desc = description?.trim();
    final ic = icon?.trim();
    return {
      'name': meta.name,
      'description':
          (desc != null && desc.isNotEmpty) ? desc : meta.description,
      'icon': (ic != null && ic.isNotEmpty) ? ic : meta.icon,
      'paymentType': normalizePaymentType(paymentType),
      'roomType': resolveRoomTypeEnum(roomType, vip: vip),
    };
  }

  /// canlifal.com `POST /api/chat/rooms/create` (yedek: `POST /api/chat/rooms`)
  Future<VoiceRoomEntity> createVoiceChatRoom({
    bool vip = false,
    String? roomType,
    String? roomName,
    String paymentType = 'jeton',
    String? description,
    String? icon,
  }) async {
    final resolvedType = roomType ?? (vip ? 'vip' : 'normal');
    final payload = buildVoiceRoomCreatePayload(
      roomType: resolvedType,
      vip: vip,
      roomName: roomName,
      paymentType: paymentType,
      description: description,
      icon: icon,
    );
    final name = payload['name']?.toString() ?? 'Sohbet';

    // safePost ApiException fırlatır, DioException değil — ApiException yakala.
    ApiException? lastError;
    for (final path in [ApiEndpoints.chatRoomCreate, ApiEndpoints.chatRooms]) {
      try {
        return await _postCreateVoiceRoom(path, payload, roomName: name);
      } on ApiException catch (e) {
        lastError = e;
        final code = e.statusCode ?? 0;
        if (code != 404 && code != 405) rethrow;
      }
    }
    throw lastError ??
        ApiException('Oda açılamadı — sunucu yanıt vermedi');
  }

  Future<VoiceRoomEntity> _postCreateVoiceRoom(
    String path,
    Map<String, dynamic> payload, {
    String? roomName,
  }) async {
    final name = roomName?.trim();
    final res = await _dio.safePost<dynamic>(
      path,
      data: payload,
      options: Options(
        contentType: Headers.jsonContentType,
        headers: const {'Accept': 'application/json'},
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    final body = res.data;
    if (body is String &&
        (body.contains('<!DOCTYPE') || body.contains('<html'))) {
      throw const ApiException('Oda açılamadı — oturum gerekli', statusCode: 401);
    }
    Map<String, dynamic>? map;
    if (body is Map<String, dynamic>) {
      map = body;
    } else if (body is Map) {
      map = Map<String, dynamic>.from(body);
    }
    if (map == null) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'Geçersiz oda oluşturma yanıtı',
      );
    }
    if (map['success'] == false) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: _formatCreateRoomError(map),
      );
    }
    final httpCode = res.statusCode ?? 0;
    if (map['success'] != true && httpCode != 201 && httpCode != 200) {
      final err = (map['error'] ?? map['message'])?.toString().trim();
      if (err != null && err.isNotEmpty) {
        throw DioException(
          requestOptions: res.requestOptions,
          message: err,
        );
      }
    }
    dynamic roomRaw = map['room'] ?? map['data'];
    if (roomRaw is Map) {
      final nested = asJsonMap(roomRaw);
      if (nested['room'] is Map) {
        roomRaw = nested['room'];
      } else if (!nested.containsKey('id') &&
          !nested.containsKey('slug') &&
          !nested.containsKey('roomId')) {
        final inner = pick(nested, ['room']);
        if (inner is Map) roomRaw = inner;
      }
    }
    if (roomRaw is Map) {
      final entity = _mapVoiceRoom(asJsonMap(roomRaw));
      if (entity.apiRoomKey.isNotEmpty) return entity;
    }
    if (map.containsKey('id') || map.containsKey('slug') || map.containsKey('roomId')) {
      final entity = _mapVoiceRoom(map);
      if (entity.apiRoomKey.isNotEmpty) return entity;
    }
    final topRoomId = pick(map, ['roomId', 'id', 'cuid'])?.toString().trim();
    if (topRoomId != null && topRoomId.isNotEmpty) {
      final fetched = await fetchVoiceRoomById(topRoomId);
      if (fetched != null && fetched.apiRoomKey.isNotEmpty) return fetched;
      return VoiceRoomEntity(
        id: topRoomId,
        slug: pick(map, ['slug'])?.toString() ?? topRoomId,
        nameTr: name?.trim().isNotEmpty == true ? name!.trim() : 'Sohbet Odası',
      );
    }
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Oda oluşturuldu ancak oda bilgisi alınamadı',
    );
  }

  static String _formatCreateRoomError(Map<String, dynamic> map) {
    final raw = map['error'] ?? map['message'] ?? map['detail'];
    final msg = raw?.toString().trim();
    if (msg != null && msg.isNotEmpty) {
      final lower = msg.toLowerCase();
      if (lower.contains('name') &&
          lower.contains('description') &&
          lower.contains('icon')) {
        return 'Oda adı, açıklama ve simge gerekli — lütfen tekrar deneyin.';
      }
      return msg;
    }
    return 'Oda açılamadı. Jeton bakiyenizi ve oturumunuzu kontrol edin.';
  }

  Future<VoiceRoomEntity?> fetchVoiceRoomById(String id) async {
    final needle = id.trim();
    if (needle.isEmpty) return null;

    try {
      final direct = await _fetchVoiceRoomDirect(needle);
      if (direct != null && direct.apiRoomKey.isNotEmpty) return direct;
    } catch (_) {}

    final rooms = await fetchVoiceRooms();
    final lower = needle.toLowerCase();
    String norm(String s) =>
        s.trim().toLowerCase().replaceAll(RegExp(r'-+$'), '');
    for (final r in rooms) {
      if (r.id == id ||
          r.slug == id ||
          r.id.toLowerCase() == lower ||
          r.slug.toLowerCase() == lower ||
          norm(r.slug) == norm(id) ||
          norm(r.id) == norm(id)) {
        return r;
      }
    }
    return null;
  }

  Future<VoiceRoomEntity?> _fetchVoiceRoomDirect(String id) async {
    final paths = [
      '/api/chat/rooms/$id',
      '${ApiEndpoints.chatRooms}/$id',
    ];
    for (final path in paths) {
      try {
        final res = await _dio.safeGet<dynamic>(path);
        final body = res.data;
        if (body is! Map) continue;
        final map = Map<String, dynamic>.from(body);
        if (map['success'] == false) continue;
        dynamic roomRaw = map['room'] ?? map['data'] ?? map;
        if (roomRaw is Map && roomRaw['room'] is Map) {
          roomRaw = roomRaw['room'];
        }
        if (roomRaw is Map) {
          final entity = _mapVoiceRoom(asJsonMap(roomRaw));
          if (entity.apiRoomKey.isNotEmpty) return entity;
        }
        if (map.containsKey('id') || map.containsKey('slug')) {
          final entity = _mapVoiceRoom(map);
          if (entity.apiRoomKey.isNotEmpty) return entity;
        }
      } on ApiException catch (e) {
        if (e.statusCode == 404) continue;
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) continue;
      }
    }
    return null;
  }

  Future<LiveStreamEntity?> fetchStream(String streamId) async {
    if (!Env.useMobileAuth) return null;
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.videoStream(streamId),
      );
      final body = res.data;
      if (body is Map<String, dynamic>) {
        final raw = body['stream'] ?? body['data'] ?? body;
        if (raw is Map) {
          return LiveStreamDto.fromApiMap(Map<String, dynamic>.from(raw))
              .toEntity();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<int> joinVideoStream(String streamId) async {
    LiveDebugLog.log('stream.join', {'streamId': streamId});
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamJoin(streamId),
    );
    final body = res.data;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final data = map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : map;
      return asInt(pick(data, ['viewerCount', 'viewers', 'watching']));
    }
    return 0;
  }

  Future<void> leaveVideoStream(String streamId) async {
    try {
      await _dio.safePost<dynamic>(ApiEndpoints.videoStreamLeave(streamId));
      LiveDebugLog.log('stream.leave', {'streamId': streamId});
    } catch (_) {}
  }

  Future<List<LiveStreamChatMessage>> fetchStreamMessages(
    String streamId, {
    DateTime? since,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.videoStreamMessages(streamId),
      query: since != null
          ? {'since': since.toUtc().toIso8601String()}
          : null,
    );
    return _parseStreamMessages(res.data);
  }

  Future<LiveStreamChatMessage?> sendStreamMessage({
    required String streamId,
    required String content,
  }) async {
    LiveDebugLog.log('stream.chat.send', {'streamId': streamId});
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamMessages(streamId),
      data: {'content': content.trim()},
    );
    final body = res.data;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final raw = map['message'] ?? map['data'];
      if (raw is Map) {
        return LiveStreamChatMessage.fromJson(
          Map<String, dynamic>.from(raw),
        );
      }
    }
    return null;
  }

  List<LiveStreamChatMessage> _parseStreamMessages(dynamic body) {
    dynamic list;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      if (map['success'] == true && map['data'] != null) {
        return _parseStreamMessages(map['data']);
      }
      list = pick(map, ['messages', 'items', 'data']);
    } else {
      list = body;
    }
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => LiveStreamChatMessage.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .where((m) => m.content.isNotEmpty)
        .toList();
  }

  Future<String> createVideoStream({
    required String title,
    String? description,
    String? category,
    List<String>? tags,
    String? thumbnailUrl,
    bool isPrivate = false,
    bool isImageMode = false,
    String? backgroundUrl,
  }) async {
    final started = DateTime.now();
    LiveDebugLog.log('create.request', {'title': title});
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreams,
      data: {
        'title': title,
        'name': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (category != null && category.isNotEmpty) 'category': category,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
          'thumbnailUrl': thumbnailUrl,
        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
          'coverUrl': thumbnailUrl,
        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
          'broadcastImage': thumbnailUrl,
        if (backgroundUrl != null && backgroundUrl.isNotEmpty)
          'backgroundUrl': backgroundUrl,
        'isPrivate': isPrivate,
        'private': isPrivate,
        'isImageMode': isImageMode,
        'requestType': 'live',
        'status': 'live',
      },
    );
    final streamId = _extractStreamId(res.data);
    if (streamId == null || streamId.isEmpty) {
      throw ApiException(
        'Yayın oluşturuldu ancak oda kimliği alınamadı. '
        'Yanıt: ${res.statusCode}',
      );
    }
    LiveDebugLog.log('create.ok', {
      'streamId': streamId,
      'elapsedMs': DateTime.now().difference(started).inMilliseconds,
    });
    return streamId;
  }

  /// Agora bağlandıktan sonra çağır — takipçilere push bildirimi.
  Future<int> notifyLiveStarted(String streamId) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.videoStreamLiveStarted(streamId),
        data: const {},
      );
      LiveDebugLog.log('live-started.ok', {'streamId': streamId});
      final body = res.data;
      if (body is Map) {
        return asInt(pick(Map<String, dynamic>.from(body), ['notifiedCount']));
      }
      return 0;
    } catch (e) {
      LiveDebugLog.log('live-started.fail', {
        'streamId': streamId,
        'reason': ApiException.userMessage(e),
      });
      rethrow;
    }
  }

  Future<void> updateVideoStream(
    String streamId, {
    String? title,
    String? description,
    String? broadcastImage,
    bool? isImageMode,
    String? backgroundUrl,
  }) async {
    await _dio.safePatch<dynamic>(
      ApiEndpoints.videoStream(streamId),
      data: {
        'title': ?title,
        'description': ?description,
        'broadcastImage': ?broadcastImage,
        'isImageMode': ?isImageMode,
        'backgroundUrl': ?backgroundUrl,
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchStreamViewers(String streamId) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.videoStreamViewers(streamId),
      );
      final body = res.data;
      dynamic list = body;
      if (body is Map) {
        list = pick(Map<String, dynamic>.from(body), ['viewers', 'items', 'data']) ?? body;
      }
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  String? _extractStreamId(dynamic body) {
    if (body is String && body.trim().isNotEmpty && !body.contains('<html')) {
      return body.trim();
    }
    Map<String, dynamic>? map;
    if (body is Map<String, dynamic>) {
      map = body;
    } else if (body is Map) {
      map = Map<String, dynamic>.from(body);
    }
    if (map == null) return null;
    if (map['success'] == true && map['data'] != null) {
      return _extractStreamId(map['data']);
    }
    final streamObj = map['stream'] ?? map['videoStream'] ?? map['broadcast'];
    if (streamObj is Map) {
      final nested = _extractStreamId(streamObj);
      if (nested != null) return nested;
    }
    final id = pick(map, ['id', '_id', 'streamId', 'roomId']);
    return id?.toString();
  }

  Future<void> endVideoStream(String streamId) async {
    try {
      await _dio.safePost<dynamic>(ApiEndpoints.videoStreamEnd(streamId));
    } catch (_) {
      await _dio.safeDelete<dynamic>('/api/video-streams/$streamId');
    }
  }

  VoiceRoomEntity _mapVoiceRoom(Map<String, dynamic> json) {
    final o = pick(json, ['owner']);
    String? ownerName;
    String? ownerAvatar;
    if (o is Map) {
      final om = asJsonMap(o);
      ownerName = jsonDisplayLabel(om);
      ownerAvatar = pick(om, ['image', 'avatar', 'avatarUrl'])?.toString();
    }
    final recent = <String>[];
    final ru = json['recentUsers'];
    if (ru is List) {
      for (final u in ru) {
        if (u is Map) {
          final m = asJsonMap(u);
          final img = pick(m, ['image', 'avatar'])?.toString();
          if (img != null && img.isNotEmpty) recent.add(img);
        }
      }
    }
    final djIds = <String>[];
    final djRaw = pick(json, ['djUserIds']);
    if (djRaw is List) {
      for (final id in djRaw) {
        if (id != null) djIds.add(id.toString());
      }
    } else if (djRaw is String && djRaw.startsWith('[')) {
      try {
        final decoded = djRaw
            .replaceAll('"', '')
            .replaceAll('[', '')
            .replaceAll(']', '')
            .split(',');
        for (final p in decoded) {
          final s = p.trim();
          if (s.isNotEmpty) djIds.add(s);
        }
      } catch (_) {}
    }
    final slug = pick(json, ['slug'])?.toString() ?? '';
    final rawId = pick(json, ['id', '_id', 'roomId', 'cuid'])?.toString() ?? '';
    final isVipRaw = pick(json, ['isVip', 'vip']);
    final isVip = isVipRaw == true ||
        isVipRaw == 1 ||
        isVipRaw == 'true' ||
        isVipRaw == '1';
    final roomType = pick(json, ['roomType', 'type'])?.toString();
    return VoiceRoomEntity(
      id: rawId,
      slug: slug,
      nameTr: pick(json, ['nameTr', 'nameEn', 'name', 'slug'])?.toString() ?? 'Oda',
      descTr: pick(json, ['descTr', 'descEn', 'description']) as String?,
      rulesTr: pick(json, ['rules', 'rulesTr', 'roomRules']) as String?,
      icon: pick(json, ['icon']) as String?,
      onlineCount: asInt(pick(json, ['onlineCount'])),
      userCount: asInt(pick(json, ['userCount'])),
      backgroundImageUrl: pick(json, ['backgroundImage']) as String?,
      ownerName: ownerName,
      ownerAvatarUrl: ownerAvatar,
      ownerId: pick(json, ['ownerId'])?.toString() ??
          (o is Map ? pick(asJsonMap(o), ['id'])?.toString() : null),
      activeDjId: pick(json, ['activeDjId'])?.toString(),
      djUserIds: djIds,
      recentUserAvatars: recent,
      isVip: isVip ? true : null,
      roomType: roomType,
    );
  }
}
