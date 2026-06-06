import 'dart:async';

import '../../domain/entities/live_gift_event.dart';
import '../datasources/live_gifts_remote_datasource.dart';

/// REST poll + yerel olay hattı (socket LiveRoomController üzerinden).
class LiveGiftRealtimeService {
  LiveGiftRealtimeService(this._remote);

  final LiveGiftsRemoteDataSource _remote;
  final _local = StreamController<LiveGiftEvent>.broadcast();
  final Set<String> _seen = {};

  Timer? _pollTimer;
  String? _streamId;
  DateTime? _since;

  Stream<LiveGiftEvent> get events => _local.stream;

  void start(String streamId) {
    if (_streamId == streamId && _pollTimer != null) return;
    stop();
    _streamId = streamId;
    _since = DateTime.now().subtract(const Duration(minutes: 2));
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
    _poll();
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _streamId = null;
  }

  void dispose() {
    stop();
    _local.close();
  }

  void publishLocal(LiveGiftEvent event) {
    _seen.add(event.id);
    if (!_local.isClosed) _local.add(event);
  }

  void publishRemote(LiveGiftEvent event) {
    if (_seen.add(event.id) && !_local.isClosed) _local.add(event);
  }

  Future<void> _poll() async {
    final id = _streamId;
    if (id == null || id.isEmpty) return;
    try {
      final batch = await _remote.fetchStreamGiftEvents(
        streamId: id,
        since: _since,
      );
      for (final e in batch) {
        if (_seen.add(e.id)) {
          if (!_local.isClosed) _local.add(e);
        }
        if (e.timestamp.isAfter(_since ?? e.timestamp)) {
          _since = e.timestamp;
        }
      }
    } catch (_) {}
  }
}
