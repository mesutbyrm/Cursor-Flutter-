import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/config/env.dart';

/// Sesli sohbet — Agora App ID Only (token boş), kanal = oda `roomId`.
class VoiceAgoraEngine {
  RtcEngine? _engine;
  RtcEngineEventHandler? _handler;
  var _inChannel = false;
  var _micOn = true;
  String _channelId = '';

  bool get isSupported => !kIsWeb;
  bool get inChannel => _inChannel;
  bool get micOn => _micOn;

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
    } catch (_) {
      return false;
    }
  }

  Future<void> joinVoice(String roomId, {bool publishMic = true}) async {
    if (!isSupported) {
      throw StateError('Agora yalnızca Android/iOS üzerinde desteklenir');
    }
    final channel = roomId.trim();
    if (channel.isEmpty) {
      throw StateError('Agora kanal adı boş');
    }
    final ok = await requestMicrophonePermission();
    if (!ok) throw StateError('Mikrofon izni verilmedi');

    if (_inChannel && _channelId == channel) {
      setMicEnabled(publishMic);
      return;
    }
    if (_inChannel) {
      await leave();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    final appId = Env.agoraVoiceAppId.trim();
    if (appId.isEmpty) {
      throw StateError('Agora App ID eksik');
    }

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(appId: appId));
    await _engine!.enableAudio();
    await _engine!.setDefaultAudioRouteToSpeakerphone(true);
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    final joinCompleter = Completer<void>();
    final prevHandler = _handler;
    _handler = RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        _inChannel = true;
        if (!joinCompleter.isCompleted) joinCompleter.complete();
      },
      onLeaveChannel: (connection, stats) => _inChannel = false,
      onError: (err, msg) {
        if (!joinCompleter.isCompleted) {
          joinCompleter.completeError(StateError('Agora: $msg'));
        }
      },
    );
    if (prevHandler != null) _engine!.unregisterEventHandler(prevHandler);
    _engine!.registerEventHandler(_handler!);

    _channelId = channel;
    await _engine!.joinChannel(
      token: '',
      channelId: channel,
      uid: 0,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
      ),
    );

    await joinCompleter.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw StateError('Agora kanala bağlanılamadı'),
    );
    _inChannel = true;
    setMicEnabled(publishMic);
  }

  void setMicEnabled(bool enabled) {
    final engine = _engine;
    if (engine == null || !_inChannel) return;
    engine.muteLocalAudioStream(!enabled);
    _micOn = enabled;
  }

  void setRemoteAudioMuted(bool muted) {
    _engine?.muteAllRemoteAudioStreams(muted);
  }

  Future<void> leave() async {
    if (_engine != null) {
      if (_inChannel) {
        await _engine!.leaveChannel();
      }
      if (_handler != null) {
        _engine!.unregisterEventHandler(_handler!);
        _handler = null;
      }
      await _engine!.release();
      _engine = null;
    }
    _inChannel = false;
    _micOn = false;
    _channelId = '';
  }

  Future<void> dispose() async => leave();
}
