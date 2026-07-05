import '../../../../core/util/json_util.dart';
import '../../../live_psychics/domain/entities/psychic_request_entity.dart';
import '../../../live_psychics/domain/entities/psychic_session_status.dart';
import '../entities/live_fortune_request_entity.dart';

/// Canlı yayın fal kuyruğu → falcı davet diyaloğu köprüsü.
PsychicRequestEntity? liveFortuneRequestToPsychicInvite(
  LiveFortuneRequestEntity request, {
  String? tellerUserId,
  String? tellerProfileId,
}) {
  if (request.id.isEmpty) return null;
  return PsychicRequestEntity(
    sessionId: request.id,
    clientId: request.userId,
    clientName: request.displayName,
    tellerId: tellerProfileId ?? '',
    tellerUserId: tellerUserId,
    durationMinutes: 10,
    totalJeton: request.jetonCost,
    fortuneType: request.fortuneType,
    status: PsychicSessionStatus.pending,
  );
}

/// SSE / push gövdesinden yayıncı kullanıcı kimliği.
String? pickStreamHostUserId(Map<String, dynamic> map) {
  final nested = map['request'] is Map
      ? Map<String, dynamic>.from(map['request'] as Map)
      : map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : map;
  return pick(nested, [
    'hostUserId',
    'host_user_id',
    'tellerUserId',
    'anchorUserId',
    'broadcasterId',
    'streamerId',
  ])?.toString();
}

LiveFortuneRequestEntity parseLiveFortuneRequestMap(Map<String, dynamic> map) {
  final request = map['request'];
  if (request is Map) {
    return LiveFortuneRequestEntity.fromJson(
      Map<String, dynamic>.from(request),
    );
  }
  final data = map['data'];
  if (data is Map) {
    final inner = Map<String, dynamic>.from(data);
    if (inner['request'] is Map) {
      return LiveFortuneRequestEntity.fromJson(
        Map<String, dynamic>.from(inner['request'] as Map),
      );
    }
    return LiveFortuneRequestEntity.fromJson(inner);
  }
  return LiveFortuneRequestEntity.fromJson(map);
}
