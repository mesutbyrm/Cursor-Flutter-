import 'dart:async';

import '../../data/datasources/live_fortune_remote_datasource.dart';
import '../../domain/entities/live_teller_review_entity.dart';

/// Canlı fal WebRTC — HTTP sinyalizasyon (`/api/room/signal`).
///
/// Socket.IO kullanılmaz. Üretim dokümanı §14: 1–2 sn poll.
class LiveFortuneRoomSignalService {
  LiveFortuneRoomSignalService(this._remote);

  final LiveFortuneRemoteDataSource _remote;

  Timer? _poll;
  String? _sessionId;
  void Function(LiveFortuneRoomSignalEntity signal)? onSignal;

  void start({
    required String sessionId,
    Duration interval = const Duration(milliseconds: 1500),
  }) {
    stop();
    _sessionId = sessionId.trim();
    if (_sessionId!.isEmpty) return;
    _poll = Timer.periodic(interval, (_) => _tick());
    unawaited(_tick());
  }

  void stop() {
    _poll?.cancel();
    _poll = null;
    _sessionId = null;
  }

  Future<void> send({
    required String sessionId,
    required String receiverId,
    required String signalType,
    required Map<String, dynamic> signalData,
  }) =>
      _remote.postRoomSignal(
        sessionId: sessionId,
        receiverId: receiverId,
        signalType: signalType,
        signalData: signalData,
      );

  Future<void> clearSignals(String sessionId) =>
      _remote.clearRoomSignals(sessionId);

  Future<void> _tick() async {
    final id = _sessionId;
    if (id == null || id.isEmpty) return;
    try {
      final signals = await _remote.pollRoomSignals(id);
      for (final sig in signals) {
        onSignal?.call(sig);
      }
    } catch (_) {}
  }

  void dispose() => stop();
}
