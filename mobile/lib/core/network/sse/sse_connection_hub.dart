import 'dart:async';

import '../../../features/live/data/datasources/live_gifts_remote_datasource.dart';
import '../../../features/voice_hub/data/services/chat_room_sse_service.dart';
import '../../../features/live/data/services/video_stream_sse_service.dart';

/// SSE kanal anahtarı — oda / yayın başına tek bağlantı.
enum SseChannelKind {
  voiceRoom,
  videoStream,
}

/// Merkezi SSE yönetimi — tek bağlantı, ref sayacı, sayfa geçişinde yeniden bağlanma yok.
class SseConnectionHub {
  SseConnectionHub({LiveGiftsRemoteDataSource? giftsRemote})
      : _giftsRemote = giftsRemote;

  LiveGiftsRemoteDataSource? _giftsRemote;

  final Map<String, _VoiceRoomLease> _voiceRooms = {};
  final Map<String, _VideoStreamLease> _videoStreams = {};

  void bindGiftsRemote(LiveGiftsRemoteDataSource giftsRemote) {
    _giftsRemote = giftsRemote;
  }

  /// Sesli oda SSE servisi — [roomId] başına tek instance.
  ChatRoomSseService voiceRoom(String roomId) {
    final id = roomId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(roomId, 'roomId', 'cannot be empty');
    }
    return _voiceRooms
        .putIfAbsent(id, () => _VoiceRoomLease(ChatRoomSseService()))
        .service;
  }

  /// Aktif oda SSE'sine abone sayacını artırır.
  void attachVoiceRoom(String roomId) {
    final id = roomId.trim();
    if (id.isEmpty) return;
    _voiceRooms.putIfAbsent(id, () => _VoiceRoomLease(ChatRoomSseService())).refCount++;
  }

  /// Abone sayacı sıfırlanınca bağlantıyı kapatır (başka sayfa hâlâ dinliyorsa açık kalır).
  void releaseVoiceRoom(String roomId) {
    final id = roomId.trim();
    final lease = _voiceRooms[id];
    if (lease == null) return;
    lease.refCount--;
    if (lease.refCount <= 0) {
      unawaited(lease.service.disconnect());
      _voiceRooms.remove(id);
    }
  }

  /// Odadan çıkış / oda değişimi — anında SSE kesilir (ref sayacı yok sayılır).
  void forceReleaseVoiceRoom(String roomId) {
    final id = roomId.trim();
    final lease = _voiceRooms[id];
    if (lease == null) return;
    lease.refCount = 0;
    unawaited(lease.service.disconnect());
    _voiceRooms.remove(id);
  }

  int voiceRoomRefCount(String roomId) =>
      _voiceRooms[roomId.trim()]?.refCount ?? 0;

  /// Video yayın SSE — [streamId] başına tek instance.
  VideoStreamSseService videoStream(String streamId) {
    final id = streamId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(streamId, 'streamId', 'cannot be empty');
    }
    return _videoStreams
        .putIfAbsent(
          id,
          () => _VideoStreamLease(
            VideoStreamSseService(_giftsRemote!),
          ),
        )
        .service;
  }

  void attachVideoStream(String streamId) {
    final id = streamId.trim();
    if (id.isEmpty || _giftsRemote == null) return;
    _videoStreams
        .putIfAbsent(
          id,
          () => _VideoStreamLease(VideoStreamSseService(_giftsRemote!)),
        )
        .refCount++;
  }

  void releaseVideoStream(String streamId) {
    final id = streamId.trim();
    final lease = _videoStreams[id];
    if (lease == null) return;
    lease.refCount--;
    if (lease.refCount <= 0) {
      unawaited(lease.service.disconnect());
      _videoStreams.remove(id);
    }
  }

  Future<void> dispose() async {
    for (final lease in Map.from(_voiceRooms).values) {
      await lease.service.disconnect();
    }
    _voiceRooms.clear();
    for (final lease in Map.from(_videoStreams).values) {
      await lease.service.disconnect();
    }
    _videoStreams.clear();
  }

  /// İnternet geri gelince aktif sesli oda SSE bağlantılarını yeniden kur.
  Future<void> reconnectAllActive() async {
    for (final lease in _voiceRooms.values) {
      if (lease.refCount > 0) {
        await lease.service.reconnectNow();
      }
    }
  }
}

class _VoiceRoomLease {
  _VoiceRoomLease(this.service);

  final ChatRoomSseService service;
  int refCount = 0;
}

class _VideoStreamLease {
  _VideoStreamLease(this.service);

  final VideoStreamSseService service;
  int refCount = 0;
}
