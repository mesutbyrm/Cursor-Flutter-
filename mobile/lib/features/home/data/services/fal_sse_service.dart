import 'dart:async';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/sse/base_sse_service.dart';
import '../../../home/domain/entities/live_fortune_session_entity.dart';
import '../../../home/presentation/providers/fortune_live_event_bus.dart';

/// Canlı fal seans SSE — `GET /api/room/{sessionId}/stream`.
class FalSseService extends BaseSseService {
  FalSseService() : _events = StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<Map<String, dynamic>> _events;
  Stream<Map<String, dynamic>> get events => _events.stream;

  String? _sessionId;

  void Function(FortuneIncomingSession request)? _onFortuneRequest;
  void Function(Map<String, dynamic> payload)? _onSessionUpdate;

  @override
  String streamPath() => ApiEndpoints.liveFortuneRoomStream(_sessionId ?? '');

  Future<void> connectToSession({
    required String sessionId,
    required Future<String?> Function() accessToken,
    void Function(FortuneIncomingSession request)? onFortuneRequest,
    void Function(Map<String, dynamic> payload)? onSessionUpdate,
  }) async {
    final id = sessionId.trim();
    if (id.isEmpty) return;
    _sessionId = id;
    _onFortuneRequest = onFortuneRequest;
    _onSessionUpdate = onSessionUpdate;
    await super.connect(accessToken: accessToken);
  }

  @override
  void onSseBlock(String block) {
    final map = BaseSseService.parseSseJsonBlock(block);
    if (map == null) return;
    if (!_events.isClosed) _events.add(map);

    final session = parseFortuneSsePayload(map);
    if (session != null) _onFortuneRequest?.call(session);
    _onSessionUpdate?.call(map);
  }

  @override
  Future<void> disconnect() async {
    _sessionId = null;
    _onFortuneRequest = null;
    _onSessionUpdate = null;
    await super.disconnect();
  }

  @override
  void dispose() {
    unawaited(disconnect());
    _events.close();
    super.dispose();
  }
}
