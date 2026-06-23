import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/util/json_util.dart';
import '../../../notifications/domain/entities/app_notification_entity.dart';
import '../../domain/entities/psychic_request_entity.dart';
import '../../domain/entities/psychic_session_status.dart';

Map<String, dynamic> flattenPsychicPushPayload(Map<String, dynamic> raw) {
  var map = Map<String, dynamic>.from(raw);
  for (final key in const ['data', 'payload', 'custom', 'additionalData']) {
    final nested = map[key];
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

/// Üretim push/SSE tipleri — `psychic_request_created` dahil.
bool isPsychicInviteEventType(String type) {
  final t = type.trim().toLowerCase();
  if (t.isEmpty) return false;
  if (t.contains('session_update') || t.contains('session_ended')) return false;

  const known = {
    'fortune_session_invite',
    'psychic_request_created',
    'psychic_request',
    'request_created',
    'fortune_session_request',
    'live_fortune_request',
    'session_request',
    'fortune_request',
    'live_fal_request',
    'fal_request',
    'private_fal_request',
  };
  if (known.contains(t)) return true;

  return t.contains('session_request') ||
      t.contains('psychic_request') ||
      t.contains('request_created') ||
      (t.contains('psychic') && t.contains('request')) ||
      (t.contains('fortune') && t.contains('request')) ||
      t.contains('fortune') ||
      t.contains('falc') ||
      t.contains('live_fortune') ||
      t.contains('live_session') ||
      t.contains('live_fal');
}

Map<String, dynamic> mergePsychicInviteNestedFields(Map<String, dynamic> map) {
  var merged = Map<String, dynamic>.from(map);
  for (final key in const ['request', 'session', 'invite', 'liveSession']) {
    final nested = merged[key];
    if (nested is Map) {
      merged = {...merged, ...asJsonMap(nested)};
    }
  }
  final client = merged['client'] ?? merged['user'];
  if (client is Map) {
    final c = asJsonMap(client);
    merged.putIfAbsent('clientId', () => pick(c, ['id', 'userId', 'clientId']));
    merged.putIfAbsent('clientName', () => pick(c, [
          'displayName',
          'name',
          'username',
          'clientName',
        ]));
    merged.putIfAbsent(
      'clientAvatarUrl',
      () => pick(c, ['avatarUrl', 'image', 'avatar']),
    );
  }
  return merged;
}

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
  bool get isCancelled =>
      action == 'cancel' || action == 'cancelled' || action == 'canceled';
}

/// İptal / red push — bekleme ve falcı dialog'unu anında kapatır.
PsychicSessionUpdatePayload? parsePsychicSessionCancelledPayload(
  Map<String, dynamic>? raw,
) {
  if (raw == null || raw.isEmpty) return null;
  final map = flattenPsychicPushPayload(raw);
  final type = psychicPushType(map);
  if (!type.contains('cancel') &&
      !type.contains('declin') &&
      !type.contains('reject')) {
    return null;
  }
  if (type.contains('session_ended')) return null;

  final sessionId = pick(map, [
    'sessionId',
    'session_id',
    'targetId',
    'target_id',
    'id',
    'requestId',
    'liveSessionId',
  ])?.toString() ??
      sessionIdFromTargetPath(map['targetPath']);
  if (sessionId == null || sessionId.isEmpty) return null;

  final action = pick(map, ['action', 'status'])?.toString().toLowerCase() ??
      (type.contains('cancel') ? 'cancel' : 'reject');
  return PsychicSessionUpdatePayload(
    sessionId: sessionId,
    action: action,
    tellerId: pick(map, ['tellerId', 'teller_id', 'fortuneTellerId'])
        ?.toString(),
  );
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

  final flat = flattenPsychicPushPayload(raw);
  final map = mergePsychicInviteNestedFields(flat);
  final type = psychicPushType(map);

  if (type.contains('session_update') || type.contains('session_ended')) {
    return null;
  }

  final looksLikeFortune = isPsychicInviteEventType(type) ||
      (map.containsKey('sessionId') &&
          (map.containsKey('tellerId') ||
              map.containsKey('clientId') ||
              map.containsKey('userId'))) ||
      ((map.containsKey('targetId') || map.containsKey('target_id')) &&
          (isPsychicInviteEventType(type) ||
              type.contains('live') ||
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
        'liveSessionId',
      ])?.toString() ??
      sessionIdFromTargetPath(map['targetPath']);
  if (sessionId == null || sessionId.isEmpty) return null;

  final inviteStatus = isPsychicInviteEventType(type)
      ? PsychicSessionStatus.pending
      : PsychicSessionStatus.fromApi(
          pick(map, ['status'])?.toString(),
          tellerResponse: pick(map, ['tellerResponse', 'response'])?.toString(),
        );

  return PsychicRequestEntity(
    sessionId: sessionId,
    clientId:
        pick(map, ['clientId', 'client_id'])?.toString() ?? '',
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
    status: inviteStatus,
  );
}

/// OneSignal yalnızca targetId gönderdiğinde minimal davet.
PsychicRequestEntity? parsePsychicIncomingLoose(
  Map<String, dynamic>? raw, {
  String? title,
  String? body,
}) {
  final fromPayload = parsePsychicIncomingPayload(raw);
  if (fromPayload != null) return fromPayload;

  final map = raw != null ? flattenPsychicPushPayload(raw) : <String, dynamic>{};
  final titleText = title ?? map['title']?.toString();
  final bodyText = body ?? map['body']?.toString();
  final type = psychicPushType(map);
  final sessionId = pick(map, [
        'sessionId',
        'session_id',
        'targetId',
        'target_id',
        'id',
      ])?.toString() ??
      sessionIdFromTargetPath(map['targetPath']);
  if (sessionId == null || sessionId.isEmpty) return null;

  final looksLikeInvite = isPsychicInviteEventType(type) ||
      type.contains('psychic') ||
      type.contains('fortune') ||
      type.contains('fal') ||
      (titleText ?? '').toLowerCase().contains('fal') ||
      (bodyText ?? '').toLowerCase().contains('fal');

  if (!looksLikeInvite) return null;

  return PsychicRequestEntity(
    sessionId: sessionId,
    clientId: pick(map, ['clientId', 'client_id'])?.toString() ?? '',
    clientName: pick(map, ['clientName', 'displayName'])?.toString() ??
        _clientNameFromTitle(titleText),
    tellerId: pick(map, ['tellerId', 'fortuneTellerId'])?.toString() ?? '',
    durationMinutes: 10,
    totalJeton: asInt(pick(map, ['totalJeton', 'jeton'])),
    fortuneType: 'general',
    status: PsychicSessionStatus.pending,
  );
}

String _clientNameFromTitle(String? title) {
  final t = title?.trim() ?? '';
  if (t.isEmpty) return 'Danışan';
  const prefixes = [
    'Canlı fal isteği:',
    'Canlı Fal İsteği:',
    'Yeni fal talebi:',
    'Yeni seans isteği:',
  ];
  for (final prefix in prefixes) {
    if (t.startsWith(prefix)) {
      final name = t.substring(prefix.length).trim();
      if (name.isNotEmpty) return name;
    }
  }
  return t;
}

bool isPsychicInvitePayload(Map<String, dynamic>? raw) =>
    parsePsychicIncomingPayload(raw) != null;

PsychicRequestEntity? psychicInviteFromNotification(AppNotificationEntity n) {
  final type = (n.type ?? '').toLowerCase();
  final path = (n.targetPath ?? '').toLowerCase();
  final isFortuneInvite = isPsychicInviteEventType(type) ||
      type.contains('fortune_session') ||
      type.contains('fortune_teller') ||
      path.contains('fal') ||
      path.contains('session') ||
      path.contains('canli-falcilar');
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

/// Danışanın kendi oluşturduğu istek — yalnızca açık `clientId` ile.
bool isPsychicInviteForClientUser(
  String authUserId,
  PsychicRequestEntity invite,
) {
  final uid = authUserId.trim();
  if (uid.isEmpty) return false;
  final clientId = invite.clientId.trim();
  if (clientId.isEmpty) return false;
  return clientId == uid;
}

/// Falcı cihazında gösterilecek gelen davet mi?
bool shouldPresentPsychicIncomingInvite({
  required String? authUserId,
  required PsychicRequestEntity invite,
  String? tellerProfileId,
  bool isFortuneTeller = false,
}) {
  final uid = authUserId?.trim() ?? '';
  if (uid.isEmpty) return true;
  if (isPsychicInviteForClientUser(uid, invite)) return false;

  final tellerUid = invite.tellerUserId?.trim() ?? '';
  if (tellerUid.isNotEmpty && tellerUid == uid) return true;

  final profileId = tellerProfileId?.trim() ?? '';
  if (profileId.isNotEmpty && invite.tellerId.trim() == profileId) return true;
  if (invite.tellerId.trim() == uid) return true;

  // Onaylı falcı: danışan değilse gelen isteği göster (clientId boş push dahil).
  if (isFortuneTeller || profileId.isNotEmpty) {
    final clientId = invite.clientId.trim();
    return clientId.isEmpty || clientId != uid;
  }

  // Danışan: clientId yoksa minimal push — kendi isteği olabilir, dialog açma.
  final clientId = invite.clientId.trim();
  if (clientId.isEmpty) return false;
  return clientId != uid;
}

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
