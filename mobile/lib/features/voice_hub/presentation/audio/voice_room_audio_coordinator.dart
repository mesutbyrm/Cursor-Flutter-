import 'dart:async';

import '../../../agora/data/datasources/agora_remote_datasource.dart';
import '../../data/datasources/chat_room_remote_datasource.dart';
import '../../data/services/voice_room_debug_log.dart';
import '../../domain/entities/voice_audio_engine.dart';
import 'voice_agora_engine.dart';
import 'voice_room_music_audio_session.dart';

/// canlifal.com sesli oda — Agora token + `POST /voice` `{type: join}`.
class VoiceRoomAudioCoordinator {
  VoiceRoomAudioCoordinator({
    VoiceAgoraEngine? agora,
    ChatRoomRemoteDataSource? remote,
    AgoraRemoteDataSource? agoraToken,
  })  : _agora = agora ?? VoiceAgoraEngine(tokenSource: agoraToken),
        _remote = remote;

  final VoiceAgoraEngine _agora;
  final ChatRoomRemoteDataSource? _remote;

  VoiceAudioEngineKind? _engine;
  VoiceAudioEngineKind? get engine => _engine;

  bool get micOn => _agora.micOn;
  bool get isSupported => _agora.isSupported;

  /// [roomId] = Prisma oda kimliği (Agora kanal adı).
  Future<VoiceAudioEngineKind> join({
    required String roomId,
    ChatRoomRemoteDataSource? remote,
    bool enableMic = true,
  }) async {
    unawaited(VoiceRoomMusicAudioSession.ensureConfigured());
    final ds = remote ?? _remote;
    if (ds == null) {
      throw StateError('Sesli oda API yapılandırması eksik');
    }
    final channel = roomId.trim();
    if (channel.isEmpty) {
      throw StateError('Oda kimliği boş');
    }

    VoiceRoomDebugLog.log('audio.agora.prepare', {'roomId': channel});
    _lastRoomId = channel;

    if (!enableMic) {
      _engine = VoiceAudioEngineKind.agora;
      return _engine!;
    }

    await ds.joinVoiceSession(channel);
    await _agora.joinVoice(channel, publishMic: true);
    _engine = VoiceAudioEngineKind.agora;
    VoiceRoomDebugLog.log('audio.agora.joined', {'roomId': channel});
    return _engine!;
  }

  void setMicEnabled(bool enabled) {
    if (enabled) {
      if (!_agora.inChannel && _lastRoomId != null) {
        unawaited(_joinVoiceNow(_lastRoomId!));
      } else {
        _agora.setMicEnabled(true);
      }
      return;
    }
    _agora.setMicEnabled(false);
    final ds = _remote;
    final channel = _lastRoomId;
    if (ds != null && channel != null && channel.isNotEmpty) {
      unawaited(ds.leaveVoiceSession(channel));
    }
  }

  Future<void> _joinVoiceNow(String roomId) async {
    final ds = _remote;
    if (ds == null) return;
    try {
      await ds.joinVoiceSession(roomId);
      await _agora.joinVoice(roomId, publishMic: true);
      _engine = VoiceAudioEngineKind.agora;
    } catch (e, st) {
      VoiceRoomDebugLog.log('audio.agora.mic_join.fail', {
        'error': e.toString(),
        'stack': st.toString(),
      });
      rethrow;
    }
  }

  void setHeadphonesOn(bool on) => _agora.setRemoteAudioMuted(!on);

  Future<void> leave() async {
    final ds = _remote;
    final channel = _agora.inChannel ? _lastRoomId : null;
    if (ds != null && channel != null && channel.isNotEmpty) {
      try {
        await ds.leaveVoiceSession(channel);
      } catch (_) {}
    }
    await _agora.leave();
    _engine = null;
    _lastRoomId = null;
  }

  String? _lastRoomId;

  /// Oturum sonlandırma — Agora + voice API leave.
  Future<void> leaveRoom(String roomId) async {
    _lastRoomId = roomId.trim();
    await leave();
  }

  void dispose() {
    unawaited(_agora.dispose());
    _engine = null;
  }
}
