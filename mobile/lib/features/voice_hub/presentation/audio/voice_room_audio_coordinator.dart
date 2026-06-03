import 'package:flutter/foundation.dart';

import '../../../../core/config/env.dart';
import '../../../livekit/data/datasources/livekit_remote_datasource.dart';
import '../../../livekit/presentation/livekit_room_manager.dart';
import '../../../trtc/data/datasources/trtc_remote_datasource.dart';
import '../../../trtc/presentation/trtc_room_manager.dart';
import '../../domain/entities/voice_audio_engine.dart';

/// LiveKit öncelikli, TRTC yedek — sesli sohbet ses katmanı.
class VoiceRoomAudioCoordinator {
  VoiceRoomAudioCoordinator({
    LiveKitRoomManager? liveKit,
    TrtcRoomManager? trtc,
    LiveKitRemoteDataSource? liveKitRemote,
    TrtcRemoteDataSource? trtcRemote,
  })  : _liveKit = liveKit ?? LiveKitRoomManager(),
        _trtc = trtc ?? TrtcRoomManager(),
        _liveKitRemote = liveKitRemote,
        _trtcRemote = trtcRemote;

  final LiveKitRoomManager _liveKit;
  final TrtcRoomManager _trtc;
  final LiveKitRemoteDataSource? _liveKitRemote;
  final TrtcRemoteDataSource? _trtcRemote;

  VoiceAudioEngineKind? _engine;
  VoiceAudioEngineKind? get engine => _engine;

  bool get micOn {
    if (_engine == VoiceAudioEngineKind.livekit) return _liveKit.micOn;
    return _trtc.micOn;
  }

  bool get isSupported => _liveKit.isSupported || _trtc.isSupported;

  Future<VoiceAudioEngineKind> join({
    required String roomId,
    required String userId,
    required bool isHost,
    LiveKitRemoteDataSource? liveKitRemote,
    TrtcRemoteDataSource? trtcRemote,
  }) async {
    final lkRemote = liveKitRemote ?? _liveKitRemote;
    final trtcDs = trtcRemote ?? _trtcRemote;

    final siteUsesTrtc =
        Env.apiBaseUrl.toLowerCase().contains('canlifal.com');
    if (!Env.forceTrtc &&
        !siteUsesTrtc &&
        Env.preferLiveKit &&
        lkRemote != null &&
        _liveKit.isSupported) {
      try {
        final cred = await lkRemote.fetchToken(roomId: roomId, roomName: roomId);
        await _liveKit.join(credentials: cred, enableMic: true);
        _engine = VoiceAudioEngineKind.livekit;
        debugPrint('Voice room audio: LiveKit');
        return _engine!;
      } catch (e) {
        debugPrint('LiveKit join failed, TRTC fallback: $e');
      }
    }

    if (!_trtc.isSupported) {
      throw StateError('Sesli oda bu platformda desteklenmiyor');
    }
    if (trtcDs == null) {
      throw StateError('TRTC yapılandırması eksik');
    }

    final cred = await trtcDs.fetchUserSig(userId: userId, roomId: roomId);
    await _trtc.join(
      credentials: cred,
      isHost: isHost,
      audioOnly: true,
    );
    _engine = VoiceAudioEngineKind.trtc;
    debugPrint('Voice room audio: TRTC');
    return _engine!;
  }

  void setMicEnabled(bool enabled) {
    if (_engine == VoiceAudioEngineKind.livekit) {
      _liveKit.setMicEnabled(enabled);
    } else {
      _trtc.setMicEnabled(enabled);
    }
  }

  void setHeadphonesOn(bool on) {
    final muted = !on;
    if (_engine == VoiceAudioEngineKind.livekit) {
      _liveKit.setRemoteAudioMuted(muted);
    } else if (_engine != null) {
      _trtc.setAllRemoteAudioMuted(muted);
    }
  }

  Future<void> leave() async {
    await _liveKit.leave();
    await _trtc.leave();
    _engine = null;
  }

  void dispose() {
    _liveKit.dispose();
    _trtc.dispose();
  }
}
