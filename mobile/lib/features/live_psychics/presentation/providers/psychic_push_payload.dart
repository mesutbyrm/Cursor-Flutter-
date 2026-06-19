import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/util/json_util.dart';
import '../../../notifications/domain/entities/app_notification_entity.dart';
import '../../domain/entities/psychic_request_entity.dart';
import '../../domain/entities/psychic_session_status.dart';

Map<String, dynamic> flattenPsychicPushPayload(Map<String, dynamic> raw) {
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

String psychicPushType(Map<String, dynamic> map) => [
      map['type'],
      map['event'],
      map['kind'],
      map['notificationType'],
    ]
        .map((e) => e?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty)
        .map((s) => s.toLowerCase())
        .join(' ');

String? sessionIdFromTargetPath(dynamic rawPath) {
  final path = rawPath?.toString().trim() ?? '';
  if (path.isEmpty) return null;
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return null;
  final last = segments.last;
  if (last == 'dashboard' || last == 'session' || last.length < 6) return null;
  return last;
}

class PsychicSessionUpdatePayload {
  const PsychicSessionUpdatePayload({
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

class PsychicSessionEndedPayload {
  const PsychicSessionEndedPayload({
    required this.sessionId,
    this.tellerId,
    this.tellerName,
    this.durationMinutes,
    this.totalJeton,
    this.message,
  });

  final String sessionId;
  final String? tellerId;
  final String? tellerName;
  final int? durationMinutes;
  final int? totalJeton;
  final String? message;
}

PsychicSessionEndedPayload? parsePsychicSessionEndedPayload(
  Map<String, dynamic>? raw,
) {
  if (raw == null || raw.isEmpty) return null;
  final map = flattenPsychicPushPayload(raw);
  final type = psychicPushType(map);
  if (!type.contains('session_ended')) return null;

  final sessionId = pick(map, [
    'sessionId',
    'session_id',
    'id',
    'targetId',
    'target_id',
  ])?.toString();
  if (sessionId == null || sessionId.isEmpty) return null;

  final rawDuration = asInt(
    pick(map, ['durationMinutes', 'duration', 'minutes', 'maxMinutes']),
  );
  final rawJeton = asInt(
    pick(map, ['totalJeton', 'total_jeton', 'jeton', 'creditsCharged']),
  );

  return PsychicSessionEndedPayload(
    sessionId: sessionId,
    tellerId: pick(map, ['tellerId', 'teller_id', 'fortuneTellerId'])
        ?.toString(),
    tellerName: pick(map, [
      'tellerName',
      'teller_name',
      'displayName',
      'name',
    ])?.toString(),
    durationMinutes: rawDuration > 0 ? rawDuration : null,
    totalJeton: rawJeton > 0 ? rawJeton : null,
    message: pick(map, ['message', 'body', 'summary'])?.toString(),
  );
}

PsychicSessionUpdatePayload? parsePsychicSessionUpdatePayload(
  Map<String, dynamic>? raw,
) {
  if (raw == null || raw.isEmpty) return null;
  final map = flattenPsychicPushPayload(raw);
  final type = psychicPushType(map);
  if (!type.contains('session_update')) return null;

  final sessionId = pick(map, [
    'sessionId',
    'session_id',
    'id',
  ])?.toString();
  if (sessionId == null || sessionId.isEmpty) return null;

  final action = pick(map, ['action', 'status'])?.toString().toLowerCase() ??
      'accept';
  return PsychicSessionUpdatePayload(
    sessionId: sessionId,
    action: action,
    tellerId: pick(map, ['tellerId', 'teller_id'])?.toString(),
  );
}

PsychicRequestEntity? parsePsychicIncomingPayload(Map<String, dynamic>? raw) {
  if (raw == null || raw.isEmpty) return null;

  final map = flattenPsychicPushPayload(raw);
  final type = psychicPushType(map);

  if (type.contains('session_update') || type.contains('session_ended')) {
    return null;
  }

  final looksLikeFortune = type.contains('session_request') ||
      type.contains('fortune') ||
      type.contains('falc') ||
      type.contains('live_fortune') ||
      type.contains('live_session') ||
      type.contains('live_fal') ||
      (map.containsKey('sessionId') &&
          (map.containsKey('tellerId') ||
              map.containsKey('clientId') ||
              map.containsKey('userId'))) ||
      ((map.containsKey('targetId') || map.containsKey('target_id')) &&
          (type.contains('fortune') ||
              type.contains('live') ||
              type.contains('falc') ||
              map['targetPath']?.toString().toLowerCase().contains('fal') ==
                  true ||
              map['targetPath']?.toString().toLowerCase().contains('session') ==
                  true));

  if (!looksLikeFortune) return null;

  final sessionId = pick(map, [
        'sessionId',
        'session_id',
        'targetId',
        'target_id',
        'id',
        'fortuneSessionId',
        'liveSessionId',
        'live_session_id',
        'entityId',
        'refId',
        'requestId',
      ])?.toString() ??
      sessionIdFromTargetPath(map['targetPath']);
  if (sessionId == null || sessionId.isEmpty) return null;

  return PsychicRequestEntity(
    sessionId: sessionId,
    clientId: pick(map, ['clientId', 'client_id', 'userId'])?.toString() ?? '',
    clientName: pick(map, [
          'clientName',
          'client_name',
          'displayName',
          'userName',
          'fromName',
          'userName',
        ])?.toString() ??
        'Danışan',
    clientAvatarUrl:
        pick(map, ['clientAvatarUrl', 'avatarUrl', 'image'])?.toString(),
    tellerId: pick(map, ['tellerId', 'teller_id', 'fortuneTellerId'])
            ?.toString() ??
        '',
    tellerUserId: pick(map, ['tellerUserId', 'teller_user_id', 'anchorUserId'])
        ?.toString(),
    durationMinutes: () {
      final duration = asInt(
        pick(map, [
          'durationMinutes',
          'duration',
          'minutes',
          'maxMinutes',
        ]),
      );
      return duration > 0 ? duration : 10;
    }(),
    totalJeton: asInt(
      pick(map, [
        'totalJeton',
        'total_jeton',
        'jeton',
        'amount',
        'creditsCharged',
      ]),
    ),
    fortuneType: pick(map, ['category', 'specialty', 'specialties', 'fortuneType'])
            ?.toString() ??
        'general',
    status: PsychicSessionStatus.fromApi(
      pick(map, ['status'])?.toString(),
      tellerResponse: pick(map, ['tellerResponse', 'response'])?.toString(),
    ),
  );
}

bool isPsychicInvitePayload(Map<String, dynamic>? raw) =>
    parsePsychicIncomingPayload(raw) != null;

PsychicRequestEntity? psychicInviteFromNotification(AppNotificationEntity n) {
  final type = (n.type ?? '').toLowerCase();
  final path = (n.targetPath ?? '').toLowerCase();
  final isFortuneInvite = type.contains('session_request') ||
      type.contains('fortune_session') ||
      type.contains('live_fortune') ||
      type.contains('fortune_teller') ||
      type.contains('fortune') ||
      type.contains('falc') ||
      path.contains('fal') ||
      path.contains('session');
  if (!isFortuneInvite) return null;

  final sessionId = _sessionIdFromNotification(n);
  if (sessionId == null || sessionId.isEmpty) return null;

  return PsychicRequestEntity(
    sessionId: sessionId,
    clientId: '',
    clientName: _clientNameFromNotification(n),
    tellerId: '',
    durationMinutes: 10,
    totalJeton: 0,
    fortuneType: 'general',
  );
}

String? _sessionIdFromNotification(AppNotificationEntity n) {
  final target = n.targetId?.trim();
  if (target != null && target.isNotEmpty) return target;

  final path = n.targetPath?.trim() ?? '';
  if (path.isNotEmpty) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty) {
      final last = segments.last;
      if (last.length >= 8 && last != 'dashboard' && last != 'session') {
        return last;
      }
    }
  }
  return null;
}

String _clientNameFromNotification(AppNotificationEntity n) {
  final title = n.title.trim();
  if (title.isEmpty) return 'Danışan';
  const prefixes = [
    'Canlı fal isteği:',
    'Canlı Fal İsteği:',
    'Yeni fal talebi:',
    'Yeni seans isteği:',
  ];
  for (final prefix in prefixes) {
    if (title.startsWith(prefix)) {
      final name = title.substring(prefix.length).trim();
      if (name.isNotEmpty) return name;
    }
  }
  return title;
}

bool isPsychicInviteNotification(AppNotificationEntity n) =>
    psychicInviteFromNotification(n) != null;

final psychicIncomingQueueFromPushProvider =
    NotifierProvider<PsychicPushQueue, List<PsychicRequestEntity>>(
  PsychicPushQueue.new,
);

class PsychicPushQueue extends Notifier<List<PsychicRequestEntity>> {
  @override
  List<PsychicRequestEntity> build() => const [];

  void enqueue(PsychicRequestEntity request) {
    if (request.sessionId.isEmpty) return;
    final exists = state.any((s) => s.sessionId == request.sessionId);
    if (!exists) {
      state = [...state, request];
    }
  }

  PsychicRequestEntity? takeNext() {
    if (state.isEmpty) return null;
    final next = state.first;
    state = state.sublist(1);
    return next;
  }

  void remove(String sessionId) {
    state = state.where((s) => s.sessionId != sessionId).toList();
  }
}
