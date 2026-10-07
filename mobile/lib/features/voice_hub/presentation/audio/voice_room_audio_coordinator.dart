import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/performance/voice_room_entry_perf.dart';
import '../../../trtc/domain/entities/trtc_credentials.dart';
import '../../../trtc/presentation/trtc_room_manager.dart';
import '../../data/datasources/chat_room_remote_datasource.dart';
import '../../data/services/voice_room_debug_log.dart';
import '../../domain/entities/voice_audio_engine.dart';
import 'voice_room_music_audio_session.dart';
import 'voice_trtc_engine.dart';

/// canlifal.com sesli oda — Tencent TRTC token + `POST /voice` `{type: join}`.
class VoiceRoomAudioCoordinator {
  VoiceRoomAudioCoordinator({
    VoiceTrtcEngine? trtc,
    ChatRoomRemoteDataSource? remote,
  })  : _trtc = trtc ?? VoiceTrtcEngine(),
        _remote = remote;

  final VoiceTrtcEngine _trtc;
  final ChatRoomRemoteDataSource? _remote;

  VoiceAudioEngineKind? _engine;
  VoiceAudioEngineKind? get engine => _engine;

  bool get micOn => _trtc.micOn;
  bool get isSupported => _trtc.isSupported;
  bool get isReconnecting => _reconnecting;
  TrtcRoomManager get trtcManager => _trtc.manager;

  Future<void>? _micOp;

  var _reconnecting = false;
  var _reconnectSuspended = false;
  var _leaveEpoch = 0;
  var _desiredMicOn = false;

  VoidCallback? onReconnecting;
  VoidCallback? onReconnected;

  void setReconnectSuspended(bool suspended) {
    _reconnectSuspended = suspended;
  }

  void _bindConnectionLostHandler() {
    _trtc.manager.onConnectionLost = () {
      if (_reconnectSuspended || _reconnecting) return;
      final channel = _lastRoomId?.trim();
      if (channel == null || channel.isEmpty) return;
      unawaited(_reconnectVoice());
    };
  }

  /// Ağ geri geldiğinde (WiFi↔mobil data) çağrılır. TRTC `onConnectionLost`
  /// her zaman tetiklenmediği için sessiz kopmaya karşı yedek: yalnızca odada
  /// olmamız beklenirken kanal düşmüşse tek uçuşlu yeniden bağlanır.
  Future<void> ensureConnected() async {
    if (_reconnectSuspended || _reconnecting) return;
    final channel = _lastRoomId?.trim();
    if (channel == null || channel.isEmpty) return;
    if (_trtc.inChannel) return;
    await _reconnectVoice();
  }

  Future<void> _reconnectVoice() async {
    if (_reconnectSuspended || _reconnecting) return;
    final channel = _lastRoomId?.trim();
    final userId = _lastUserId;
    if (channel == null || channel.isEmpty) return;

    _reconnecting = true;
    // `_desiredMicOn` kullanıcı niyetini taşır (koltuktan inme / leave); TRTC
    // `micOn` geçici olarak true kalabildiği için yeniden bağlanmada mic açılmamalı.
    final publishMic = _desiredMicOn;
    onReconnecting?.call();
    VoiceRoomDebugLog.log('audio.trtc.reconnect.start', {
      'roomId': channel,
      'mic': _desiredMicOn,
    });

    try {
      await _trtc.leave();
      // Yeniden bağlanma sürerken kullanıcı odadan çıktıysa ODAYA GERİ GİRME
      // (çıktıktan sonra ses gidip gelmesinin kaynağı).
      if (_reconnectSuspended) return;
      await _trtc.joinVoice(
        channel,
        publishMic: publishMic,
        userId: userId,
        role: publishMic ? 'host' : 'audience',
      );
      if (_reconnectSuspended) {
        await _trtc.leave();
        return;
      }
      if (!publishMic) {
        await _trtc.setMicEnabled(false);
      }
      VoiceRoomDebugLog.log('audio.trtc.reconnect.ok', {'roomId': channel});
      onReconnected?.call();
    } catch (e, st) {
      VoiceRoomDebugLog.log('audio.trtc.reconnect.fail', {
        'roomId': channel,
        'error': e.toString(),
        'stack': st.toString(),
      });
    } finally {
      _reconnecting = false;
    }
  }

