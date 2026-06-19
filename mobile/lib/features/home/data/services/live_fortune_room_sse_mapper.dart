import '../../../../core/util/json_util.dart';
import '../../domain/entities/live_fortune_session_entity.dart';

/// SSE `data:` JSON → domain modelleri (üretim prompt §9–10).
abstract final class LiveFortuneRoomSseMapper {
  static TellerChatMessage? parseMessage(
    Map<String, dynamic> map, {
    String? myUserId,
  }) {
    final nested = map['message'] is Map
        ? asJsonMap(map['message'])
        : map;
    final sender = asJsonMap(nested['sender'] ?? nested['user'] ?? nested['from']);
    final senderId = _str(nested, ['senderId', 'userId', 'fromId']) ??
        _str(sender, ['id', 'userId']) ??
        '';
    final senderName = _str(nested, ['senderName', 'userName', 'displayName']) ??
        _str(sender, ['displayName', 'name', 'username']) ??
        'Kullanıcı';
    final text = _str(nested, ['text', 'message', 'content', 'body']) ?? '';
    if (text.trim().isEmpty) return null;
    final createdRaw =
        pick(nested, ['createdAt', 'sentAt', 'timestamp'])?.toString();
    DateTime? createdAt;
    if (createdRaw != null && createdRaw.isNotEmpty) {
      createdAt = DateTime.tryParse(createdRaw);
    }
    return TellerChatMessage(
      id: _str(nested, ['id', '_id']) ??
          '${senderId}_${createdRaw ?? text.hashCode}',
      senderId: senderId,
      senderName: senderName,
      text: text,
      createdAt: createdAt,
      isMine: myUserId != null && senderId.isNotEmpty && senderId == myUserId,
    );
  }

  static List<TellerChatMessage> parseMessages(
    Map<String, dynamic> map, {
    String? myUserId,
  }) {
    final raw = map['messages'] ?? map['items'];
    if (raw is! List) {
      final one = parseMessage(map, myUserId: myUserId);
      return one == null ? const [] : [one];
    }
    final out = <TellerChatMessage>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final msg = parseMessage(Map<String, dynamic>.from(item), myUserId: myUserId);
      if (msg != null) out.add(msg);
    }
    return out;
  }

  static LiveFortuneRoomInfo? parseRoomInfo(
    Map<String, dynamic> map, {
    required String fallbackSessionId,
  }) {
    final nested = map['room'] is Map
        ? asJsonMap(map['room'])
        : map['session'] is Map
            ? asJsonMap(map['session'])
            : map;
    final id = _str(nested, ['id', 'sessionId']) ?? fallbackSessionId;
    if (id.isEmpty) return null;
    final timerRaw = pick(nested, ['timerStartedAt'])?.toString();
    DateTime? timerStartedAt;
    if (timerRaw != null && timerRaw.isNotEmpty) {
      timerStartedAt = DateTime.tryParse(timerRaw);
    }
    final user = asJsonMap(nested['user']);
    final teller = asJsonMap(nested['teller']);
    final tellerUserId = _str(nested, ['tellerUserId', 'anchorUserId']) ??
        _str(teller, ['userId', 'tellerUserId']);
    final clientId = _str(nested, ['clientId']) ??
        _str(user, ['id', 'userId']);
    final isTeller = nested['isTeller'] == true;
    final peerId = isTeller
        ? _str(nested, ['peerId', 'clientId', 'userId']) ?? clientId
        : _str(nested, ['peerId', 'anchorUserId', 'tellerUserId']) ??
            tellerUserId;
    return LiveFortuneRoomInfo(
      sessionId: id,
      status: _str(nested, ['status']) ?? 'active',
      maxMinutes: () {
        final v = asInt(
          pick(nested, ['maxMinutes', 'durationMinutes', 'duration']),
        );
        return v > 0 ? v : 10;
      }(),
      timerStarted:
          nested['timerStarted'] == true || map['timerStarted'] == true,
      roomId: _str(nested, ['roomId', 'trtcRoomId']),
      timerStartedAt: timerStartedAt,
      elapsedSeconds: asInt(pick(nested, ['elapsedSeconds'])),
      minutesUsed: asInt(pick(nested, ['minutesUsed'])),
      creditsPerMinute: () {
        final v = asInt(pick(nested, ['creditsPerMinute']));
        return v > 0 ? v : 10;
      }(),
      peerId: peerId,
      tellerUserId: tellerUserId,
      clientId: clientId,
      isUser: nested['isUser'] == true || nested['isTeller'] != true,
      isTeller: isTeller,
      userJetonBalance: asInt(pick(user, ['jetonBalance'])),
    );
  }

  static FortuneSessionStatusResult? parseSessionStatus(
    Map<String, dynamic> map, {
    required String fallbackSessionId,
  }) {
    final nested = map['session'] is Map
        ? asJsonMap(map['session'])
        : map['request'] is Map
            ? asJsonMap(map['request'])
            : map;
    final sessionId =
        _str(nested, ['id', 'sessionId', 'requestId']) ?? fallbackSessionId;
    if (sessionId.isEmpty) return null;
    final status = _str(nested, ['status']) ?? 'pending';
    var tellerResponse =
        _str(nested, ['tellerResponse', 'response', 'tellerStatus']) ??
            'pending';
    if (nested['accepted'] == true || nested['isAccepted'] == true) {
      tellerResponse = 'accepted';
    } else if (nested['rejected'] == true || nested['isRejected'] == true) {
      tellerResponse = 'rejected';
    }
    final role = _str(nested, ['role']);
    final isClientRaw = nested['isClient'];
    final isClient = isClientRaw is bool ? isClientRaw : role != 'teller';
    return FortuneSessionStatusResult(
      sessionId: sessionId,
      status: status,
      tellerResponse: tellerResponse,
      isClient: isClient,
      tellerUserId: _str(nested, ['tellerUserId', 'anchorUserId']),
      tellerProfileId: _str(nested, ['tellerId', 'fortuneTellerId']),
      trtcRoomId: _str(nested, ['roomId', 'trtcRoomId']),
      durationMinutes: () {
        final v = asInt(
          pick(nested, ['durationMinutes', 'maxMinutes', 'minutes', 'duration']),
        );
        return v > 0 ? v : null;
      }(),
      totalJeton: () {
        final v = asInt(
          pick(nested, ['totalJeton', 'creditsCharged', 'jeton']),
        );
        return v > 0 ? v : null;
      }(),
    );
  }

  static String? _str(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }
}
