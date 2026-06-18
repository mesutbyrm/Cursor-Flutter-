import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import '../../domain/entities/live_fortune_teller_entity.dart';
import '../../domain/entities/live_teller_review_entity.dart';
import 'home_remote_datasource.dart';

/// Canlı falcı modülü — canlifal.com üretim uçları (JWT Bearer).
class LiveFortuneRemoteDataSource {
  LiveFortuneRemoteDataSource(this._dio, this._home);

  final Dio _dio;
  final HomeRemoteDataSource _home;

  Future<List<LiveFortuneTellerEntity>> fetchTellers({
    bool? onlineOnly,
    String? specialty,
    String? sort,
  }) async {
    final params = <String, dynamic>{};
    if (onlineOnly == true) params['online'] = 'true';
    if (specialty != null && specialty.trim().isNotEmpty) {
      params['specialty'] = specialty.trim();
    }
    if (sort != null && sort.trim().isNotEmpty) params['sort'] = sort.trim();
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.fortuneTellers,
        query: params.isEmpty ? null : params,
      );
      final items = _itemsFromBody(res.data);
      if (items.isNotEmpty) {
        return items
            .map((j) => _home.parseLiveFortuneTeller(j))
            .where((t) => t.id.isNotEmpty)
            .toList(growable: false);
      }
    } catch (_) {}
    var tellers = await _home.fetchLiveFortuneTellers();
    if (onlineOnly == true) {
      tellers = tellers.where((t) => t.isOnline).toList();
    }
    if (specialty != null && specialty.trim().isNotEmpty) {
      final key = specialty.trim().toLowerCase();
      tellers = tellers
          .where(
            (t) => t.specialties.any((s) => s.toLowerCase().contains(key)),
          )
          .toList();
    }
    return tellers;
  }

  Future<LiveFortuneTellerEntity?> fetchTeller(String id) =>
      _home.fetchLiveFortuneTeller(id);

  Future<LiveFortuneTellerEntity?> fetchMyProfile() =>
      _home.fetchMyFortuneTellerProfile();

  Future<FortuneTellerApplyResult> applyAsTeller({
    required String displayName,
    required List<String> specialties,
    String? bio,
    String? applicationNote,
  }) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.fortuneTellerApply,
        data: {
          'displayName': displayName.trim(),
          'specialties': specialties.where((s) => s.trim().isNotEmpty).toList(),
          if (bio != null && bio.trim().isNotEmpty) 'bio': bio.trim(),
          if (applicationNote != null && applicationNote.trim().isNotEmpty)
            'applicationNote': applicationNote.trim(),
        },
      );
      final body = res.data;
      if (body is! Map) {
        return const FortuneTellerApplyResult(success: false);
      }
      final map = asJsonMap(body);
      final teller = map['teller'] is Map ? asJsonMap(map['teller']) : map;
      return FortuneTellerApplyResult(
        success: map['success'] == true || teller['id'] != null,
        tellerId: teller['id']?.toString(),
        applicationStatus: teller['applicationStatus']?.toString(),
        message: map['message']?.toString(),
      );
    } on ApiException catch (e) {
      return FortuneTellerApplyResult(
        success: false,
        message: e.message,
      );
    }
  }

  Future<bool> setOnline({required bool online}) =>
      _home.setFortuneTellerOnline(online: online);

  Future<FortuneSessionCreateResult?> createSession(
    String tellerId, {
    String? tellerUserId,
    int? durationMinutes,
    int? totalJeton,
    String? fortuneType,
  }) =>
      _home.createFortuneTellerSession(
        tellerId,
        tellerUserId: tellerUserId,
        durationMinutes: durationMinutes,
        totalJeton: totalJeton,
        fortuneType: fortuneType,
      );

  Future<List<FortuneIncomingSession>> fetchIncomingSessions({
    String? currentUserId,
    String? tellerProfileId,
  }) =>
      _home.fetchIncomingFortuneSessions(
        currentUserId: currentUserId,
        tellerProfileId: tellerProfileId,
      );

  Future<FortuneSessionStatusResult?> fetchSessionStatus(String sessionId) =>
      _home.fetchFortuneSessionStatus(sessionId);

  Future<List<FortuneSessionStatusResult>> fetchActiveSessions() =>
      _home.fetchUserActiveSessions();

  Future<bool> respondSession(String sessionId, {required String action}) =>
      _home.respondFortuneSession(sessionId, action: action);

  Future<bool> endSession(String sessionId) => _home.endFortuneSession(sessionId);

  Future<LiveFortuneRoomInfo?> fetchRoomInfo(String sessionId) =>
      _home.fetchRoomInfo(sessionId);

  Future<Map<String, dynamic>?> roomAction(
    String sessionId,
    String action, {
    Map<String, dynamic>? extra,
  }) =>
      _home.roomAction(sessionId, action, extra: extra);

  Future<List<TellerChatMessage>> fetchRoomMessages(
    String sessionId, {
    String? afterIso,
    String? myUserId,
  }) =>
      _home.fetchRoomMessages(
        sessionId,
        afterIso: afterIso,
        myUserId: myUserId,
      );

  Future<List<TellerChatMessage>> fetchTellerChatMessages(
    String sessionId, {
    String? afterIso,
    String? myUserId,
  }) =>
      _home.fetchTellerChatMessages(
        sessionId,
        afterIso: afterIso,
        myUserId: myUserId,
      );

  Future<bool> sendRoomMessage(String sessionId, String text) =>
      _home.sendRoomMessage(sessionId, text);

  Future<bool> extendSession({
    required String sessionId,
    required int minutes,
    required int totalJeton,
  }) =>
      _home.extendFortuneSession(
        sessionId: sessionId,
        minutes: minutes,
        totalJeton: totalJeton,
      );

  Future<bool> tellerAddTime({
    required String sessionId,
    required int minutes,
  }) =>
      _home.tellerAddSessionTime(sessionId: sessionId, minutes: minutes);

  Future<bool> sendTip({
    required String sessionId,
    required int amount,
    String? tellerId,
    String? tellerUserId,
  }) =>
      _home.sendTellerTip(
        sessionId: sessionId,
        amount: amount,
        tellerId: tellerId,
        tellerUserId: tellerUserId,
      );

  Future<LiveTellerReviewsBundle> fetchTellerReviews(String tellerId) async {
    final key = tellerId.trim();
    if (key.isEmpty) return const LiveTellerReviewsBundle();
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.fortuneTellerReviews(key),
      );
      final body = res.data;
      if (body is! Map) return const LiveTellerReviewsBundle();
      final map = asJsonMap(body);
      final raw = map['reviews'];
      final reviews = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => _mapReview(key, Map<String, dynamic>.from(e)))
              .where((r) => r.id.isNotEmpty)
              .toList(growable: false)
          : <LiveTellerReviewEntity>[];
      return LiveTellerReviewsBundle(
        reviews: reviews,
        averageRating: _parseDouble(map['averageRating']),
        totalReviews: asInt(map['totalReviews']),
      );
    } catch (_) {
      return const LiveTellerReviewsBundle();
    }
  }

  Future<List<LiveTellerAwardEntity>> fetchTellerAwards(String tellerId) async {
    final key = tellerId.trim();
    if (key.isEmpty) return const [];
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.fortuneTellerAwards(key),
      );
      final items = _itemsFromBody(res.data);
      return items
          .map((m) => LiveTellerAwardEntity(
                id: m['id']?.toString() ?? '',
                tellerId: key,
                awardType: m['awardType']?.toString() ?? '',
                title: m['title']?.toString() ?? '',
                startDate: _parseDate(m['startDate']),
                endDate: _parseDate(m['endDate']),
                createdAt: _parseDate(m['createdAt']),
              ))
          .where((a) => a.id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<LiveTellerGiftSummaryEntity>> fetchTellerGifts(
    String tellerId,
  ) async {
    final key = tellerId.trim();
    if (key.isEmpty) return const [];
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.fortuneTellerGifts(key),
      );
      final items = _itemsFromBody(res.data);
      return items
          .map((m) => LiveTellerGiftSummaryEntity(
                senderId: m['senderId']?.toString() ??
                    m['userId']?.toString() ??
                    '',
                senderName: m['senderName']?.toString() ??
                    m['name']?.toString() ??
                    'Kullanıcı',
                giftCount: asInt(m['giftCount'] ?? m['count']),
                senderImage: m['senderImage']?.toString() ?? m['image']?.toString(),
                totalJeton: asInt(m['totalJeton'] ?? m['jeton'] ?? m['amount']),
              ))
          .where((g) => g.senderId.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> postRoomSignal({
    required String sessionId,
    required String receiverId,
    required String signalType,
    required Map<String, dynamic> signalData,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.liveFortuneRoomSignal,
      data: {
        'sessionId': sessionId.trim(),
        'receiverId': receiverId.trim(),
        'signalType': signalType.trim(),
        'signalData': signalData,
      },
    );
  }

  Future<List<LiveFortuneRoomSignalEntity>> pollRoomSignals(
    String sessionId,
  ) async {
    final key = sessionId.trim();
    if (key.isEmpty) return const [];
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.liveFortuneRoomSignalQuery(key),
      );
      final body = res.data;
      final list = body is List ? body : body is Map ? body['signals'] : null;
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map(_mapSignal)
          .where((s) => s.id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> clearRoomSignals(String sessionId) async {
    final key = sessionId.trim();
    if (key.isEmpty) return;
    try {
      await _dio.safeDelete<dynamic>(
        ApiEndpoints.liveFortuneRoomSignalQuery(key),
      );
    } catch (_) {}
  }

  LiveTellerReviewEntity _mapReview(String tellerId, Map<String, dynamic> m) {
    final session = m['session'] is Map
        ? Map<String, dynamic>.from(m['session'] as Map)
        : null;
    final user = session?['user'] is Map
        ? Map<String, dynamic>.from(session!['user'] as Map)
        : null;
    return LiveTellerReviewEntity(
      id: m['id']?.toString() ?? '',
      tellerId: m['tellerId']?.toString() ?? tellerId,
      sessionId: m['sessionId']?.toString() ?? '',
      rating: asInt(m['rating']).clamp(1, 5),
      comment: m['comment']?.toString(),
      createdAt: _parseDate(m['createdAt']),
      reviewerName: user?['name']?.toString(),
      reviewerUsername: user?['username']?.toString(),
      reviewerImage: user?['image']?.toString(),
      fortuneType: session?['fortuneType']?.toString(),
    );
  }

  LiveFortuneRoomSignalEntity _mapSignal(Map raw) {
    final m = Map<String, dynamic>.from(raw);
    Map<String, dynamic> data;
    final rawData = m['signalData'];
    if (rawData is Map) {
      data = Map<String, dynamic>.from(rawData);
    } else if (rawData is String && rawData.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawData);
        data = decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : <String, dynamic>{'sdp': rawData};
      } catch (_) {
        data = <String, dynamic>{'sdp': rawData};
      }
    } else {
      data = const {};
    }
    return LiveFortuneRoomSignalEntity(
      id: m['id']?.toString() ?? '',
      sessionId: m['sessionId']?.toString() ?? '',
      senderId: m['senderId']?.toString() ?? '',
      receiverId: m['receiverId']?.toString() ?? '',
      signalType: m['signalType']?.toString() ?? '',
      signalData: data,
      processed: m['processed'] == true,
      createdAt: _parseDate(m['createdAt']),
    );
  }

  List<Map<String, dynamic>> _itemsFromBody(dynamic body) {
    if (body is List) {
      return body.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (body is! Map) return const [];
    final map = asJsonMap(body);
    final raw = map['items'] ??
        map['data'] ??
        map['awards'] ??
        map['gifts'] ??
        map['results'] ??
        [];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  double _parseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
