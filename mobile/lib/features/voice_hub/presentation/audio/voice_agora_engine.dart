import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/config/env.dart';
import '../../../agora/data/datasources/agora_remote_datasource.dart';
import '../../../agora/domain/agora_channel_names.dart';
import '../../../agora/domain/entities/agora_credentials.dart';
import '../../data/services/voice_room_debug_log.dart';
import 'voice_agora_exception.dart';

/// Sesli sohbet — sunucu token + yedek App ID only.
class VoiceAgoraEngine {
  VoiceAgoraEngine({AgoraRemoteDataSource? tokenSource})
      : _tokenSource = tokenSource;

  final AgoraRemoteDataSource? _tokenSource;

  RtcEngine? _engine;
  RtcEngineEventHandler? _handler;
  var _inChannel = false;
  var _micOn = true;
  var _publishMic = false;
  String _channelId = '';
  AgoraCredentials? _lastCredentials;
  Future<void>? _joinInFlight;

  bool get isSupported => !kIsWeb;
  bool get inChannel => _inChannel;
  bool get micOn => _micOn;
  AgoraCredentials? get lastCredentials => _lastCredentials;

  static Future<bool> requestMicrophonePermission() async {
    if (kIsWeb) return false;
    try {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        if (mic.isPermanentlyDenied) await openAppSettings();
        return false;
      }
      return true;
    } on MissingPluginException {
      return false;
    } catch (e, st) {
      _logFailure('requestMicrophonePermission', e, st);
      return false;
    }
  }

  Future<void> joinVoice(
    String roomId, {
    bool publishMic = true,
  }) async {
    if (!isSupported) {
      throw const VoiceAgoraException(
        'Agora yalnızca Android ve iOS cihazlarda desteklenir.',
        phase: 'platform',
      );
    }

    final rawRoomId = roomId.trim();
    if (rawRoomId.isEmpty) {
      throw const VoiceAgoraException(
        'Oda kimliği boş — ses bağlantısı kurulamadı.',
        phase: 'validate',
      );
    }

    final channel = AgoraChannelNames.forVoiceRoom(rawRoomId);
    VoiceRoomDebugLog.log('audio.agora.prepare', {
      'roomId': rawRoomId,
      'channel': channel,
      'publishMic': publishMic,
    });

    try {
      final micOk = await requestMicrophonePermission();
      if (!micOk) {
        throw const VoiceAgoraException(
          'Mikrofon izni verilmedi. Ayarlardan mikrofonu açıp tekrar deneyin.',
          phase: 'permission',
        );
      }

      if (_inChannel && _channelId == channel) {
        await setMicEnabled(publishMic);
        return;
      }

      if (_inChannel) {
        await leave();
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }

      final role = publishMic ? 'host' : 'audience';
      AgoraCredentials? credentials;
      final tokenSource = _tokenSource;
      if (tokenSource != null) {
        try {
          credentials = await tokenSource.fetchVoiceRoomToken(
            roomId: rawRoomId,
            role: role,
          );
        } catch (e, st) {
          _logFailure('fetchVoiceRoomToken', e, st, extra: {'channel': channel});
          VoiceRoomDebugLog.log('audio.agora.token.fallback', {
            'channel': channel,
            'error': e.toString(),
          });
        }
      }

      final appId = credentials?.appId.trim().isNotEmpty == true
          ? credentials!.appId.trim()
          : Env.agoraVoiceAppId.trim();
      if (appId.isEmpty) {
        throw const VoiceAgoraException(
          'Agora App ID eksik (sunucu yanıtı ve AGORA_VOICE_APP_ID boş).',
          phase: 'app_id',
        );
      }

      final joinToken = credentials?.token.trim() ?? '';
      final joinChannel = credentials?.channelName.trim().isNotEmpty == true
          ? credentials!.channelName.trim()
          : channel;
      final joinUid = credentials?.uid ?? 0;
      final mode = joinToken.isNotEmpty ? 'server_token' : 'app_id_only';

      VoiceRoomDebugLog.log('audio.agora.token', {
        'channel': joinChannel,
        'uid': joinUid,
        'appIdPrefix': appId.length >= 8 ? appId.substring(0, 8) : appId,
        'tokenLength': joinToken.length,
        'mode': mode,
      });

      await _createAndInitializeEngine(appId);

      final clientRole = publishMic
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience;
      try {
        await _engine!.setClientRole(role: clientRole);
        await _engine!.setDefaultAudioRouteToSpeakerphone(true);
      } catch (e, st) {
        _logFailure('engine.configure', e, st);
        throw VoiceAgoraException(
          'Agora ses motoru yapılandırılamadı: ${_friendlyError(e)}',
          cause: e,
          stackTrace: st,
          phase: 'configure',
        );
      }

      final joinCompleter = Completer<void>();
      final prevHandler = _handler;
      _handler = RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          _inChannel = true;
          VoiceRoomDebugLog.log('audio.agora.joined', {
            'channel': connection.channelId ?? channel,
            'elapsedMs': elapsed,
          });
          if (!joinCompleter.isCompleted) joinCompleter.complete();
        },
        onLeaveChannel: (connection, stats) {
          _inChannel = false;
        },
        onError: (err, msg) {
          final text = _formatAgoraError(err, msg);
          VoiceRoomDebugLog.log('audio.agora.error', {
            'code': err.name,
            'message': text,
          });
          if (_shouldIgnoreAgoraError(err)) return;
          if (!joinCompleter.isCompleted) {
            joinCompleter.completeError(
              VoiceAgoraException(
                text,
                phase: 'agora_callback',
              ),
            );
          }
        },
      );
      if (prevHandler != null) {
        try {
          _engine!.unregisterEventHandler(prevHandler);
        } catch (e, st) {
          _logFailure('unregisterEventHandler', e, st);
        }
      }
      _engine!.registerEventHandler(_handler!);

      _channelId = joinChannel;
      _lastCredentials = AgoraCredentials(
        appId: appId,
        token: joinToken,
        channelName: joinChannel,
        uid: joinUid,
      );

      try {
        await _engine!.joinChannel(
          token: joinToken,
          channelId: joinChannel,
          uid: joinUid,
          options: ChannelMediaOptions(
            channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
            clientRoleType: clientRole,
            publishMicrophoneTrack: publishMic,
            autoSubscribeAudio: true,
          ),
        );
      } on AgoraRtcException catch (e, st) {
        if (e.code == -17 || e.code == 17) {
          VoiceRoomDebugLog.log('audio.agora.duplicate_join', {'channel': channel});
          if (!joinCompleter.isCompleted) joinCompleter.complete();
          _inChannel = true;
        } else {
          _logFailure('joinChannel', e, st);
          throw VoiceAgoraException(
            'Agora kanala girilemedi (${e.code}): ${e.message ?? e.toString()}',
            cause: e,
            stackTrace: st,
            phase: 'join_channel',
          );
        }
      } catch (e, st) {
        _logFailure('joinChannel', e, st);
        throw VoiceAgoraException(
          'Agora kanala girilemedi: ${_friendlyError(e)}',
          cause: e,
          stackTrace: st,
          phase: 'join_channel',
        );
      }

      try {
        await joinCompleter.future.timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw VoiceAgoraException(
            'Agora kanala bağlanma zaman aşımı (20 sn). '
            'Kanal: $channel',
            phase: 'join_timeout',
          ),
        );
      } on VoiceAgoraException {
        rethrow;
      } catch (e, st) {
        _logFailure('joinCompleter', e, st);
        throw VoiceAgoraException(
          'Agora bağlantısı tamamlanamadı: ${_friendlyError(e)}',
          cause: e,
          stackTrace: st,
          phase: 'join_wait',
        );
      }

      _inChannel = true;
      _publishMic = publishMic;
      await setMicEnabled(publishMic);
    } on VoiceAgoraException {
      rethrow;
    } catch (e, st) {
      _logFailure('joinVoice', e, st);
      throw VoiceAgoraException(
        'Ses bağlantısı kurulamadı: ${_friendlyError(e)}',
        cause: e,
        stackTrace: st,
        phase: 'joinVoice',
      );
    }
  }

  Future<void> _createAndInitializeEngine(String appId) async {
    try {
      if (_engine != null) {
        await leave();
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );
      await _engine!.enableAudio();
      // GameStreaming senaryosu: RTC sesi arka plan medyasıyla (WebView YouTube
      // müziği) BİRLİKTE çalar; Agora özel ses odağı almaz. Aksi halde
      // Communication profili odaya katıldıktan ~5-6 sn sonra ses odağını alıp
      // müziği durduruyordu ("müzik 5-6 sn çalıp duruyor").
      try {
        await _engine!.setAudioScenario(
          AudioScenarioType.audioScenarioGameStreaming,
        );
      } catch (e, st) {
        _logFailure('setAudioScenario', e, st);
      }
      VoiceRoomDebugLog.log('audio.agora.initialized', {
        'appIdPrefix': appId.length >= 8 ? appId.substring(0, 8) : appId,
      });
    } catch (e, st) {
      _logFailure('initialize', e, st);
      throw VoiceAgoraException(
        'Agora motoru başlatılamadı: ${_friendlyError(e)}',
        cause: e,
        stackTrace: st,
        phase: 'initialize',
      );
    }
  }

  Future<void> setMicEnabled(bool enabled) async {
    final engine = _engine;
    if (engine == null || !_inChannel) return;
    if (enabled == _micOn && enabled == _publishMic) return;
    try {
      if (enabled && !_publishMic) {
        await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
        await engine.updateChannelMediaOptions(
          options: const ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
            publishMicrophoneTrack: true,
          ),
        );
        _publishMic = true;
      } else if (!enabled && _publishMic) {
        await engine.muteLocalAudioStream(true);
        await engine.updateChannelMediaOptions(
          options: const ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleAudience,
            publishMicrophoneTrack: false,
          ),
        );
        await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
        _publishMic = false;
        _micOn = false;
        return;
      }
      await engine.muteLocalAudioStream(!enabled);
      _micOn = enabled;
    } catch (e, st) {
      _logFailure('setMicEnabled', e, st);
      rethrow;
    }
  }

  void setRemoteAudioMuted(bool muted) {
    try {
      _engine?.muteAllRemoteAudioStreams(muted);
    } catch (e, st) {
      _logFailure('setRemoteAudioMuted', e, st);
    }
  }

  Future<void> leave() async {
    final engine = _engine;
    if (engine == null) {
      _inChannel = false;
      _micOn = false;
      _channelId = '';
      _lastCredentials = null;
      return;
    }
    try {
      if (_inChannel) {
        await engine.leaveChannel();
      }
    } catch (e, st) {
      _logFailure('leaveChannel', e, st);
    }
    try {
      if (_handler != null) {
        engine.unregisterEventHandler(_handler!);
        _handler = null;
      }
    } catch (e, st) {
      _logFailure('unregisterOnLeave', e, st);
    }
    try {
      await engine.release();
    } catch (e, st) {
      _logFailure('release', e, st);
    }
    _engine = null;
    _inChannel = false;
    _micOn = false;
    _publishMic = false;
    _channelId = '';
    _lastCredentials = null;
    _joinInFlight = null;
    VoiceRoomDebugLog.log('audio.agora.left', {});
  }

  Future<void> dispose() async {
    try {
      await leave();
    } catch (e, st) {
      _logFailure('dispose', e, st);
    }
  }

  static bool _shouldIgnoreAgoraError(ErrorCodeType err) {
    return err == ErrorCodeType.errJoinChannelRejected;
  }

  static String _formatAgoraError(ErrorCodeType err, String msg) {
    final detail = msg.trim();
    if (detail.isNotEmpty) return 'Agora hatası (${err.name}): $detail';
    return switch (err) {
      ErrorCodeType.errInvalidAppId =>
        'Agora App ID geçersiz. AGORA_VOICE_APP_ID ve sunucu yanıtını kontrol edin.',
      ErrorCodeType.errInvalidToken =>
        'Agora token geçersiz veya süresi dolmuş. Odaya tekrar girin.',
      ErrorCodeType.errTokenExpired =>
        'Agora token süresi doldu. Odaya tekrar girin.',
      ErrorCodeType.errJoinChannelRejected =>
        'Agora kanala katılım reddedildi. Birkaç saniye sonra tekrar deneyin.',
      _ => 'Agora hatası (${err.name}). Bağlantıyı kontrol edip tekrar deneyin.',
    };
  }

  static String _friendlyError(Object e) {
    if (e is VoiceAgoraException) return e.message;
    final raw = e.toString();
    if (raw.startsWith('ApiException')) {
      return raw.replaceFirst(RegExp(r'^ApiException(\(\d+\))?: '), '');
    }
    return raw.replaceFirst('Bad state: ', '');
  }

  static void _logFailure(
    String phase,
    Object e,
    StackTrace st, {
    Map<String, Object?>? extra,
  }) {
    VoiceRoomDebugLog.log('audio.agora.fail', {
      'phase': phase,
      'error': e.toString(),
      'stack': st.toString(),
      ...?extra,
    });
    debugPrint('[VoiceAgora] FAIL phase=$phase error=$e\n$st');
  }
}
