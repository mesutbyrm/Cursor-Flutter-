import 'dart:async';

import 'package:flutter/foundation.dart';

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
  var _sseActive = false;

  /// SSE bağlı olsa da REST yedek poll açık — üretimde hediye Socket.IO üzerinden gelebilir.
  void setSseActive(bool active) {
    _sseActive = active;
    if (_streamId != null && _streamId!.isNotEmpty) {
      if (_pollTimer == null) start(_streamId!);
    }
  }

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
    _realtimeFingerprints.clear();
  }

  String _fingerprint(LiveGiftEvent e) {
    final sender = (e.senderId ?? e.senderName).trim().toLowerCase();
    final receiver = (e.receiverId ?? e.receiverName).trim().toLowerCase();
    final gift = e.giftId.trim().isNotEmpty ? e.giftId : e.giftName;
    return '$sender|$receiver|$gift|${e.quantity}|${e.jetonAmount}';
  }

  /// SSE/socket ile gelen her hediyenin parmak izi (aynı hediye art arda
  /// gönderilebilir — her biri ayrı kayıt).
  final Map<String, List<DateTime>> _realtimeFingerprints = {};

  void _recordRealtimeFingerprint(LiveGiftEvent event) {
    final list = _realtimeFingerprints.putIfAbsent(
      _fingerprint(event),
      () => <DateTime>[],
    );
    list.add(event.timestamp);
    if (list.length > 32) list.removeAt(0);
    if (_realtimeFingerprints.length > 64) {
      final cutoff = event.timestamp.subtract(const Duration(seconds: 30));
      _realtimeFingerprints.removeWhere((_, ts) {
        ts.removeWhere((t) => t.isBefore(cutoff));
        return ts.isEmpty;
      });
    }
  }

  /// REST yedek poll'u SSE'de farklı id ile gelmiş aynı hediyeyi tekrar
  /// üretmesin: eşleşen bir SSE kaydı tüketilir. Önceden süzgeç SSE olaylarına
  /// da uygulanıyordu → aynı hediye 4 sn içinde ikinci kez gönderilince
  /// ikinci hediye tamamen düşüyordu (video/feed yok).
  bool _consumeRealtimeFingerprint(LiveGiftEvent event) {
    final list = _realtimeFingerprints[_fingerprint(event)];
    if (list == null || list.isEmpty) return false;
    final i = list.indexWhere(
      (t) => event.timestamp.difference(t).inMilliseconds.abs() < 4000,
    );
    if (i < 0) return false;
    list.removeAt(i);
    return true;
  }

  /// Yerel animasyon devre dışı — hediyeler yalnızca SSE/socket/poll üzerinden oynar.
  void publishLocal(LiveGiftEvent event) {}

  void publishRemote(LiveGiftEvent event) {
    if (!_seen.add(event.id)) return;
    _recordRealtimeFingerprint(event);
    if (!_local.isClosed) _local.add(event);
  }

  @visibleForTesting
  void publishPolled(LiveGiftEvent event) {
    if (!_seen.add(event.id)) return;
    if (_consumeRealtimeFingerprint(event)) return;
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
        publishPolled(e);
        if (e.timestamp.isAfter(_since ?? e.timestamp)) {
          _since = e.timestamp;
        }
      }
    } catch (_) {}
  }
}
