import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/home_banner_entity.dart';
import '../../domain/entities/home_fortune_card_entity.dart';
import '../../domain/entities/home_game_entity.dart';
import '../../domain/entities/home_trend_video_entity.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import '../../domain/entities/live_fortune_teller_entity.dart';
import '../../domain/entities/online_advisor_entity.dart';

class HomeRemoteDataSource {
  HomeRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<HomeBannerEntity>> fetchBanners() async {
    for (final path in [
      ApiEndpoints.homeBanners,
      ApiEndpoints.socialAnnouncements,
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(path);
        final items = _itemsFromBody(res.data);
        if (items.isNotEmpty) return items.map(_mapBanner).toList();
      } catch (_) {}
    }
    return const [];
  }

  Future<List<LiveFortuneTellerEntity>> fetchLiveFortuneTellers() async {
    for (final path in [
      ApiEndpoints.fortuneTellers,
      ApiEndpoints.homeAdvisorsOnline,
      ApiEndpoints.socialFortuneTellers,
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(path);
        final items = _itemsFromBody(res.data, keys: const [
          'items',
          'tellers',
          'advisors',
          'fortuneTellers',
          'data',
          'results',
        ]);
        if (items.isNotEmpty) {
          final tellers = items
              .map(_mapLiveFortuneTeller)
              .where((t) => t.id.isNotEmpty)
              .toList();
          tellers.sort((a, b) {
            if (a.isOnline != b.isOnline) {
              return a.isOnline ? -1 : 1;
            }
            return b.rating.compareTo(a.rating);
          });
          return tellers;
        }
      } catch (_) {}
    }
    return const [];
  }

  Future<FortuneSessionCreateResult?> createFortuneTellerSession(
    String tellerId, {
    String? tellerUserId,
    String? clientName,
    int? durationMinutes,
    int? totalJeton,
    String? fortuneType,
  }) async {
    final id = tellerId.trim();
    if (id.isEmpty) return null;
    final duration = durationMinutes ?? 10;
    final type = (fortuneType?.trim().isNotEmpty == true)
        ? fortuneType!.trim()
        : 'general';
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.fortuneTellerSession,
        data: {
          'tellerId': id,
          'fortuneType': type,
          'duration': duration,
          'fortuneTellerId': id,
          if (tellerUserId != null && tellerUserId.trim().isNotEmpty) ...{
            'tellerUserId': tellerUserId.trim(),
            'anchorUserId': tellerUserId.trim(),
          },
          if (clientName != null && clientName.trim().isNotEmpty)
            'clientName': clientName.trim(),
          'durationMinutes': duration,
          if (totalJeton != null) 'totalJeton': totalJeton,
        },
      );
      final body = res.data;
      if (body is! Map) return null;
      final map = asJsonMap(body);
      final data = map['data'] is Map ? asJsonMap(map['data']) : map;
      final sessionMap =
          data['session'] is Map ? asJsonMap(data['session']) : data;
      final sessionId = pick(data, ['sessionId', 'id', 'trtcRoomId'])
              ?.toString() ??
          pick(sessionMap, ['id', 'sessionId', 'trtcRoomId'])?.toString();
      final status = pick(data, ['status'])?.toString() ??
          pick(sessionMap, ['status'])?.toString() ??
          'pending';
      if (sessionId == null || sessionId.isEmpty) return null;
      final role = pick(data, ['role'])?.toString();
      final isClientRaw = data['isClient'];
      final isClient = isClientRaw is bool
          ? isClientRaw
          : role != 'teller';
      return FortuneSessionCreateResult(
        sessionId: sessionId,
        status: status,
        tellerUserId: pick(data, ['tellerUserId', 'anchorUserId'])?.toString() ??
            pick(sessionMap, ['tellerUserId'])?.toString(),
        clientId: pick(data, ['clientId'])?.toString() ??
            pick(sessionMap, ['clientId'])?.toString(),
        role: role,
        isClient: isClient,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<FortuneIncomingSession>> fetchIncomingFortuneSessions({
    String? currentUserId,
    String? tellerProfileId,
  }) async {
    final merged = <FortuneIncomingSession>[];
    final seen = <String>{};

    void addAll(List<FortuneIncomingSession> rows) {
      for (final row in rows) {
        if (seen.add(row.sessionId)) merged.add(row);
      }
    }

    try {
      addAll(await fetchLiveFalPending());
    } catch (_) {}

    for (final path in [
      ApiEndpoints.fortuneTellerSessionsWithStatus('pending'),
      ApiEndpoints.fortuneTellerSessions,
      ApiEndpoints.fortuneTellerIncomingSessions,
    ]) {
      try {
        addAll(await _fetchFortuneSessionsFromPath(path));
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 405) continue;
      } catch (_) {}
    }

    return _filterTellerIncoming(
      merged,
      currentUserId,
      tellerProfileId: tellerProfileId,
    );
  }

