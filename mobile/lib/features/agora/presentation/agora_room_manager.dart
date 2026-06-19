import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

import '../domain/entities/agora_credentials.dart';

/// Agora RTC — canlı video yayını (üretim: `POST /api/agora/token`).
class AgoraRoomManager {
  RtcEngine? _engine;
  RtcEngineEventHandler? _handler;

  var _inChannel = false;
  var _micOn = true;
  var _cameraOn = true;
  var _isHost = false;
  var _previewOnly = false;
  String _channelName = '';

  int? remoteUid;
  final ValueNotifier<int?> remoteUidNotifier = ValueNotifier<int?>(null);
  final ValueNotifier<bool> remoteVideoAvailable = ValueNotifier(false);

  final Set<int> _remoteUids = {};

  bool get isSupported => !kIsWeb;
  bool get inChannel => _inChannel;
  bool get micOn => _micOn;
  bool get cameraOn => _cameraOn;
  bool get isHost => _isHost;

  static Future<bool> requestPermissions({required bool video}) async {
    if (kIsWeb) return false;
    try {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        if (mic.isPermanentlyDenied) await openAppSettings();
        return false;
      }
      if (video) {
        final cam = await Permission.camera.request();
        if (!cam.isGranted) {
          if (cam.isPermanentlyDenied) await openAppSettings();
          return false;
        }
      }
      return true;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensureEngine(String appId) async {
    if (_engine != null) return;
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );
    await _engine!.enableVideo();
    await _engine!.setDefaultAudioRouteToSpeakerphone(true);
  }

  /// Önizleme — kanala girmeden kamera.
  Future<void> startPreviewOnly({required String appId}) async {
    if (!isSupported) return;
    final ok = await requestPermissions(video: true);
    if (!ok) throw StateError('Kamera izni gerekli');

    await _ensureEngine(appId);
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.startPreview();
    _previewOnly = true;
    _cameraOn = true;
    _isHost = true;
  }

