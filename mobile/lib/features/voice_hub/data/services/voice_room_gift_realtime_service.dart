import 'dart:async';

import '../../../live/domain/entities/live_gift_event.dart';
import '../datasources/chat_room_gifts_remote_datasource.dart';

/// REST poll — sesli oda hediyeleri (socket yedek).
class VoiceRoomGiftRealtimeService {
  VoiceRoomGiftRealtimeService(this._gifts);

  final ChatRoomGiftsRemoteDataSource _gifts;

  final _local = StreamController<LiveGiftEvent>.broadcast();
  final _seen = <String>{};

  Timer? _poll;
  String? _roomId;
  DateTime? _since;
  var _socketPreferred = false;

  Stream<LiveGiftEvent> get events => _local.stream;

  /// Socket.IO aktifken REST poll seyrekleştirilir.
  void setSocketPreferred(bool preferred) {
    _socketPreferred = preferred;
    if (_roomId != null) {
      stop();
      start(_roomId!);
    }
  }

  void start(String roomId) {
    if (_roomId == roomId && _poll != null) return;
    stop();
    _roomId = roomId;
    _since = DateTime.now().subtract(const Duration(minutes: 2));
    final interval = _socketPreferred
        ? const Duration(seconds: 30)
        : const Duration(seconds: 12);
    _poll = Timer.periodic(interval, (_) => _pollOnce());
    _pollOnce();
  }

  void stop() {
    _poll?.cancel();
    _poll = null;
    _roomId = null;
  }

  void publishLocal(LiveGiftEvent event) {
    _seen.add(event.id);
    if (!_local.isClosed) _local.add(event);
  }

  void publishRemote(LiveGiftEvent event) {
    if (_seen.add(event.id) && !_local.isClosed) _local.add(event);
  }

  void dispose() {
    stop();
    _local.close();
  }

  Future<void> _pollOnce() async {
    final id = _roomId;
    if (id == null) return;
    try {
      final batch = await _gifts.fetchRoomGiftEvents(
        roomId: id,
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
