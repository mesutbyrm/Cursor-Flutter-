import 'dart:async';

import '../../domain/entities/live_gift_event.dart';
import '../datasources/live_gifts_remote_datasource.dart';

/// REST poll + yerel olay hattı (socket LiveRoomController üzerinden).
class LiveGiftRealtimeService {
  LiveGiftRealtimeService(this._remote);

  final LiveGiftsRemoteDataSource _remote;
  final _local = StreamController<LiveGiftEvent>.broadcast();
  final Set<String> _seen = {};
  final Map<String, DateTime> _fingerprints = {};

  Timer? _pollTimer;
  String? _streamId;
  DateTime? _since;

  Stream<LiveGiftEvent> get events => _local.stream;

  void start(String streamId) {
    if (_streamId == streamId && _pollTimer != null) return;
    stop();
    _streamId = streamId;
    _since = DateTime.now().subtract(const Duration(minutes: 2));
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _poll());
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

  void resetDedupeState() {
    _seen.clear();
    _fingerprints.clear();
  }

  String _fingerprint(LiveGiftEvent e) {
    final sender = (e.senderId ?? e.senderName).trim().toLowerCase();
    final receiver = (e.receiverId ?? e.receiverName).trim().toLowerCase();
    final gift = e.giftId.trim().isNotEmpty ? e.giftId : e.giftName;
    return '$sender|$receiver|$gift|${e.quantity}|${e.jetonAmount}';
  }

  bool _isDuplicateFingerprint(LiveGiftEvent event) {
    final fp = _fingerprint(event);
    final prev = _fingerprints[fp];
    final now = event.timestamp;
    if (prev != null && now.difference(prev).inMilliseconds.abs() < 4000) {
      return true;
    }
    _fingerprints[fp] = now;
    if (_fingerprints.length > 64) {
      final cutoff = now.subtract(const Duration(seconds: 30));
      _fingerprints.removeWhere((_, t) => t.isBefore(cutoff));
    }
    return false;
  }

  /// Yerel animasyon devre dışı — hediyeler yalnızca SSE/socket/poll üzerinden oynar.
  void publishLocal(LiveGiftEvent event) {}

  void publishRemote(LiveGiftEvent event) {
    if (!_seen.add(event.id)) return;
    if (_isDuplicateFingerprint(event)) return;
    if (!_local.isClosed) _local.add(event);
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
        publishRemote(e);
        if (e.timestamp.isAfter(_since ?? e.timestamp)) {
          _since = e.timestamp;
        }
      }
    } catch (_) {}
  }
}
