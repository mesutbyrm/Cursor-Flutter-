import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../trtc/presentation/trtc_room_manager.dart';
import '../domain/entities/livekit_credentials.dart';

/// LiveKit sesli oda — WebRTC tabanlı (TRTC alternatifi).
class LiveKitRoomManager {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  var _micOn = true;
  var _inRoom = false;

  bool get isSupported => !kIsWeb;
  bool get inRoom => _inRoom;
  bool get micOn => _micOn;

  Future<void> join({
    required LiveKitCredentials credentials,
    bool enableMic = true,
  }) async {
    if (!isSupported) {
      throw StateError('LiveKit yalnızca Android/iOS üzerinde desteklenir');
    }

    final micOk = await TrtcRoomManager.requestPermissions(video: false);
    if (!micOk) {
      throw StateError('Mikrofon izni verilmedi');
    }

    await leave();

    final room = Room();
    _listener = room.createListener();
    _listener?.on<RoomDisconnectedEvent>((_) {
      _inRoom = false;
    });

    await room.connect(
      credentials.url,
      credentials.token,
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultAudioPublishOptions: AudioPublishOptions(
          dtx: true,
        ),
      ),
    );

    await room.localParticipant?.setMicrophoneEnabled(enableMic);
    _micOn = enableMic;
    _room = room;
    _inRoom = true;
  }

  void setMicEnabled(bool enabled) {
    _micOn = enabled;
    _room?.localParticipant?.setMicrophoneEnabled(enabled);
  }

  /// Kulaklık kapalıyken uzak sesleri yerelde susturur (TRTC muteAllRemoteAudio ile aynı).
  void setRemoteAudioMuted(bool muted) {
    final room = _room;
    if (room == null) return;
    for (final p in room.remoteParticipants.values) {
      for (final pub in p.audioTrackPublications) {
        final track = pub.track;
        if (track == null) continue;
        if (muted) {
          track.stop();
        } else {
          track.start();
        }
      }
    }
  }

  Future<void> leave() async {
    _listener?.dispose();
    _listener = null;
    if (_room != null) {
      await _room!.disconnect();
    }
    _room = null;
    _inRoom = false;
  }

  void dispose() {
    leave();
  }
}
