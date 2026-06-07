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

/// Push / bildirim `additionalData` → davet modeli.
FortuneIncomingSession? parseFortuneIncomingPayload(Map<String, dynamic>? raw) {
  if (raw == null || raw.isEmpty) return null;

  Map<String, dynamic> map = Map<String, dynamic>.from(raw);
  if (map['data'] is Map) {
    map = {...map, ...asJsonMap(map['data'])};
  }
  if (map['payload'] is Map) {
    map = {...map, ...asJsonMap(map['payload'])};
  }

  final type = [
    map['type'],
    map['event'],
    map['kind'],
    map['notificationType'],
  ].whereType<String>().map((s) => s.toLowerCase()).join(' ');

  final looksLikeFortune = type.contains('fortune') ||
      type.contains('falc') ||
      type.contains('live_fortune') ||
      map.containsKey('sessionId') && map.containsKey('tellerId');

  if (!looksLikeFortune) return null;

  final sessionId = pick(map, [
    'sessionId',
    'session_id',
    'id',
    'fortuneSessionId',
  ])?.toString();
  if (sessionId == null || sessionId.isEmpty) return null;

  final duration = asInt(pick(map, ['durationMinutes', 'duration', 'minutes']));
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
    durationMinutes: duration > 0 ? duration : 10,
    totalJeton: asInt(pick(map, ['totalJeton', 'total_jeton', 'jeton', 'amount'])),
    category: pick(map, ['category', 'specialty', 'specialties'])?.toString() ??
        'general',
    status: pick(map, ['status'])?.toString() ?? 'pending',
    tellerResponse: pick(map, ['tellerResponse', 'response'])?.toString() ??
        'pending',
  );
}

bool isFortuneInvitePayload(Map<String, dynamic>? raw) =>
    parseFortuneIncomingPayload(raw) != null;
