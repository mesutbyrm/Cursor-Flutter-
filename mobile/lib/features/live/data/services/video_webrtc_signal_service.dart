import 'dart:async';

import '../datasources/live_stream_extras_datasource.dart';

/// HTTP polling — `GET/POST /api/video-streams/{id}/signal`
class VideoWebrtcSignalService {
  VideoWebrtcSignalService(this._remote);

  final LiveStreamExtrasDataSource _remote;

  Timer? _poll;
  String? _streamId;
  String? _since;
  void Function(Map<String, dynamic> signal)? onSignal;

  void start({
    required String streamId,
    Duration interval = const Duration(seconds: 2),
  }) {
    stop();
    _streamId = streamId;
    _since = null;
    _poll = Timer.periodic(interval, (_) => _tick());
    unawaited(_tick());
  }

  void stop() {
    _poll?.cancel();
    _poll = null;
    _streamId = null;
    _since = null;
  }

  Future<void> send({
    required String streamId,
    required String type,
    required Map<String, dynamic> payload,
  }) =>
      _remote.postSignal(streamId: streamId, type: type, payload: payload);

  Future<void> _tick() async {
    final id = _streamId;
    if (id == null || id.isEmpty) return;
    try {
      final signals = await _remote.pollSignals(id, since: _since);
      for (final sig in signals) {
        final created = sig['createdAt']?.toString();
        if (created != null && created.isNotEmpty) {
          _since = created;
        }
        onSignal?.call(sig);
      }
    } catch (_) {}
  }

  void dispose() => stop();
}
