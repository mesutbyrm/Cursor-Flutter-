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

  Future<void>? _micOp;

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

    VoiceRoomDebugLog.log('audio.agora.prepare', {
      'roomId': channel,
      'enableMic': enableMic,
    });
    _lastRoomId = channel;

    await ds.joinVoiceSession(channel);
    await _agora.joinVoice(channel, publishMic: enableMic);
    _engine = VoiceAudioEngineKind.agora;
    VoiceRoomDebugLog.log('audio.agora.joined', {
      'roomId': channel,
      'mic': enableMic,
    });
    return _engine!;
  }

  void setMicEnabled(bool enabled) {
    _micOp = _setMicEnabledSafe(enabled);
    unawaited(_micOp);
  }

  Future<void> _setMicEnabledSafe(bool enabled) async {
    final op = _micOp;
    try {
      final channel = _lastRoomId?.trim();
      if (channel == null || channel.isEmpty) return;

      if (enabled) {
        final ds = _remote;
        if (ds != null) {
          await ds.joinVoiceSession(channel);
        }
        // Host token gerekir — tam yeniden bağlan.
        await _agora.joinVoice(channel, publishMic: true);
        _engine = VoiceAudioEngineKind.agora;
        return;
      }

      if (_agora.inChannel) {
        await _agora.setMicEnabled(false);
      }
      final ds = _remote;
      if (ds != null) {
        try {
          await ds.leaveVoiceSession(channel);
        } catch (_) {}
      }
    } catch (e, st) {
      VoiceRoomDebugLog.log('audio.agora.mic_toggle.fail', {
        'enabled': enabled,
        'error': e.toString(),
        'stack': st.toString(),
      });
      rethrow;
    } finally {
      if (identical(_micOp, op)) _micOp = null;
    }
  }

  void setHeadphonesOn(bool on) => _agora.setRemoteAudioMuted(!on);

  Future<void> leave() async {
    await _micOp;
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
    unawaited(leave());
    unawaited(_agora.dispose());
    _engine = null;
  }
}
