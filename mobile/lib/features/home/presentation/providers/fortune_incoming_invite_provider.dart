import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/util/json_util.dart';
import '../../domain/entities/live_fortune_session_entity.dart';

/// Falcıya gösterilecek bekleyen davet kuyruğu (push + poll).
class FortuneIncomingInviteNotifier extends Notifier<List<FortuneIncomingSession>> {
  @override
  List<FortuneIncomingSession> build() => const [];

  void enqueue(FortuneIncomingSession session) {
    if (session.sessionId.isEmpty) return;
    if (state.any((s) => s.sessionId == session.sessionId)) return;
    state = [...state, session];
  }

  FortuneIncomingSession? takeNext() {
    if (state.isEmpty) return null;
    final next = state.first;
    state = state.sublist(1);
    return next;
  }

  void remove(String sessionId) {
    state = state.where((s) => s.sessionId != sessionId).toList();
  }
}

final fortuneIncomingInviteProvider =
    NotifierProvider<FortuneIncomingInviteNotifier, List<FortuneIncomingSession>>(
  FortuneIncomingInviteNotifier.new,
);

Map<String, dynamic> _flattenPushPayload(Map<String, dynamic> raw) {
  var map = Map<String, dynamic>.from(raw);
  final nested = map['data'];
  if (nested is String && nested.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(nested);
      if (decoded is Map) {
        map = {...map, ...asJsonMap(decoded)};
      }
    } catch (_) {}
  } else if (nested is Map) {
    map = {...map, ...asJsonMap(nested)};
  }
  if (map['payload'] is Map) {
    map = {...map, ...asJsonMap(map['payload'])};
  }
  return map;
}

String _pushType(Map<String, dynamic> map) => [
      map['type'],
      map['event'],
      map['kind'],
      map['notificationType'],
    ].whereType<String>().map((s) => s.toLowerCase()).join(' ');

/// Kullanıcı push — `session_update` (kabul / red / iptal).
class FortuneSessionUpdatePayload {
  const FortuneSessionUpdatePayload({
    required this.sessionId,
    required this.action,
    this.tellerId,
  });

  final String sessionId;
  final String action;
  final String? tellerId;

  bool get isAccepted => action == 'accept';
  bool get isRejected =>
      action == 'reject' || action == 'decline' || action == 'cancel';
}

FortuneSessionUpdatePayload? parseSessionUpdatePayload(
  Map<String, dynamic>? raw,
) {
  if (raw == null || raw.isEmpty) return null;
  final map = _flattenPushPayload(raw);
  final type = _pushType(map);
  if (!type.contains('session_update')) return null;

  final sessionId = pick(map, [
    'sessionId',
    'session_id',
    'id',
  ])?.toString();
  if (sessionId == null || sessionId.isEmpty) return null;

  final action = pick(map, ['action', 'status'])?.toString().toLowerCase() ??
      'accept';
  return FortuneSessionUpdatePayload(
    sessionId: sessionId,
    action: action,
    tellerId: pick(map, ['tellerId', 'teller_id'])?.toString(),
  );
}

/// Push / bildirim `additionalData` → falcı davet modeli (`session_request`).
FortuneIncomingSession? parseFortuneIncomingPayload(Map<String, dynamic>? raw) {
  if (raw == null || raw.isEmpty) return null;

  final map = _flattenPushPayload(raw);
  final type = _pushType(map);

  if (type.contains('session_update') || type.contains('session_ended')) {
    return null;
  }

  final looksLikeFortune = type.contains('session_request') ||
      type.contains('fortune') ||
      type.contains('falc') ||
      type.contains('live_fortune') ||
      type.contains('live_session') ||
      (map.containsKey('sessionId') &&
          (map.containsKey('tellerId') ||
              map.containsKey('clientId') ||
              map.containsKey('userId')));

  if (!looksLikeFortune) return null;

  final sessionId = pick(map, [
    'sessionId',
    'session_id',
    'id',
    'fortuneSessionId',
    'liveSessionId',
    'live_session_id',
  ])?.toString();
  if (sessionId == null || sessionId.isEmpty) return null;

  final duration = asInt(
    pick(map, ['durationMinutes', 'duration', 'minutes', 'maxMinutes']),
  );
  return FortuneIncomingSession(
    sessionId: sessionId,
    clientId: pick(map, ['clientId', 'client_id', 'userId'])?.toString() ?? '',
    clientName: pick(map, [
          'clientName',
          'client_name',
          'displayName',
          'userName',
          'fromName',
        ])?.toString() ??
        'Danışan',
    tellerId: pick(map, ['tellerId', 'teller_id', 'fortuneTellerId'])
            ?.toString() ??
        '',
    tellerUserId: pick(map, ['tellerUserId', 'teller_user_id', 'anchorUserId'])
        ?.toString(),
    durationMinutes: duration > 0 ? duration : 10,
    totalJeton: asInt(
      pick(map, [
        'totalJeton',
        'total_jeton',
        'jeton',
        'amount',
        'creditsCharged',
      ]),
    ),
    category: pick(map, ['category', 'specialty', 'specialties', 'fortuneType'])
            ?.toString() ??
        'general',
    status: pick(map, ['status'])?.toString() ?? 'pending',
    tellerResponse: pick(map, ['tellerResponse', 'response'])?.toString() ??
        'pending',
  );
}

bool isFortuneInvitePayload(Map<String, dynamic>? raw) =>
    parseFortuneIncomingPayload(raw) != null;
