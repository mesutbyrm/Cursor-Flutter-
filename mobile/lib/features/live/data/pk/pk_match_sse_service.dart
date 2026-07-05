import 'dart:async';

import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/sse/base_sse_service.dart';
import '../../domain/pk/pk_event_models.dart';
import '../../domain/pk/pk_room_models.dart';

/// PK maç SSE — `GET /api/pk/{id}/stream`.
/// Skor, süre, koltuk, takım ve premium etkinlik güncellemeleri.
class PkMatchSseService extends BaseSseService {
  PkMatchSseService()
      : _events = StreamController<PkMatchSseEvent>.broadcast();

  final StreamController<PkMatchSseEvent> _events;
  Stream<PkMatchSseEvent> get events => _events.stream;

  String? _matchId;
  void Function(PkMatchSseEvent event)? _onEvent;

  /// PK SSE her zaman games backend'e gider (`canlifalapi.abacusai.app`).
  @override
  Dio connectionDio() => createPkSseDio();

  static Dio createPkSseDio() {
    final base = Env.gamesApiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return Dio(
      BaseOptions(
        baseUrl: base.isNotEmpty ? base : Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: Duration.zero,
        headers: {
          'Accept': 'text/event-stream',
          'Connection': 'keep-alive',
        },
        persistentConnection: true,
      ),
    );
  }

  @override
  String streamPath() {
    final id = _matchId ?? '';
    return ApiEndpoints.pkMatchStream(id);
  }

  Future<void> connectToMatch({
    required String matchId,
    required Future<String?> Function() accessToken,
    void Function(PkMatchSseEvent event)? onEvent,
  }) async {
    final id = matchId.trim();
    if (id.isEmpty) return;
    _matchId = id;
    _onEvent = onEvent;
    await openConnection(accessToken: accessToken);
  }

  @override
  void onSseBlock(String block) {
    final map = BaseSseService.parseSseJsonBlock(block);
    if (map == null) return;
    final event = PkMatchSseEvent.fromJson(map);
    if (!_events.isClosed) _events.add(event);
    _onEvent?.call(event);
  }

  @override
  Future<void> disconnect() async {
    _matchId = null;
    _onEvent = null;
    await super.disconnect();
  }

  @override
  void dispose() {
    unawaited(disconnect());
    _events.close();
    super.dispose();
  }
}

/// SSE olay zarfı — `type` alanına göre yorumlanır.
class PkMatchSseEvent {
  const PkMatchSseEvent({
    required this.type,
    this.match,
    this.event,
    this.raw = const {},
  });

  final String type;
  final PkRoomMatch? match;
  final PkMatchEvent? event;
  final Map<String, dynamic> raw;

  factory PkMatchSseEvent.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? json['event'] ?? 'update').toString();
    PkRoomMatch? match;
    final matchRaw = json['match'] ?? json['data'] ?? json;
    if (matchRaw is Map) {
      final m = Map<String, dynamic>.from(matchRaw);
      if (m.containsKey('id') || m.containsKey('matchId')) {
        match = PkRoomMatch.fromJson(m);
      }
    }
    PkMatchEvent? event;
    final eventRaw = json['pkEvent'] ?? json['eventData'];
    if (eventRaw is Map) {
      event = PkMatchEvent.fromJson(Map<String, dynamic>.from(eventRaw));
    }
    return PkMatchSseEvent(type: type, match: match, event: event, raw: json);
  }

  bool get isScoreUpdate =>
      type == 'score' ||
      type == 'score_update' ||
      type == 'pk:score' ||
      type == 'match_update';

  bool get isEnded =>
      type == 'ended' || type == 'pk:end' || type == 'completed';

  bool get isEventUpdate =>
      type == 'event' || type == 'pk_event' || type == 'multiplier';
}