  /// `GET /api/live-fal/pending` — bekleyen canlı fal istekleri.
  Future<List<FortuneIncomingSession>> fetchLiveFalPending() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.liveFalPending);
      final body = res.data;
      if (body is List) {
        return body
            .map(_mapIncomingFortuneSession)
            .where((s) => s.sessionId.isNotEmpty)
            .toList(growable: false);
      }
      if (body is! Map) return const [];
      final map = asJsonMap(body);
      final data = map['data'] is Map ? asJsonMap(map['data']) : map;
      final raw = data['pending'] ??
          data['requests'] ??
          data['items'] ??
          data['sessions'] ??
          [];
      if (raw is! List) return const [];
      return raw
          .map(_mapIncomingFortuneSession)
          .where((s) => s.sessionId.isNotEmpty)
          .toList(growable: false);
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) return const [];
      rethrow;
    }
  }

  /// `POST /api/live-fal/request/{requestId}/accept`
  Future<bool> acceptLiveFalRequest(String requestId) async {
    final key = requestId.trim();
    if (key.isEmpty) return false;
    try {
      await _dio.safePost<dynamic>(ApiEndpoints.liveFalRequestAccept(key));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// `POST /api/live-fal/request/{requestId}/reject`
  Future<bool> rejectLiveFalRequest(String requestId) async {
    final key = requestId.trim();
    if (key.isEmpty) return false;
    try {
      await _dio.safePost<dynamic>(ApiEndpoints.liveFalRequestReject(key));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Falcı uygulamadayken web ile aynı «çevrimiçi» durumu.
  Future<bool> setFortuneTellerOnline({bool online = true}) async {
    final body = {'online': online, 'isOnline': online};
    for (final call in [
      () => _dio.safePost<dynamic>(
            ApiEndpoints.fortuneTellerToggleOnline,
            data: body,
          ),
      () => _dio.safePatch<dynamic>(
            '/api/fortune-tellers/toggle',
            data: body,
          ),
      () => _dio.safePost<dynamic>(
            '/api/fortune-tellers/toggle',
            data: body,
          ),
    ]) {
      try {
        await call();
        return true;
      } catch (_) {}
    }
    return false;
  }

  Future<LiveFortuneTellerEntity?> fetchMyFortuneTellerProfile() async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.fortuneTellerMyProfile,
      );
      final body = res.data;
      if (body is! Map) return null;
      final map = asJsonMap(body);
      final data = map['data'] is Map ? asJsonMap(map['data']) : map;
      final teller = data['teller'] ?? data['fortuneTeller'] ?? data;
      return _mapLiveFortuneTeller(teller);
    } catch (_) {
      return null;
    }
  }

  Future<FortuneSessionStatusResult?> fetchFortuneSessionStatus(
    String sessionId,
  ) async {
    final key = sessionId.trim();
    if (key.isEmpty) return null;

    final fromGet = await _fetchFortuneSessionStatusDirect(key);
    if (fromGet != null) return fromGet;

    for (final path in [
      ApiEndpoints.fortuneTellerSessions,
      ApiEndpoints.fortuneTellerIncomingSessions,
    ]) {
      try {
        final sessions = await _fetchFortuneSessionsFromPath(path);
        for (final row in sessions) {
          if (row.sessionId == key) {
            return _statusFromIncoming(row);
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Future<bool> respondFortuneSession(
    String sessionId, {
    required String action,
  }) async {
    final key = sessionId.trim();
    if (key.isEmpty) return false;
    final normalized = action.trim().toLowerCase();
    if (normalized == 'accept') {
      final ok = await acceptLiveFalRequest(key);
      if (ok) return true;
    } else if (normalized == 'reject' || normalized == 'decline') {
      final ok = await rejectLiveFalRequest(key);
      if (ok) return true;
    } else if (normalized == 'hold') {
      // Üretim: PATCH ile beklet.
    }
    try {
      await _dio.safePatch<dynamic>(
        ApiEndpoints.fortuneTellerSessionPatch(key),
        data: {'action': normalized},
      );
      return true;
    } catch (_) {}
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.fortuneTellerSessionRespond(key),
        data: {'action': normalized},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> endFortuneSession(String sessionId) async {
    final key = sessionId.trim();
    if (key.isEmpty) return false;
    final roomEnded = await roomAction(key, 'end');
    if (roomEnded != null) return true;
    for (final action in const ['end', 'leave', 'cancel', 'complete']) {
      final ok = await respondFortuneSession(key, action: action);
      if (ok) return true;
    }
    return false;
  }

  /// Falcıya bahşiş — `POST /api/teller/gifts`.
  Future<bool> sendTellerTip({
    required String sessionId,
    required int amount,
    String? tellerId,
    String? tellerUserId,
  }) async {
    final key = sessionId.trim();
    if (key.isEmpty || amount <= 0) return false;
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.tellerGifts,
        data: {
          'sessionId': key,
          'amount': amount,
          'jeton': amount,
          'coins': amount,
          if (tellerId != null) 'tellerId': tellerId,
          if (tellerUserId != null) 'tellerUserId': tellerUserId,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Seans süresi uzatma — önce `PATCH /api/room/{id}` (`extend`).
  Future<bool> extendFortuneSession({
    required String sessionId,
    required int minutes,
    required int totalJeton,
  }) async {
    final key = sessionId.trim();
    if (key.isEmpty || minutes <= 0) return false;
    final roomResult = await roomAction(
      key,
      'extend',
      extra: {'minutes': minutes},
    );
    if (roomResult != null) return true;
    try {
      await _dio.safePatch<dynamic>(
        ApiEndpoints.fortuneTellerSessionPatch(key),
        data: {
          'action': 'extend',
          'durationMinutes': minutes,
          'minutes': minutes,
          'totalJeton': totalJeton,
          'jeton': totalJeton,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Falcı kullanıcı jetonundan süre ekler — `PATCH /api/room/{id}`.
  Future<bool> tellerAddSessionTime({
    required String sessionId,
    required int minutes,
  }) async {
    final key = sessionId.trim();
    if (key.isEmpty || minutes <= 0) return false;
    final result = await roomAction(
      key,
      'teller_add_time',
      extra: {'minutes': minutes},
    );
    return result != null;
  }

  /// `GET /api/room/{sessionId}` — oda + timer bilgisi.
  Future<LiveFortuneRoomInfo?> fetchRoomInfo(String sessionId) async {
    final key = sessionId.trim();
    if (key.isEmpty) return null;
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.liveFortuneRoom(key));
      final body = res.data;
      if (body is! Map) return null;
      final map = asJsonMap(body);
      final data = map['data'] is Map ? asJsonMap(map['data']) : map;
      return _mapRoomInfo(data, fallbackId: key);
    } catch (_) {
      return null;
    }
  }

  /// `PATCH /api/room/{sessionId}` — start_timer, ping, extend, end vb.
  Future<Map<String, dynamic>?> roomAction(
    String sessionId,
    String action, {
    Map<String, dynamic>? extra,
  }) async {
    final key = sessionId.trim();
    final act = action.trim().toLowerCase();
    if (key.isEmpty || act.isEmpty) return null;
    try {
      final res = await _dio.safePatch<dynamic>(
        ApiEndpoints.liveFortuneRoom(key),
        data: {
          'action': act,
          if (extra != null) ...extra,
        },
      );
      final body = res.data;
      if (body is Map) {
        final map = asJsonMap(body);
        return map['data'] is Map ? asJsonMap(map['data']) : map;
      }
      return <String, dynamic>{};
    } catch (_) {
      return null;
    }
  }

  Future<List<TellerChatMessage>> fetchRoomMessages(
    String sessionId, {
    String? afterIso,
    String? myUserId,
  }) async {
    final key = sessionId.trim();
    if (key.isEmpty) return const [];
    try {
      final path = afterIso != null && afterIso.isNotEmpty
          ? '${ApiEndpoints.liveFortuneRoomMessages(key)}?after=${Uri.encodeComponent(afterIso)}'
          : ApiEndpoints.liveFortuneRoomMessages(key);
      final res = await _dio.safeGet<dynamic>(path);
      final items = _itemsFromBody(res.data, keys: const [
        'messages',
        'items',
        'data',
      ]);
      return items
          .map((raw) => _mapRoomChatMessage(raw, myUserId: myUserId))
          .where((m) => m.text.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<bool> sendRoomMessage(String sessionId, String text) async {
    final key = sessionId.trim();
    final message = text.trim();
    if (key.isEmpty || message.isEmpty) return false;
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.liveFortuneRoomMessages(key),
        data: {'message': message},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<TellerChatMessage>> fetchTellerChatMessages(
    String sessionId, {
    String? myUserId,
    String? afterIso,
  }) async {
    final roomMessages = await fetchRoomMessages(
      sessionId,
      afterIso: afterIso,
      myUserId: myUserId,
    );
    if (roomMessages.isNotEmpty) return roomMessages;

    final key = sessionId.trim();
    if (key.isEmpty) return const [];
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.tellerChat(key));
      final items = _itemsFromBody(res.data, keys: const [
        'messages',
        'items',
        'chat',
        'data',
      ]);
      return items
          .map((raw) => _mapTellerChatMessage(raw, myUserId: myUserId))
          .where((m) => m.text.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<bool> sendTellerChatMessage(String sessionId, String text) async {
    final key = sessionId.trim();
    final message = text.trim();
    if (key.isEmpty || message.isEmpty) return false;
    final roomOk = await sendRoomMessage(key, message);
    if (roomOk) return true;
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.tellerChat(key),
        data: {
          'message': message,
          'text': message,
          'content': message,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<FortuneIncomingSession>> _fetchFortuneSessionsFromPath(
    String path,
  ) async {
    final res = await _dio.safeGet<dynamic>(path);
    final body = res.data;
    if (body is List) {
      return body
          .map(_mapIncomingFortuneSession)
          .where((s) => s.sessionId.isNotEmpty)
          .toList(growable: false);
    }
    if (body is! Map) return const [];
    final map = asJsonMap(body);
    final data = map['data'] is Map ? asJsonMap(map['data']) : map;
    final raw = data['sessions'] ??
        data['items'] ??
        data['incoming'] ??
        data['pending'] ??
        data['requests'] ??
        data['fortuneSessions'] ??
        data['pendingSessions'] ??
        data['incomingRequests'] ??
        data['liveSessions'] ??
        data['pendingRequests'] ??
        [];
    if (raw is List && raw.isNotEmpty) {
      return raw
          .map(_mapIncomingFortuneSession)
          .where((s) => s.sessionId.isNotEmpty)
          .toList(growable: false);
    }
    if (data.containsKey('id') || data.containsKey('sessionId')) {
      final one = _mapIncomingFortuneSession(data);
      if (one.sessionId.isNotEmpty) return [one];
    }
    return const [];
  }

  List<FortuneIncomingSession> _filterTellerIncoming(
    List<FortuneIncomingSession> sessions,
    String? currentUserId, {
    String? tellerProfileId,
  }) {
    final uid = currentUserId?.trim() ?? '';
    final profileId = tellerProfileId?.trim() ?? '';
    return sessions.where((session) {
      if (!_isPendingFortuneInvite(session)) return false;
      if (uid.isEmpty) return true;
      if (session.clientId == uid) return false;
      if (session.tellerUserId == uid) return true;
      if (session.tellerId == uid) return true;
      if (profileId.isNotEmpty && session.tellerId == profileId) return true;
      // Sunucu zaten falcıya filtrelediyse teller alanları boş gelebilir.
      if (session.tellerUserId == null &&
          session.tellerId.isEmpty &&
          session.clientId.isNotEmpty &&
          session.clientId != uid) {
        return true;
      }
      return false;
    }).toList(growable: false);
  }

  Future<FortuneSessionStatusResult?> _fetchFortuneSessionStatusDirect(
    String sessionId,
  ) async {
    for (final path in [
      ApiEndpoints.fortuneTellerSessionQuery(sessionId),
      ApiEndpoints.fortuneTellerSessionStatus(sessionId),
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(path);
        final body = res.data;
        if (body is! Map) continue;
        final map = asJsonMap(body);
        final data = map['data'] is Map ? asJsonMap(map['data']) : map;
        final sessionMap =
            data['session'] is Map ? asJsonMap(data['session']) : data;
        final status = _statusFromSessionMaps(data, sessionMap);
        if (status != null) return status;
      } catch (_) {}
    }

    final room = await fetchRoomInfo(sessionId);
    if (room == null) return null;
    return FortuneSessionStatusResult(
      sessionId: room.sessionId,
      status: room.status,
      tellerResponse: room.status == 'active' ? 'accepted' : 'pending',
      isClient: room.isUser,
      trtcRoomId: room.roomId,
      durationMinutes: room.maxMinutes,
    );
  }

  FortuneSessionStatusResult? _statusFromSessionMaps(
    Map<String, dynamic> data,
    Map<String, dynamic> sessionMap,
  ) {
    final id = pick(data, ['sessionId', 'id'])?.toString() ??
        pick(sessionMap, ['id', 'sessionId'])?.toString();
    if (id == null || id.isEmpty) return null;
    final status = pick(data, ['status'])?.toString() ??
        pick(sessionMap, ['status'])?.toString() ??
        'pending';
    final tellerResponse = pick(data, ['tellerResponse', 'response'])?.toString() ??
        pick(sessionMap, ['tellerResponse', 'response'])?.toString() ??
        'pending';
    final isClientRaw = data['isClient'];
    final isClient = isClientRaw is bool ? isClientRaw : true;
    return FortuneSessionStatusResult(
      sessionId: id,
      status: status,
      tellerResponse: tellerResponse,
      isClient: isClient,
      tellerUserId: pick(data, ['tellerUserId', 'anchorUserId'])?.toString() ??
          pick(sessionMap, ['tellerUserId', 'anchorUserId'])?.toString(),
      trtcRoomId: pick(data, ['trtcRoomId', 'roomId'])?.toString() ??
          pick(sessionMap, ['trtcRoomId', 'roomId'])?.toString(),
      durationMinutes: asInt(
        pick(data, ['durationMinutes', 'maxMinutes', 'duration']) ??
            pick(sessionMap, ['durationMinutes', 'maxMinutes', 'duration']),
      ),
      totalJeton: asInt(
        pick(data, ['totalJeton', 'creditsCharged']) ??
            pick(sessionMap, ['totalJeton', 'creditsCharged']),
      ),
    );
  }

  FortuneSessionStatusResult _statusFromIncoming(FortuneIncomingSession row) {
    return FortuneSessionStatusResult(
      sessionId: row.sessionId,
      status: row.status,
      tellerResponse: row.tellerResponse,
      isClient: true,
      durationMinutes: row.durationMinutes,
      totalJeton: row.totalJeton,
    );
  }

  bool _isPendingFortuneInvite(FortuneIncomingSession session) {
    final status = session.status.toLowerCase();
    final response = session.tellerResponse.toLowerCase();
    if (response == 'accepted' ||
        response == 'rejected' ||
        response == 'declined' ||
        response == 'cancelled') {
      return false;
    }
    if (status == 'active' ||
        status == 'ended' ||
        status == 'completed' ||
        status == 'cancelled' ||
        status == 'rejected') {
      return false;
    }
    return response.isEmpty ||
        response == 'pending' ||
        response == 'held' ||
        response == 'waiting' ||
        response == 'requested' ||
        status == 'pending' ||
        status == 'waiting' ||
        status == 'requested' ||
        status == 'new' ||
        status == 'open';
  }

  TellerChatMessage _mapTellerChatMessage(
    dynamic raw, {
    String? myUserId,
  }) {
    final m = asJsonMap(raw);
    final sender = asJsonMap(m['sender'] ?? m['user'] ?? m['from']);
    final senderId = _str(m, ['senderId', 'userId', 'fromId']) ??
        _str(sender, ['id', 'userId']) ??
        '';
    final senderName = _str(m, ['senderName', 'userName', 'displayName']) ??
        _str(sender, ['displayName', 'name', 'username']) ??
        'Kullanıcı';
    final text = _str(m, ['text', 'message', 'content', 'body']) ?? '';
    final createdRaw = pick(m, ['createdAt', 'sentAt', 'timestamp'])?.toString();
    DateTime? createdAt;
    if (createdRaw != null && createdRaw.isNotEmpty) {
      createdAt = DateTime.tryParse(createdRaw);
    }
    return TellerChatMessage(
      id: _str(m, ['id', '_id']) ?? '${senderId}_${createdRaw ?? text.hashCode}',
      senderId: senderId,
      senderName: senderName,
      text: text,
      createdAt: createdAt,
      isMine: myUserId != null && senderId.isNotEmpty && senderId == myUserId,
    );
  }

  TellerChatMessage _mapRoomChatMessage(
    dynamic raw, {
    String? myUserId,
  }) {
    return _mapTellerChatMessage(raw, myUserId: myUserId);
  }

  LiveFortuneRoomInfo? _mapRoomInfo(
    Map<String, dynamic> data, {
    required String fallbackId,
  }) {
    final id = _str(data, ['id', 'sessionId']) ?? fallbackId;
    if (id.isEmpty) return null;
    final timerRaw = pick(data, ['timerStartedAt'])?.toString();
    DateTime? timerStartedAt;
    if (timerRaw != null && timerRaw.isNotEmpty) {
      timerStartedAt = DateTime.tryParse(timerRaw);
    }
    final user = asJsonMap(data['user']);
    return LiveFortuneRoomInfo(
      sessionId: id,
      status: _str(data, ['status']) ?? 'active',
      maxMinutes: () {
        final v = asInt(pick(data, ['maxMinutes', 'durationMinutes', 'duration']));
        return v > 0 ? v : 10;
      }(),
      timerStarted: data['timerStarted'] == true,
      roomId: _str(data, ['roomId', 'trtcRoomId']),
      timerStartedAt: timerStartedAt,
      elapsedSeconds: asInt(pick(data, ['elapsedSeconds'])),
      minutesUsed: asInt(pick(data, ['minutesUsed'])),
      creditsPerMinute: () {
        final v = asInt(pick(data, ['creditsPerMinute']));
        return v > 0 ? v : 10;
      }(),
      peerId: _str(data, ['peerId']),
      isUser: data['isUser'] == true || data['isTeller'] != true,
      isTeller: data['isTeller'] == true,
      userJetonBalance: asInt(pick(user, ['jetonBalance'])),
    );
  }

  FortuneIncomingSession _mapIncomingFortuneSession(dynamic raw) {
    final m = asJsonMap(raw);
    final client = asJsonMap(m['client'] ?? m['user'] ?? m['clientUser']);
    final teller = asJsonMap(m['teller'] ?? m['fortuneTeller']);
    final accepted = m['accepted'] == true || m['isAccepted'] == true;
    final rejected = m['rejected'] == true || m['isRejected'] == true;
    var status = _str(m, ['status']) ?? 'pending';
    var tellerResponse =
        _str(m, ['tellerResponse', 'response', 'tellerStatus']) ?? 'pending';
    if (accepted) {
      status = 'active';
      tellerResponse = 'accepted';
    } else if (rejected) {
      status = 'ended';
      tellerResponse = 'rejected';
    }
    return FortuneIncomingSession(
      sessionId: _str(m, ['requestId', 'id', 'sessionId']) ?? '',
      clientId: _str(m, ['clientId']) ??
          _str(client, ['id', 'userId']) ??
          '',
      clientName: _str(m, ['clientName', 'clientDisplayName', 'userName']) ??
          _str(client, ['displayName', 'name', 'username']) ??
          'Danışan',
      tellerId: _str(m, ['tellerId', 'fortuneTellerId']) ??
          _str(teller, ['id', 'tellerId']) ??
          '',
      tellerUserId: _str(m, ['tellerUserId', 'anchorUserId']) ??
          _str(teller, ['userId', 'tellerUserId']) ??
          null,
      durationMinutes: () {
        final v = asInt(
          pick(m, ['durationMinutes', 'maxMinutes', 'minutes', 'duration']),
        );
        return v > 0 ? v : 10;
      }(),
      totalJeton: asInt(
        pick(m, [
          'totalJeton',
          'jeton',
          'amount',
          'cost',
          'tokenAmount',
          'creditsCharged',
        ]),
      ),
      category: _str(m, ['category', 'specialty', 'fortuneType', 'falType']) ??
          _str(teller, ['specialty']) ??
          'general',
      status: status,
      tellerResponse: tellerResponse,
    );
  }

  Future<LiveFortuneTellerEntity?> fetchLiveFortuneTeller(String id) async {
    final key = id.trim();
    if (key.isEmpty) return null;
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.fortuneTeller(key));
      final body = res.data;
      if (body is Map) {
        final map = asJsonMap(body);
        final data = map['data'] is Map ? asJsonMap(map['data']) : map;
        final teller = data['teller'] ?? data['fortuneTeller'] ?? data;
        return _mapLiveFortuneTeller(teller);
      }
    } catch (_) {}
    final list = await fetchLiveFortuneTellers();
    for (final t in list) {
      if (t.id == key) return t;
    }
    return null;
  }

  Future<List<OnlineAdvisorEntity>> fetchOnlineAdvisors() async {
    final tellers = await fetchLiveFortuneTellers();
    if (tellers.isNotEmpty) {
      return tellers
          .map(
            (t) => OnlineAdvisorEntity(
              id: t.id,
              name: t.name,
              category: t.displayCategory,
              avatarUrl: t.avatarUrl,
              isOnline: t.isOnline,
              rating: t.rating,
              viewerCount: t.reviewCount,
              specialties: t.specialties,
            ),
          )
          .toList();
    }
    return const [];
  }

  Future<List<HomeGameEntity>> fetchGames() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.homeGames);
      final items = _itemsFromBody(res.data);
      if (items.isNotEmpty) {
        return items.map(_mapGame).where((g) => g.id.isNotEmpty).toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<List<DailyRewardEntity>> fetchDailyRewards() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.homeDailyRewards);
      final items = _itemsFromBody(res.data);
      return items.map(_mapDailyReward).where((r) => r.id.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<HomeTrendVideoEntity>> fetchTrendVideos() async {
    // Öncelik: kullanıcıların yüklediği kısa videolar (R2/CDN).
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.shortVideos,
        query: {'limit': 12},
      );
      final shorts = _shortVideosFromBody(res.data)
          .map(_mapShortVideoToTrend)
          .where((v) => v.id.isNotEmpty && !v.isYoutubeSource)
          .toList();
      if (shorts.isNotEmpty) return shorts;
    } catch (_) {}

    // Eski trend-videos: YouTube kaynaklarını gösterme.
    for (final path in [ApiEndpoints.trendVideos]) {
      try {
        final res = await _dio.safeGet<dynamic>(path);
        final items = _itemsFromBody(
          res.data,
          keys: const ['videos', 'items', 'posts', 'data', 'results'],
        );
        if (items.isNotEmpty) {
          return items
              .map(_mapTrendVideo)
              .where((v) => v.id.isNotEmpty && !v.isYoutubeSource)
              .toList();
        }
      } catch (_) {}
    }
    return const [];
  }

  List<dynamic> _shortVideosFromBody(dynamic body) {
    if (body is! Map) return const [];
    final m = asJsonMap(body);
    final data = m['success'] == true && m['data'] is Map
        ? asJsonMap(m['data'])
        : m;
    final raw = data['videos'];
    if (raw is List) return raw;
    return const [];
  }

  HomeTrendVideoEntity _mapShortVideoToTrend(dynamic raw) {
    final m = asJsonMap(raw);
    final authorRaw = pick(m, ['author', 'user']);
    var channel = 'Canlifal';
    if (authorRaw is Map) {
      final am = asJsonMap(authorRaw);
      channel = _str(am, ['displayName', 'username', 'name']) ?? channel;
    }
    final desc = _str(m, ['description', 'caption'])?.trim();
    final dur = pick(m, ['durationSec', 'duration_sec']);
    var durationStr = '';
    if (dur is num && dur > 0) {
      final sec = dur.round();
      final m = sec ~/ 60;
      final s = sec % 60;
      durationStr = '$m:${s.toString().padLeft(2, '0')}';
    }
    return HomeTrendVideoEntity(
      id: _str(m, ['id', '_id']) ?? '',
      title: (desc != null && desc.isNotEmpty) ? desc : channel,
      channelName: channel,
      thumbnailUrl: _str(m, ['thumbnailUrl', 'thumbnail_url', 'thumbnail']),
      duration: durationStr,
      viewCount: asInt(pick(m, ['viewsCount', 'views_count', 'viewCount'])),
      videoUrl: _str(m, ['videoUrl', 'video_url']),
      badge: 'YENİ',
    );
  }

  Future<int?> fetchUnreadNotifications() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.notificationsUnread);
      final map = asJsonMap(res.data);
      final data = map['data'] is Map ? asJsonMap(map['data']) : map;
      final countRaw = pick(data, ['count', 'unread', 'unreadCount']);
      if (countRaw != null) return asInt(countRaw);
    } catch (_) {}
    if (Env.useMobileAuth) {
      try {
        final res = await _dio.safeGet<dynamic>(
          ApiEndpoints.messages,
          query: {'unreadCount': 'true'},
        );
        final map = asJsonMap(res.data);
        final countRaw = pick(map, ['unreadCount', 'count', 'unread']);
        if (countRaw != null) return asInt(countRaw);
      } catch (_) {}
    }
    return null;
  }

  List<dynamic> _itemsFromBody(
    dynamic body, {
    List<String> keys = const ['items', 'banners', 'data', 'results'],
  }) {
    if (body is List) return body;
    if (body is! Map) return const [];
    final map = asJsonMap(body);
    if (map['success'] == true && map['data'] != null) {
      final data = map['data'];
      if (data is List) return data;
      if (data is Map) {
        for (final k in keys) {
          final v = data[k];
          if (v is List) return v;
        }
      }
    }
    for (final k in keys) {
      final v = map[k];
      if (v is List) return v;
    }
    return const [];
  }

  HomeBannerEntity _mapBanner(dynamic raw) {
    final m = asJsonMap(raw);
    final gradientRaw = m['gradient'];
    List<int> gradient = const [0xFF2A1548, 0xFF7B4DFF];
    if (gradientRaw is List && gradientRaw.length >= 2) {
      gradient = gradientRaw
          .take(2)
          .map((e) => _parseColorInt(e) ?? 0xFF7B4DFF)
          .toList();
    }
    final actionsRaw = m['quickActions'] ?? m['actions'];
    final actions = <HomeBannerQuickAction>[];
    if (actionsRaw is List) {
      for (final a in actionsRaw) {
        final am = asJsonMap(a);
        final id = _str(am, ['id', 'slug']) ?? '';
        if (id.isEmpty) continue;
        actions.add(
          HomeBannerQuickAction(
            id: id,
            label: _str(am, ['label', 'title', 'name']) ?? id,
            route: _str(am, ['route', 'path', 'href']),
          ),
        );
      }
    }
    return HomeBannerEntity(
      id: _str(m, ['id', '_id']) ?? '',
      title: _str(m, ['title', 'headline', 'name']) ?? 'CanlıFal',
      subtitle: _str(m, ['subtitle', 'body', 'description']),
      ctaLabel: _str(m, ['ctaLabel', 'cta', 'buttonLabel']),
      ctaRoute: _str(m, ['ctaRoute', 'ctaPath', 'link', 'url']),
      imageUrl: _str(m, ['imageUrl', 'image', 'thumbnailUrl', 'icon']),
      gradient: gradient,
      quickActions: actions,
    );
  }

  LiveFortuneTellerEntity _mapLiveFortuneTeller(dynamic raw) {
    final m = asJsonMap(raw);
    final user = asJsonMap(m['user'] ?? m['profile']);
    final online = m['isOnline'] == true ||
        m['online'] == true ||
        m['status']?.toString().toLowerCase() == 'online' ||
        m['canGoOnline'] == true;
    final specs = _stringList(m['specialties'] ?? m['tags'] ?? user['specialties']);
    final profileId = _str(m, ['id', '_id', 'tellerId']) ??
        _str(user, ['tellerId']) ??
        '';
    final userId = _str(m, ['userId', 'tellerUserId', 'ownerId', 'uid']) ??
        _str(user, ['id', 'userId']);
    return LiveFortuneTellerEntity(
      id: profileId.isNotEmpty ? profileId : (userId ?? ''),
      userId: userId,
      name: _str(m, ['displayName', 'name', 'username']) ??
          _str(user, ['displayName', 'name', 'username']) ??
          'Falcı',
      bio: _str(m, ['bio', 'description', 'about']) ?? _str(user, ['bio']),
      avatarUrl: _str(m, [
            'avatarUrl',
            'image',
            'avatar',
            'photoUrl',
            'profileImage',
          ]) ??
          _str(user, ['avatarUrl', 'image', 'avatar']),
      isOnline: online,
      rating: _dbl(m, ['rating', 'score', 'averageRating']) != 0
          ? _dbl(m, ['rating', 'score', 'averageRating'])
          : _dbl(user, ['rating', 'score']),
      reviewCount: asInt(
        pick(m, ['reviewCount', 'reviews', 'totalReviews', 'viewerCount']),
      ),
      pricePerMinute: asInt(
        pick(m, [
          'pricePerMinute',
          'pricePerSession',
          'sessionPrice',
          'price',
          'minutePrice',
        ]),
      ),
      level: _str(m, ['level', 'tier', 'tellerLevel']),
      specialties: specs,
      category: _advisorCategory(m) ?? _advisorCategory(user),
    );
  }

  OnlineAdvisorEntity _mapAdvisor(dynamic raw) {
    final m = asJsonMap(raw);
    final online = m['isOnline'] == true ||
        m['online'] == true ||
        m['status'] == 'online';
    return OnlineAdvisorEntity(
      id: _str(m, ['id', '_id', 'userId']) ?? '',
      name: _str(m, ['name', 'displayName', 'username']) ?? 'Falcı',
      category: _advisorCategory(m),
      avatarUrl: _str(m, ['avatarUrl', 'image', 'avatar', 'photoUrl']),
      isOnline: online,
      rating: _dbl(m, ['rating', 'score']),
      viewerCount: asInt(pick(m, ['viewerCount', 'viewers', 'audience'])),
      specialties: _stringList(m['specialties']),
    );
  }

  HomeGameEntity _mapGame(dynamic raw) {
    final m = asJsonMap(raw);
    return HomeGameEntity(
      id: _str(m, ['id', 'slug']) ?? '',
      title: _str(m, ['title', 'name', 'label']) ?? '',
      icon: _str(m, ['icon', 'emoji']),
      route: _str(m, ['route', 'path', 'deepLink']),
      accentColorArgb: _parseColorInt(m['accentColor'] ?? m['color']),
    );
  }

  HomeTrendVideoEntity _mapTrendVideo(dynamic raw) {
    final m = asJsonMap(raw);
    final badges = ['POPÜLER', 'EZEL', 'YENİ', 'TREND'];
    final idx = m.hashCode.abs() % badges.length;
    final videoUrl = _str(m, [
      'videoUrl',
      'video_url',
      'playbackUrl',
      'url',
      'youtubeUrl',
    ]);
    return HomeTrendVideoEntity(
      id: _str(m, ['id', '_id']) ?? '',
      title: _str(m, ['title', 'name', 'content']) ?? 'Video',
      channelName: _str(m, ['channelName', 'author', 'username']) ??
          _str(asJsonMap(m['channel'] ?? m['celebrity']), ['name', 'displayName']) ??
          'Canlifal',
      thumbnailUrl: _str(m, [
        'thumbnailUrl',
        'thumbnail',
        'imageUrl',
        'coverUrl',
        'image',
      ]),
      duration: _str(m, ['duration', 'length']) ?? '0:30',
      badge: _str(m, ['badge', 'tag', 'label']) ?? badges[idx],
      viewCount: asInt(pick(m, ['viewCount', 'views', 'viewers'])),
      videoUrl: videoUrl,
    );
  }

  DailyRewardEntity _mapDailyReward(dynamic raw) {
    final m = asJsonMap(raw);
    return DailyRewardEntity(
      id: _str(m, ['id']) ?? '',
      title: _str(m, ['title', 'name']) ?? '',
      description: _str(m, ['description', 'body']),
      claimed: m['claimed'] == true,
      rewardJeton: asInt(pick(m, ['rewardJeton', 'jeton', 'amount'])),
      route: _str(m, ['route', 'path']),
    );
  }

  List<String> _stringList(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    if (v is String && v.isNotEmpty) return [v];
    return const [];
  }

  String? _advisorCategory(Map<String, dynamic> m) {
    final direct = _str(m, ['category', 'specialty', 'title']);
    if (direct != null) return direct;
    final specs = m['specialties'];
    if (specs is List && specs.isNotEmpty) {
      return specs.first.toString();
    }
    return null;
  }

  String? _str(Map<String, dynamic> m, List<String> keys) {
    final v = pick(m, keys);
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  double _dbl(Map<String, dynamic> m, List<String> keys) {
    final v = pick(m, keys);
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// canlifal.com ana sayfa fal vitrin — web `/` ile aynı kart listesi.
  Future<List<HomeFortuneCardEntity>> fetchHomepageFortuneCards() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.homepageFortuneCards);
      final items = _itemsFromBody(res.data, keys: const ['cards', 'items']);
      if (items.isEmpty) return const [];
      return items
          .map((j) => _mapHomeFortuneCard(j))
          .where((c) => c.title.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  HomeFortuneCardEntity _mapHomeFortuneCard(Map<String, dynamic> m) {
    final href = _str(m, const ['href', 'url', 'link']) ?? '';
    var slug = _str(m, const ['slug', 'fortuneSlug']) ?? '';
    if (slug.isEmpty && href.contains('/')) {
      slug = href.split('/').where((s) => s.isNotEmpty).last;
    }
    return HomeFortuneCardEntity(
      id: _str(m, const ['id']) ?? slug,
      title: _str(m, const ['name', 'title']) ?? '',
      slug: slug,
      icon: _str(m, const ['icon', 'emoji']) ?? '🔮',
      imageUrl: _str(m, const ['image', 'imageUrl', 'thumbnail']),
      routePath: href.isNotEmpty ? href : null,
    );
  }

  int? _parseColorInt(dynamic v) {
    if (v is int) return v;
    if (v is String) {
      var s = v.trim();
      if (s.startsWith('#')) s = s.substring(1);
      if (s.startsWith('0x')) return int.tryParse(s.substring(2), radix: 16);
      final parsed = int.tryParse(s, radix: 16);
      if (parsed != null) {
        return s.length <= 6 ? (0xFF000000 | parsed) : parsed;
      }
    }
    return null;
  }
}

/// Wallet balance shortcut for header (production + self-hosted).
Future<int> fetchWalletJetonBalance(Dio dio) async {
  if (Env.useMobileAuth) {
    try {
      final me = await dio.safeGet<dynamic>(ApiEndpoints.me);
      final map = asJsonMap(me.data);
      final data = map['data'] is Map ? asJsonMap(map['data']) : map;
      final user = data['user'] is Map ? asJsonMap(data['user']) : data;
      return asInt(pick(user, ['coins', 'jeton', 'coinBalance', 'balance']));
    } catch (_) {}
  }
  for (final path in [ApiEndpoints.userCredits, ApiEndpoints.wallet]) {
    try {
      final res = await dio.safeGet<dynamic>(path);
      final map = asJsonMap(res.data);
      final data = map['data'] is Map ? asJsonMap(map['data']) : map;
      return asInt(pick(data, ['jeton', 'coins', 'balance', 'cfc']));
    } catch (_) {}
  }
  return 0;
}
