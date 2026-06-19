import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/util/json_util.dart';
import '../../domain/entities/psychic_request_entity.dart';
import '../../domain/entities/psychic_session_status.dart';
import 'psychic_push_payload.dart';

/// Sesli oda / yayın SSE — canlı fal isteği olayları.
final psychicLiveEventBusProvider =
    Provider<StreamController<PsychicRequestEntity>>((ref) {
  final controller = StreamController<PsychicRequestEntity>.broadcast();
  ref.onDispose(controller.close);
  return controller;
});

void emitPsychicLiveRequest(
  Ref ref,
  PsychicRequestEntity request,
) {
  final bus = ref.read(psychicLiveEventBusProvider);
  if (!bus.isClosed) bus.add(request);
}

PsychicRequestEntity? parsePsychicSsePayload(Map<String, dynamic> map) {
  final merged = mergePsychicInviteNestedFields(map);
  final type = psychicPushType(merged);
  if (!isPsychicInviteEventType(type) &&
      !merged.containsKey('sessionId') &&
      !merged.containsKey('requestId') &&
      !merged.containsKey('request') &&
      !merged.containsKey('session')) {
    return null;
  }

  final nested = merged['request'] is Map
      ? asJsonMap(merged['request'])
      : merged['session'] is Map
          ? asJsonMap(merged['session'])
          : merged;
  final client = asJsonMap(nested['client'] ?? nested['user']);
  final sessionId = pick(nested, [
        'requestId',
        'id',
        'sessionId',
        'session_id',
        'targetId',
        'target_id',
        'liveSessionId',
      ])?.toString() ??
      pick(merged, [
        'requestId',
        'id',
        'sessionId',
        'session_id',
        'targetId',
        'target_id',
        'liveSessionId',
      ])?.toString() ??
      '';
  if (sessionId.isEmpty) return null;
  return PsychicRequestEntity(
    sessionId: sessionId,
    clientId: pick(nested, ['clientId'])?.toString() ??
        pick(client, ['id', 'userId'])?.toString() ??
        '',
    clientName: pick(nested, ['clientName', 'userName'])?.toString() ??
        pick(client, ['displayName', 'name', 'username'])?.toString() ??
        'Danışan',
    clientAvatarUrl: pick(client, ['avatarUrl', 'image', 'avatar'])?.toString(),
    tellerId: pick(nested, ['tellerId', 'fortuneTellerId'])?.toString() ?? '',
    tellerUserId: pick(nested, ['tellerUserId', 'anchorUserId'])?.toString(),
    durationMinutes: () {
      final v = asInt(
        pick(nested, ['durationMinutes', 'minutes', 'duration']),
      );
      return v > 0 ? v : 10;
    }(),
    totalJeton: asInt(
      pick(nested, ['totalJeton', 'jeton', 'amount', 'tokenAmount']),
    ),
    fortuneType: pick(nested, ['category', 'fortuneType', 'falType'])?.toString() ??
        'Canlı fal',
    status: PsychicSessionStatus.fromApi(
      pick(nested, ['status'])?.toString(),
      tellerResponse: pick(nested, ['tellerResponse', 'response'])?.toString(),
    ),
  );
}
