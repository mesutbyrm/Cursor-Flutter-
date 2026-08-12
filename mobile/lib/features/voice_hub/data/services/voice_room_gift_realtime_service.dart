import 'dart:async';

import '../../../live/domain/entities/live_gift_event.dart';
import '../datasources/chat_room_gifts_remote_datasource.dart';

/// REST poll — sesli oda hediyeleri (socket yedek).
class VoiceRoomGiftRealtimeService {
  VoiceRoomGiftRealtimeService(this._gifts);

  final ChatRoomGiftsRemoteDataSource _gifts;

  final _local = StreamController<LiveGiftEvent>.broadcast();
  final _seen = <String>{};
  final Map<String, DateTime> _fingerprints = {};

  Timer? _poll;
  String? _roomId;
  DateTime? _since;
  var _socketPreferred = false;
  var _sseActive = false;

  /// SSE bağlıyken REST hediye poll kapalı — animasyon yalnızca SSE'den.
  void setSseActive(bool active) {
    _sseActive = active;
    if (active) stop();
  }

  Stream<LiveGiftEvent> get events => _local.stream;

  /// Socket.IO aktifken REST poll kapalı; yalnızca socket kesilirse yeniden açılır.
  void setSocketPreferred(bool preferred) {
    _socketPreferred = preferred;
    if (_roomId != null) {
      stop();
      if (!preferred) start(_roomId!);
    }
  }

  void start(String roomId) {
    if (_roomId == roomId && _poll != null) return;
    stop();
    _roomId = roomId;
    _since = DateTime.now().subtract(const Duration(minutes: 2));
    final interval = _socketPreferred
        ? const Duration(seconds: 20)
        : const Duration(seconds: 6);
    _poll = Timer.periodic(interval, (_) => _pollOnce());
    _pollOnce();
  }

  void stop() {
    _poll?.cancel();
    _poll = null;
    _roomId = null;
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
    if (_seen.length > 2048) {
      _seen.remove(_seen.first);
    }
    if (_isDuplicateFingerprint(event)) return;
    if (!_local.isClosed) _local.add(event);
  }

  void dispose() {
    stop();
    _local.close();
  }

  /// Oda çıkışı — dedupe setlerini sıfırla (bellek sızıntısı önleme).
  void resetDedupeState() {
    _seen.clear();
    _fingerprints.clear();
  }

  Future<void> _pollOnce() async {
    if (_sseActive) return;
    final id = _roomId;
    if (id == null) return;
    try {
      final batch = await _gifts.fetchRoomGiftEvents(
        roomId: id,
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
