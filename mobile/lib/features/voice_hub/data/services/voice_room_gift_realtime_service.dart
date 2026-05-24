import 'dart:async';

import '../../../live/data/datasources/live_gifts_remote_datasource.dart';
import '../../../live/domain/entities/live_gift_event.dart';
import '../datasources/chat_room_gifts_remote_datasource.dart';
import 'voice_room_gift_socket.dart';

/// REST poll + socket — sesli oda hediye olayları.
class VoiceRoomGiftRealtimeService {
  VoiceRoomGiftRealtimeService(this._gifts, this._socket);

  final ChatRoomGiftsRemoteDataSource _gifts;
  final VoiceRoomGiftSocket _socket;

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
    _socket.connect(
      roomId: roomId,
      onEvent: (e) {
        if (_seen.add(e.id) && !_local.isClosed) _local.add(e);
      },
    );
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _pollOnce());
    _pollOnce();
  }

  void stop() {
    _poll?.cancel();
    _poll = null;
    _socket.disconnect();
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
