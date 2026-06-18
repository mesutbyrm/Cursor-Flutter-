import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/util/json_util.dart';
import '../../domain/entities/live_fortune_session_entity.dart';

/// Sesli oda SSE veya falcı SSE — canlı fal isteği olayları.
final fortuneLiveEventBusProvider =
    Provider<StreamController<FortuneIncomingSession>>((ref) {
  final controller = StreamController<FortuneIncomingSession>.broadcast();
  ref.onDispose(controller.close);
  return controller;
});

void emitFortuneLiveRequest(
  Ref ref,
  FortuneIncomingSession session,
) {
  final bus = ref.read(fortuneLiveEventBusProvider);
  if (!bus.isClosed) bus.add(session);
}

FortuneIncomingSession? parseFortuneSsePayload(Map<String, dynamic> map) {
  final nested = map['request'] is Map
      ? asJsonMap(map['request'])
      : map['session'] is Map
          ? asJsonMap(map['session'])
          : map;
  final client = asJsonMap(nested['client'] ?? nested['user']);
  final sessionId = pick(nested, [
        'requestId',
        'id',
        'sessionId',
        'session_id',
        'targetId',
        'target_id',
      ])?.toString() ??
      '';
  if (sessionId.isEmpty) return null;
  return FortuneIncomingSession(
    sessionId: sessionId,
    clientId: pick(nested, ['clientId'])?.toString() ??
        pick(client, ['id', 'userId'])?.toString() ??
        '',
    clientName: pick(nested, ['clientName', 'userName'])?.toString() ??
        pick(client, ['displayName', 'name', 'username'])?.toString() ??
        'Danışan',
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
    category: pick(nested, ['category', 'fortuneType', 'falType'])?.toString() ??
        'Canlı fal',
    status: pick(nested, ['status'])?.toString() ?? 'pending',
    tellerResponse:
        pick(nested, ['tellerResponse', 'response'])?.toString() ?? 'pending',
  );
}