  Future<void> join({
    required AgoraCredentials credentials,
    required bool isHost,
  }) async {
    if (!isSupported) {
      throw StateError('Agora yalnızca Android/iOS üzerinde desteklenir');
    }

    final channel = credentials.channelName.trim();
    if (channel.isEmpty) {
      throw StateError('Agora kanal adı boş');
    }

    final ok = await requestPermissions(video: isHost);
    if (!ok) throw StateError('Mikrofon veya kamera izni verilmedi');

    if (_inChannel || _previewOnly) {
      await leave();
    }

    final appId = credentials.appId.trim();
    if (appId.isEmpty) {
      throw StateError('Agora App ID eksik');
    }

    await _ensureEngine(appId);
    _isHost = isHost;
    _previewOnly = false;
    _channelName = channel;

    final role = isHost
        ? ClientRoleType.clientRoleBroadcaster
        : ClientRoleType.clientRoleAudience;

    await _engine!.setClientRole(role: role);

    if (isHost) {
      await _engine!.enableLocalAudio(true);
      await _engine!.muteLocalAudioStream(false);
      await _engine!.muteLocalVideoStream(false);
      _micOn = true;
      _cameraOn = true;
    }

    final joinCompleter = Completer<void>();
    void onJoin(RtcConnection connection, int elapsed) {
      if (!joinCompleter.isCompleted) joinCompleter.complete();
    }

    final prevHandler = _handler;
    _handler = RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        _inChannel = true;
        onJoin(connection, elapsed);
        debugPrint('Agora join ok channel=${connection.channelId}');
      },
      onLeaveChannel: (connection, stats) => _inChannel = false,
      onUserJoined: (connection, uid, elapsed) {
        debugPrint('Agora remote joined uid=$uid');
        _remoteUids.add(uid);
        if (!_isHost || remoteUid == null) {
          remoteUid = uid;
          remoteUidNotifier.value = uid;
          remoteVideoAvailable.value = true;
        }
      },
      onUserOffline: (connection, uid, reason) {
        _remoteUids.remove(uid);
        if (remoteUid == uid) {
          remoteUid = _remoteUids.isEmpty ? null : _remoteUids.first;
          remoteUidNotifier.value = remoteUid;
          remoteVideoAvailable.value = remoteUid != null;
        }
      },
      onError: (err, msg) {
        debugPrint('Agora error $err: $msg');
        if (!joinCompleter.isCompleted) {
          joinCompleter.completeError(StateError('Agora bağlantı hatası: $msg'));
        }
      },
    );
    if (prevHandler != null) _engine!.unregisterEventHandler(prevHandler);
    _engine!.registerEventHandler(_handler!);

    await _engine!.joinChannel(
      token: credentials.token,
      channelId: channel,
      uid: credentials.uid,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: role,
        publishMicrophoneTrack: isHost,
        publishCameraTrack: isHost,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );

    await joinCompleter.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw StateError('Agora kanala bağlanılamadı'),
    );
    _inChannel = true;

    if (isHost) {
      await _engine!.enableLocalVideo(true);
      await _engine!.enableLocalAudio(true);
    }
  }

  String get channelName => _channelName;

  /// Co-broadcast: izleyiciden yayıncıya geçiş — yeni token ile yeniden bağlan.
  Future<void> rejoinAsHost(AgoraCredentials credentials) async {
    await leave();
    await join(credentials: credentials, isHost: true);
  }

  void setMicEnabled(bool enabled) {
    if (_engine == null || !_isHost) return;
    _engine!.muteLocalAudioStream(!enabled);
    _micOn = enabled;
  }

  Future<void> setCameraEnabled(bool enabled) async {
    if (_engine == null || !_isHost) return;
    if (_previewOnly && !_inChannel) {
      if (enabled) {
        await _engine!.startPreview();
      } else {
        await _engine!.stopPreview();
      }
    } else {
      await _engine!.muteLocalVideoStream(!enabled);
    }
    _cameraOn = enabled;
  }

  void switchCamera() {
    _engine?.switchCamera();
  }

  Future<void> leave() async {
    remoteVideoAvailable.value = false;
    remoteUid = null;
    remoteUidNotifier.value = null;
    _remoteUids.clear();

    if (_engine != null) {
      if (_previewOnly) {
        await _engine!.stopPreview();
      }
      if (_inChannel) {
        await _engine!.leaveChannel();
      }
      if (_handler != null) {
        _engine!.unregisterEventHandler(_handler!);
        _handler = null;
      }
    }

    _inChannel = false;
    _previewOnly = false;
    _isHost = false;
    _micOn = false;
    _cameraOn = false;
  }

  /// Önizlemeden yayın odasına geçerken motoru tamamen bırak (kamera kilidi).
  Future<void> shutdownForHandoff() async {
    await leave();
    if (_engine != null) {
      await _engine!.release();
      _engine = null;
    }
    _channelName = '';
  }

  Future<void> dispose() async {
    await shutdownForHandoff();
  }

  RtcEngine? get engine => _engine;
}

/// Yerel kamera — önizleme veya yayın.
class AgoraLocalVideoView extends StatelessWidget {
  const AgoraLocalVideoView({super.key, required this.manager});

  final AgoraRoomManager manager;

  @override
  Widget build(BuildContext context) {
    final engine = manager.engine;
    if (engine == null) return const SizedBox.shrink();
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: engine,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }
}

/// Uzak yayıncı videosu.
class AgoraRemoteVideoView extends StatelessWidget {
  const AgoraRemoteVideoView({
    super.key,
    required this.manager,
    required this.uid,
  });

  final AgoraRoomManager manager;
  final int uid;

  @override
  Widget build(BuildContext context) {
    final engine = manager.engine;
    if (engine == null || uid <= 0) return const SizedBox.shrink();
    return AgoraVideoView(
      key: ValueKey('agora-remote-$uid'),
      controller: VideoViewController.remote(
        rtcEngine: engine,
        canvas: VideoCanvas(uid: uid),
        connection: RtcConnection(channelId: manager.channelName),
      ),
    );
  }
}
