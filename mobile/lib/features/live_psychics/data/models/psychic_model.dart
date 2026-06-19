import '../../../../core/util/json_util.dart';
import '../../domain/entities/psychic_entity.dart';
import '../../domain/entities/psychic_request_entity.dart';
import '../../domain/entities/psychic_room_entity.dart';
import '../../domain/entities/psychic_session_status.dart';
import '../../domain/repositories/live_psychics_repository.dart';

/// JSON → domain — üretim API alan adları (değiştirilmez).
abstract final class PsychicModel {
  static List<Map<String, dynamic>> itemsFromBody(
    dynamic body, {
    List<String> keys = const ['items', 'tellers', 'data', 'results', 'sessions'],
  }) {
    if (body is List) {
      return body
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (body is! Map) return const [];
    final map = asJsonMap(body);
    for (final k in keys) {
      final raw = map[k];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return const [];
  }

  static String? str(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static PsychicEntity psychicFromJson(dynamic raw) {
    final m = asJsonMap(raw);
    final user = asJsonMap(m['user'] ?? m['profile']);
    final online = m['isOnline'] == true ||
        m['online'] == true ||
        m['status']?.toString().toLowerCase() == 'online';
    final specs = _stringList(m['specialties'] ?? m['tags'] ?? user['specialties']);
    final profileId = str(m, ['id', '_id', 'tellerId']) ?? str(user, ['tellerId']) ?? '';
    final userId = str(m, ['userId', 'tellerUserId', 'ownerId']) ??
        str(user, ['id', 'userId']);
    return PsychicEntity(
      id: profileId.isNotEmpty ? profileId : (userId ?? ''),
      userId: userId,
      name: str(m, ['displayName', 'name', 'username']) ??
          str(user, ['displayName', 'name', 'username']) ??
          'Falcı',
      bio: str(m, ['bio', 'description', 'about']) ?? str(user, ['bio']),
      avatarUrl: str(m, [
            'avatarUrl',
            'image',
            'avatar',
            'photoUrl',
            'profileImage',
          ]) ??
          str(user, ['avatarUrl', 'image', 'avatar']),
      isOnline: online,
      rating: _dbl(m, ['rating', 'score', 'averageRating']) != 0
          ? _dbl(m, ['rating', 'score', 'averageRating'])
          : _dbl(user, ['rating', 'score']),
      reviewCount: asInt(pick(m, ['reviewCount', 'reviews', 'totalReviews'])),
      pricePerMinute: asInt(pick(m, [
        'pricePerMinute',
        'pricePerSession',
        'sessionPrice',
        'price',
        'minutePrice',
      ])),
      specialties: specs,
      category: str(m, ['category', 'specialty']) ?? str(user, ['category']),
      applicationStatus: str(m, ['applicationStatus', 'status']) ??
          str(user, ['applicationStatus']),
    );
  }

  static PsychicRequestEntity requestFromJson(dynamic raw) {
    final m = asJsonMap(raw);
    final client = asJsonMap(m['client'] ?? m['user'] ?? m['clientUser']);
    final teller = asJsonMap(m['teller'] ?? m['fortuneTeller']);
    final statusRaw = str(m, ['status']) ?? 'pending';
    final response = str(m, ['tellerResponse', 'response']) ?? 'pending';
    return PsychicRequestEntity(
      sessionId: str(m, ['requestId', 'id', 'sessionId']) ?? '',
      clientId: str(m, ['clientId', 'userId']) ??
          str(client, ['id', 'userId']) ??
          '',
      clientName: str(m, ['clientName', 'clientDisplayName', 'userName']) ??
          str(client, ['displayName', 'name', 'username']) ??
          'Danışan',
      clientAvatarUrl: str(client, ['avatarUrl', 'image', 'avatar']),
      tellerId: str(m, ['tellerId', 'fortuneTellerId']) ??
          str(teller, ['id', 'tellerId']) ??
          '',
      tellerUserId: str(m, ['tellerUserId', 'anchorUserId']) ??
          str(teller, ['userId', 'tellerUserId']),
      durationMinutes: () {
        final v = asInt(
          pick(m, ['durationMinutes', 'maxMinutes', 'minutes', 'duration']),
        );
        return v > 0 ? v : 10;
      }(),
      totalJeton: asInt(
        pick(m, ['totalJeton', 'jeton', 'creditsCharged', 'amount']),
      ),
      fortuneType: str(m, ['fortuneType', 'category', 'specialty', 'falType']) ??
          str(teller, ['specialty']) ??
          'general',
      status: PsychicSessionStatus.fromApi(statusRaw, tellerResponse: response),
    );
  }

  static PsychicRoomEntity roomFromJson(
    Map<String, dynamic> data, {
    required String fallbackId,
  }) {
    final id = str(data, ['id', 'sessionId']) ?? fallbackId;
    final timerRaw = pick(data, ['timerStartedAt'])?.toString();
    DateTime? timerStartedAt;
    if (timerRaw != null && timerRaw.isNotEmpty) {
      timerStartedAt = DateTime.tryParse(timerRaw);
    }
    final user = asJsonMap(data['user']);
    final teller = asJsonMap(data['teller']);
    final tellerUserId = str(data, ['tellerUserId', 'anchorUserId']) ??
        str(teller, ['userId', 'tellerUserId']);
    final clientId = str(data, ['clientId']) ?? str(user, ['id', 'userId']);
    final isTeller = data['isTeller'] == true;
    final peerId = isTeller
        ? str(data, ['peerId', 'clientId', 'userId']) ?? clientId
        : str(data, ['peerId', 'anchorUserId', 'tellerUserId']) ?? tellerUserId;
    final statusRaw = str(data, ['status']) ?? 'active';
    return PsychicRoomEntity(
      sessionId: id,
      status: PsychicSessionStatus.fromApi(statusRaw),
      maxMinutes: () {
        final v = asInt(pick(data, ['maxMinutes', 'durationMinutes', 'duration']));
        return v > 0 ? v : 10;
      }(),
      timerStarted: data['timerStarted'] == true,
      roomId: str(data, ['roomId', 'trtcRoomId']),
      timerStartedAt: timerStartedAt,
      peerId: peerId,
      tellerUserId: tellerUserId,
      clientId: clientId,
      isClient: data['isUser'] == true || data['isTeller'] != true,
      isTeller: isTeller,
    );
  }

  static PsychicChatMessage chatFromJson(dynamic raw, {String? myUserId}) {
    final m = asJsonMap(raw);
    final sender = asJsonMap(m['sender'] ?? m['user'] ?? m['from']);
    final senderId = str(m, ['senderId', 'userId', 'fromId']) ??
        str(sender, ['id', 'userId']) ??
        '';
    final senderName = str(m, ['senderName', 'userName', 'displayName']) ??
        str(sender, ['displayName', 'name', 'username']) ??
        'Kullanıcı';
    final text = str(m, ['text', 'message', 'content', 'body']) ?? '';
    final createdRaw = pick(m, ['createdAt', 'sentAt', 'timestamp'])?.toString();
    DateTime? createdAt;
    if (createdRaw != null && createdRaw.isNotEmpty) {
      createdAt = DateTime.tryParse(createdRaw);
    }
    return PsychicChatMessage(
      id: str(m, ['id', '_id']) ?? '${senderId}_${createdRaw ?? text.hashCode}',
      senderId: senderId,
      senderName: senderName,
      text: text,
      createdAt: createdAt,
      isMine: myUserId != null && senderId.isNotEmpty && senderId == myUserId,
    );
  }

  static PsychicSessionCreateResult? sessionCreateFromJson(dynamic body) {
    if (body is! Map) return null;
    final map = asJsonMap(body);
    final data = map['data'] is Map ? asJsonMap(map['data']) : map;
    final sessionMap =
        data['session'] is Map ? asJsonMap(data['session']) : data;
    final sessionId = pick(data, ['sessionId', 'id', 'trtcRoomId'])?.toString() ??
        pick(sessionMap, ['id', 'sessionId', 'trtcRoomId'])?.toString();
    if (sessionId == null || sessionId.isEmpty) return null;
    final statusRaw = pick(data, ['status'])?.toString() ??
        pick(sessionMap, ['status'])?.toString() ??
        'pending';
    return PsychicSessionCreateResult(
      sessionId: sessionId,
      status: PsychicSessionStatus.fromApi(statusRaw),
      tellerUserId: pick(data, ['tellerUserId', 'anchorUserId'])?.toString() ??
          pick(sessionMap, ['tellerUserId'])?.toString(),
      clientId: pick(data, ['clientId', 'userId'])?.toString() ??
          pick(sessionMap, ['clientId', 'userId'])?.toString(),
      creditsCharged: asInt(
        pick(data, ['creditsCharged', 'totalJeton']) ??
            pick(sessionMap, ['creditsCharged', 'totalJeton']),
      ),
      maxMinutes: asInt(
        pick(data, ['maxMinutes', 'duration']) ??
            pick(sessionMap, ['maxMinutes', 'duration']),
      ),
      trtcRoomId: pick(data, ['trtcRoomId', 'roomId'])?.toString() ??
          pick(sessionMap, ['trtcRoomId', 'roomId'])?.toString(),
    );
  }

  static PsychicSessionStatusResult? sessionStatusFromJson(
    Map<String, dynamic> data,
    Map<String, dynamic> sessionMap,
  ) {
    final id = pick(data, ['sessionId', 'id'])?.toString() ??
        pick(sessionMap, ['id', 'sessionId'])?.toString();
    if (id == null || id.isEmpty) return null;
    final statusRaw = pick(data, ['status'])?.toString() ??
        pick(sessionMap, ['status'])?.toString() ??
        'pending';
    final tellerResponse = pick(data, ['tellerResponse', 'response'])?.toString() ??
        pick(sessionMap, ['tellerResponse', 'response'])?.toString();
    final isClientRaw = data['isClient'];
    final isClient = isClientRaw is bool ? isClientRaw : true;
    final tellerMap = asJsonMap(sessionMap['teller'] ?? data['teller']);
    return PsychicSessionStatusResult(
      sessionId: id,
      status: PsychicSessionStatus.fromApi(statusRaw, tellerResponse: tellerResponse),
      isClient: isClient,
      tellerUserId: pick(data, ['tellerUserId', 'anchorUserId'])?.toString() ??
          pick(sessionMap, ['tellerUserId'])?.toString() ??
          pick(tellerMap, ['userId'])?.toString(),
      tellerProfileId: pick(data, ['tellerId'])?.toString() ??
          pick(sessionMap, ['tellerId'])?.toString() ??
          pick(tellerMap, ['id'])?.toString(),
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

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
  }

  static double _dbl(Map<String, dynamic> m, List<String> keys) {
    final v = pick(m, keys);
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
