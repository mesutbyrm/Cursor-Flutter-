import 'dart:async';

import '../../../live/domain/entities/live_gift_event.dart';
import '../datasources/chat_room_gifts_remote_datasource.dart';
/// REST poll — sesli oda hediyeleri (SSE/HTTP; Socket.IO yok).
class VoiceRoomGiftRealtimeService {
  VoiceRoomGiftRealtimeService(this._gifts);

  final ChatRoomGiftsRemoteDataSource _gifts;

  final _local = StreamController<LiveGiftEvent>.broadcast();
  final _seen = <String>{};

  Timer? _poll;
  String? _roomId;
  DateTime? _since;

  Stream<LiveGiftEvent> get events => _local.stream;

  void start(String roomId) {
    if (_roomId == roomId && _poll != null) return;
    stop();
    _roomId = roomId;
    _since = DateTime.now().subtract(const Duration(minutes: 2));
    _poll = Timer.periodic(const Duration(seconds: 6), (_) => _pollOnce());
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