  /// [roomId] = Prisma oda kimliği; TRTC kanalı `voice_room_{id}`.
  Future<VoiceAudioEngineKind> join({
    required String roomId,
    ChatRoomRemoteDataSource? remote,
    bool enableMic = false,
    bool staffBypassVoiceApi = false,
    String? userId,
    TrtcCredentials? backendTrtc,
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

    VoiceRoomDebugLog.log('audio.trtc.prepare', {
      'roomId': channel,
      'trtcRoom': backendTrtc?.effectiveStrRoomId,
      'enableMic': enableMic,
      'fromBackend': backendTrtc != null,
    });
    _lastRoomId = channel;
    _lastUserId = userId;
    _desiredMicOn = enableMic;
    _reconnectSuspended = false;
    final epoch = _leaveEpoch;

    final role = enableMic ? 'host' : 'audience';
    final prefetched = backendTrtc ??
        (userId != null && userId.isNotEmpty
            ? VoiceRoomEntryPerf.takeTrtc(
                userId: userId,
                roomId: backendTrtc?.effectiveStrRoomId ??
                    VoiceTrtcEngine.trtcRoomIdFor(channel),
              )
            : null);

    try {
      await Future.wait<void>([
        if (enableMic)
          () async {
            try {
              await ds.joinVoiceSession(channel);
            } on Object catch (e) {
              VoiceRoomDebugLog.log('audio.voice_api.join.warn', {
                'error': e.toString(),
                'staffBypass': staffBypassVoiceApi,
              });
              if (!staffBypassVoiceApi) rethrow;
            }
          }()
        else
          Future<void>.value(),
        _trtc.joinVoice(
          channel,
          publishMic: enableMic,
          prefetchedCredentials: prefetched,
          role: role,
          userId: userId,
        ),
      ]);
    } on Object catch (e) {
      if (!staffBypassVoiceApi) rethrow;
      VoiceRoomDebugLog.log('audio.join.partial', {'error': e.toString()});
      await _trtc.joinVoice(
        channel,
        publishMic: enableMic,
        prefetchedCredentials: prefetched,
        role: role,
        userId: userId,
      );
    }
    // Katılma sürerken kullanıcı odadan çıktıysa bağlantıyı hemen kapat.
    if (epoch != _leaveEpoch) {
      await _trtc.leave();
      return VoiceAudioEngineKind.trtc;
    }
    _engine = VoiceAudioEngineKind.trtc;
    _desiredMicOn = enableMic;
    if (!enableMic) {
      await _trtc.setMicEnabled(false);
    }
    _bindConnectionLostHandler();
    VoiceRoomDebugLog.log('audio.trtc.joined', {
      'roomId': channel,
      'mic': enableMic,
    });
    return _engine!;
  }

  Future<void> setMicEnabled(bool enabled) async {
    _desiredMicOn = enabled;
    _micOp = _setMicEnabledSafe(enabled);
    await _micOp;
  }

  var _staffBypassVoiceApi = false;

  void setStaffBypassVoiceApi(bool value) => _staffBypassVoiceApi = value;

  Future<void> _setMicEnabledSafe(bool enabled) async {
    final op = _micOp;
    try {
      final channel = _lastRoomId?.trim();
      if (channel == null || channel.isEmpty) return;

      if (enabled) {
        final ds = _remote;
        if (ds != null && !_trtc.inChannel) {
          try {
            await ds.joinVoiceSession(channel);
          } on Object catch (e) {
            VoiceRoomDebugLog.log('audio.voice_api.mic.warn', {
              'error': e.toString(),
              'staffBypass': _staffBypassVoiceApi,
            });
            if (!_staffBypassVoiceApi) rethrow;
          }
        }
        if (!_trtc.inChannel) {
          await _trtc.joinVoice(
            channel,
            publishMic: true,
            userId: _lastUserId,
          );
          _engine = VoiceAudioEngineKind.trtc;
          _bindConnectionLostHandler();
        } else {
          await _trtc.setMicEnabled(true);
        }
        _desiredMicOn = true;
        return;
      }

      if (_trtc.inChannel) {
        await _trtc.setMicEnabled(false);
      }
      final ds = _remote;
      if (ds != null) {
        try {
          await ds.leaveVoiceSession(channel);
        } catch (_) {}
      }
      _desiredMicOn = false;
      return;
    } catch (e, st) {
      VoiceRoomDebugLog.log('audio.trtc.mic_toggle.fail', {
        'enabled': enabled,
        'error': e.toString(),
        'stack': st.toString(),
      });
      rethrow;
    } finally {
      if (identical(_micOp, op)) _micOp = null;
    }
  }

  void setHeadphonesOn(bool on) => _trtc.setRemoteAudioMuted(!on);

  /// Koltuktan inme — odada kalırken TRTC ve `/voice` oturumunu kapat.
  Future<void> releaseSeatVoice() async {
    _desiredMicOn = false;
    _reconnectSuspended = true;
    final ds = _remote;
    final channel = _lastRoomId?.trim();
    try {
      _trtc.setRemoteAudioMuted(true);
    } catch (_) {}
    try {
      await _trtc.setMicEnabled(false);
    } catch (_) {}
    if (ds != null && channel != null && channel.isNotEmpty) {
      try {
        await ds
            .leaveVoiceSession(channel)
            .timeout(const Duration(seconds: 4));
      } catch (_) {}
    }
    try {
      await _trtc.leave().timeout(const Duration(seconds: 3));
    } catch (_) {}
    _engine = null;
    // Yeniden bağlanmayı çağıran (audience join / leave) açana kadar kapalı tut.
  }

  Future<void> leave() async {
    _leaveEpoch++;
    _reconnectSuspended = true;
    _trtc.manager.onConnectionLost = null;
    final ds = _remote;
    final channel = _trtc.inChannel ? _lastRoomId : null;
    // Ses önce kesilir: REST `voice leave` yavaş/asılı kalırsa (zaman aşımı
    // çağıranı bekletmeden bırakır) TRTC odada kalıyor, kullanıcı çıktıktan
    // sonra da duyuyor ve duyuluyordu.
    try {
      _trtc.setRemoteAudioMuted(true);
    } catch (_) {}
    try {
      await _trtc.leave().timeout(const Duration(seconds: 3));
    } catch (_) {}
    if (ds != null && channel != null && channel.isNotEmpty) {
      unawaited(
        ds
            .leaveVoiceSession(channel)
            .timeout(const Duration(seconds: 6))
            .catchError((_) {}),
      );
    }
    try {
      await _micOp;
    } catch (_) {}
    _engine = null;
    _lastRoomId = null;
    _lastUserId = null;
    _desiredMicOn = false;
  }

  String? _lastRoomId;
  String? _lastUserId;

  Future<void> leaveRoom(String roomId) async {
    _lastRoomId = roomId.trim();
    await leave();
  }

  void dispose() {
    unawaited(leave());
    unawaited(_trtc.dispose());
    _engine = null;
  }
}
