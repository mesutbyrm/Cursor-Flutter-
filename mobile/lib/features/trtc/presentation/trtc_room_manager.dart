import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tencent_rtc_sdk/trtc_cloud.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_def.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_listener.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_video_view.dart';
import 'package:tencent_rtc_sdk/tx_audio_effect_manager.dart';
import 'package:tencent_rtc_sdk/tx_device_manager.dart';

import '../../voice_hub/data/services/voice_room_debug_log.dart';
import '../domain/entities/trtc_credentials.dart';

/// Tencent TRTC oda oturumu — canlı yayın ve sesli sohbet.
class TrtcRoomManager {
  /// Tek `TRTCCloud.sharedInstance()` — eşzamanlı çoklu manager oturumu engelle.
  static TrtcRoomManager? _activeSession;

  TRTCCloud? _cloud;
  TXDeviceManager? _device;
  TRTCCloudListener? _listener;
  Completer<int>? _enterRoomCompleter;
  Completer<void>? _exitRoomCompleter;

  bool _inRoom = false;
  bool _previewOnly = false;
  bool _micOn = true;
  bool _cameraOn = true;
  bool _isHost = false;
  bool _twoWayVideo = false;
  bool _audioOnly = false;
  String? _localUserId;

  String? remoteAnchorUserId;
  final ValueNotifier<String?> remoteAnchorUserIdNotifier =
      ValueNotifier<String?>(null);
  final ValueNotifier<bool> remoteVideoAvailable = ValueNotifier(false);
  /// Katılımcı bazlı uzak video durumu — yerel kamera ile karıştırılmaz.
  final ValueNotifier<Map<String, bool>> remoteVideoByUser =
      ValueNotifier<Map<String, bool>>({});
  /// Katılımcı bazlı uzak ses durumu — yerel mikrofon ile karıştırılmaz.
  final ValueNotifier<Map<String, bool>> remoteAudioByUser =
      ValueNotifier<Map<String, bool>>({});

  int? _boundRemoteViewId;
  String? _boundRemoteUserId;
  String? _expectedAnchorUserId;

  /// Bağlantı koptuğunda çağrılır (yeniden bağlanma koordinatörde).
  VoidCallback? onConnectionLost;

  final ValueNotifier<int?> networkQuality = ValueNotifier<int?>(null);

  bool get isSupported => !kIsWeb;
  bool get inRoom => _inRoom;
  /// Agora uyumluluk — `inChannel` yerine.
  bool get inChannel => _inRoom;

  final ValueNotifier<List<String>> remoteUserIdsNotifier =
      ValueNotifier<List<String>>([]);
  final Set<String> _remoteUserIds = {};
  bool get micOn => _micOn;
  bool get cameraOn => _cameraOn;

  void _trtcLog(String event, [Map<String, Object?> fields = const {}]) {
    _logTrtc(event, fields);
  }

  static void _logTrtc(String event, [Map<String, Object?> fields = const {}]) {
    if (!kDebugMode) return;
    final safe = Map<String, Object?>.from(fields)
      ..remove('userSig')
      ..remove('token')
      ..remove('accessToken');
    debugPrint('[TRTC] $event $safe');
  }

  static Future<bool> requestPermissions({required bool video}) async {
    if (kIsWeb) return false;
    try {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        if (mic.isPermanentlyDenied) {
          await openAppSettings();
        }
        return false;
      }
      if (video) {
        final cam = await Permission.camera.request();
        if (!cam.isGranted) {
          if (cam.isPermanentlyDenied) {
            await openAppSettings();
          }
          return false;
        }
      }
      return true;
    } on MissingPluginException {
      _logTrtc('permission_plugin_missing');
      return false;
    } catch (e) {
      _logTrtc('permission_error', {'error': e.runtimeType.toString()});
      return false;
    }
  }

  /// Önizleme — kanala girmeden kamera (yayın hazırlığı).
  Future<void> startPreviewOnly() async {
    if (!isSupported) return;
    final ok = await requestPermissions(video: true);
    if (!ok) throw StateError('Kamera izni gerekli');

    _cloud ??= await TRTCCloud.sharedInstance();
    _device ??= _cloud!.getDeviceManager();
    _previewOnly = true;
    _isHost = true;
    _cameraOn = true;
    _configureAudioProcessing();
  }

  /// Önizlemeden yayın odasına geçerken motoru bırak.
  Future<void> shutdownForHandoff() async {
    if (_previewOnly) {
      _cloud?.stopLocalPreview();
      _previewOnly = false;
    }
    await leave();
  }

  void muteAllRemoteAudioStreams(bool mute) => setAllRemoteAudioMuted(mute);

  Future<void> join({
    required TrtcCredentials credentials,
    required bool isHost,
    bool audioOnly = false,
    String? expectedAnchorUserId,
    bool twoWayVideo = false,
  }) async {
    if (!isSupported) {
      throw StateError('TRTC yalnızca Android/iOS üzerinde desteklenir');
    }

    final roomId = credentials.effectiveStrRoomId;
    if (roomId.isEmpty) {
      throw StateError('TRTC oda kimliği boş — yayına bağlanılamadı');
    }

    try {
      _trtcLog('initialize', {'roomId': roomId});
      await TRTCCloud.sharedInstance();
    } catch (e) {
      throw StateError(
        'Tencent RTC bu cihazda başlatılamadı. Lütfen uygulamayı yeniden başlatın.',
      );
    }

    final ok = await requestPermissions(video: !audioOnly);
    if (!ok) {
      throw StateError('Mikrofon veya kamera izni verilmedi');
    }

    if (_inRoom) {
      await leave();
    }

    final other = _activeSession;
    if (other != null && other != this && other._inRoom) {
      await other.leave();
    }

    _previewOnly = false;
    _audioOnly = audioOnly;

    _cloud ??= await TRTCCloud.sharedInstance();
    _device ??= _cloud!.getDeviceManager();
    _isHost = isHost;
    _twoWayVideo = twoWayVideo;
    _localUserId = credentials.userId.trim();
    _expectedAnchorUserId =
        expectedAnchorUserId?.trim().isNotEmpty == true
            ? expectedAnchorUserId!.trim()
            : null;

    _enterRoomCompleter = Completer<int>();
    if (_cloud != null && _listener != null) {
      _cloud!.unRegisterListener(_listener!);
    }
    _listener = TRTCCloudListener(
      onError: (code, msg) =>
          _trtcLog('error', {'code': code, 'message': msg}),
      onWarning: (code, msg) =>
          _trtcLog('warning', {'code': code, 'message': msg}),
      onEnterRoom: (result) {
        _inRoom = result > 0;
        VoiceRoomDebugLog.log('audio.trtc.enter_room', {
          'result': result,
          'room': roomId,
          'host': _isHost,
          'audioOnly': audioOnly,
        });
        _trtcLog('enter_room', {
          'result': result,
          'roomId': roomId,
          'host': _isHost,
        });
        if (result > 0) {
          _trtcLog('join_success', {'roomId': roomId, 'result': result});
        }
        final c = _enterRoomCompleter;
        if (c != null && !c.isCompleted) c.complete(result);
      },
      onRemoteUserEnterRoom: (userId) {
        _trtcLog('remote_enter', {'userId': userId});
        if (userId == _localUserId) return;
        _trtcLog('remote_user_joined', {'userId': userId});
        _trackRemoteUser(userId, joined: true);
        if (_twoWayVideo) {
          _setRemoteAnchor(userId);
          _cloud?.muteRemoteAudio(userId, false);
        }
      },
      onRemoteUserLeaveRoom: (userId, _) {
        _trtcLog('remote_leave', {'userId': userId});
        _trackRemoteUser(userId, joined: false);
        if (remoteAnchorUserId == userId) {
          _clearRemoteAnchor();
        }
      },
      onExitRoom: (reason) {
        _trtcLog('exit_room', {'reason': reason});
        _inRoom = false;
        final c = _exitRoomCompleter;
        if (c != null && !c.isCompleted) c.complete();
      },
      onConnectionLost: () {
        _trtcLog('connection_lost');
        onConnectionLost?.call();
      },
      onNetworkQuality: (local, remote) {
        networkQuality.value = local.quality.index;
      },
      onUserVideoAvailable: (userId, available) {
        if (_audioOnly) {
          if (available && userId != _localUserId) {
            _cloud?.stopRemoteView(userId, TRTCVideoStreamType.big);
          }
          return;
        }
        _trtcLog('user_video', {'userId': userId, 'available': available});
        if (userId == _localUserId) return;
        _trtcLog('remote_video', {'userId': userId, 'available': available});
        _setRemoteVideoState(userId, available);
        if (!_twoWayVideo && _isHost) return;
        if (available) {
          _setRemoteAnchor(userId);
          _tryBindPendingRemoteView(userId);
        } else if (remoteAnchorUserId == userId) {
          remoteVideoAvailable.value = false;
          stopRemoteView(userId);
          _clearRemoteAnchor();
        }
      },
      onUserAudioAvailable: (userId, available) {
        _trtcLog('user_audio', {'userId': userId, 'available': available});
        if (userId == _localUserId) return;
        _trtcLog('remote_audio', {'userId': userId, 'available': available});
        _setRemoteAudioState(userId, available);
        if (!_twoWayVideo && _isHost) return;
        if (available) {
          _cloud?.muteRemoteAudio(userId, false);
        } else {
          _cloud?.muteRemoteAudio(userId, true);
        }
      },
    );
    _cloud!.registerListener(_listener!);
    _configureAudioProcessing();

    // Canlı yayın izleyicisi: otomatik ses/video alımı (enterRoom öncesi).
    if (audioOnly) {
      _cloud!.setDefaultStreamRecvMode(true, false);
    } else {
      _cloud!.setDefaultStreamRecvMode(true, true);
    }

    final publishAsAnchor = isHost || twoWayVideo;
    final params = TRTCParams(
      sdkAppId: credentials.sdkAppId,
      userId: credentials.userId,
      userSig: credentials.userSig,
      roomId: 0,
      strRoomId: roomId,
      role: publishAsAnchor ? TRTCRoleType.anchor : TRTCRoleType.audience,
    );

    // İki yönlü görüşme: videoCall; tek yönlü yayın: live.
    final scene = audioOnly
        ? TRTCAppScene.voiceChatRoom
        : (twoWayVideo ? TRTCAppScene.videoCall : TRTCAppScene.live);
    _trtcLog('join_start', {
      'roomId': roomId,
      'userId': credentials.userId,
      'sdkAppId': credentials.sdkAppId,
      'audioOnly': audioOnly,
      'role': publishAsAnchor ? 'anchor' : 'audience',
    });
    _cloud!.enterRoom(params, scene);

    final enterResult = await _enterRoomCompleter!.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () => -1,
    );
    _enterRoomCompleter = null;
    if (enterResult <= 0) {
      throw StateError(
        'Canlı odaya bağlanılamadı (kod: $enterResult). İnterneti kontrol edin.',
      );
    }

    _activeSession = this;

    if (audioOnly) {
      _cloud!.startLocalAudio(TRTCAudioQuality.speech);
      _device?.setAudioRoute(TXAudioRoute.speakerPhone);
      _micOn = true;
      _trtcLog('local_audio', {'roomId': roomId, 'enabled': true});
    } else if (publishAsAnchor) {
      _cloud!.startLocalAudio(TRTCAudioQuality.speech);
      _cloud!.muteLocalVideo(TRTCVideoStreamType.big, false);
      // Yerel önizleme yalnızca TrtcLocalVideoView.onViewCreated ile bağlanır.
      // viewId=0 kullanımı uzak tam ekran yüzeyini ele geçirip kamera flip-flop yapar.
      _micOn = true;
      _cameraOn = true;
      _device?.setAudioRoute(TXAudioRoute.speakerPhone);
      _trtcLog('local_audio', {'roomId': roomId, 'enabled': true});
      _trtcLog('local_video', {'roomId': roomId, 'enabled': true});
    } else {
      _device?.setAudioRoute(TXAudioRoute.speakerPhone);
    }
  }

  void _setRemoteVideoState(String userId, bool available) {
    if (userId.isEmpty || userId == _localUserId) return;
    final next = Map<String, bool>.from(remoteVideoByUser.value);
    if (available) {
      next[userId] = true;
    } else {
      next.remove(userId);
    }
    remoteVideoByUser.value = next;
  }

  void _setRemoteAudioState(String userId, bool available) {
    if (userId.isEmpty || userId == _localUserId) return;
    final next = Map<String, bool>.from(remoteAudioByUser.value);
    if (available) {
      next[userId] = true;
    } else {
      next.remove(userId);
    }
    remoteAudioByUser.value = next;
  }

  void _trackRemoteUser(String userId, {required bool joined}) {
    if (userId.isEmpty || userId == _localUserId) return;
    if (joined) {
      _remoteUserIds.add(userId);
    } else {
      _remoteUserIds.remove(userId);
    }
    remoteUserIdsNotifier.value = _remoteUserIds.toList(growable: false);
  }

  /// Yayın kalitesi — TRTC varsayılan encoder (no-op).
  Future<void> setStreamQuality(dynamic preset) async {}

  void muteRemoteAudio(String userId, bool mute) {
    _cloud?.muteRemoteAudio(userId, mute);
  }

  void _configureAudioProcessing() {
    if (_cloud == null) return;
    // TRTC videoCall/live/voiceChatRoom sahnelerinde AEC/ANS/AGC varsayılan açık.
    _cloud!.enableAudioVolumeEvaluation(
      true,
      TRTCAudioVolumeEvaluateParams(interval: 300),
    );
    _device?.setAudioRoute(TXAudioRoute.speakerPhone);
  }

  void _setRemoteAnchor(String userId) {
    if (userId.isEmpty || userId == _localUserId) return;
    if (_expectedAnchorUserId != null && userId != _expectedAnchorUserId) {
      return;
    }
    remoteAnchorUserId = userId;
    remoteAnchorUserIdNotifier.value = userId;
    remoteVideoAvailable.value = true;
  }

  void _clearRemoteAnchor() {
    remoteAnchorUserId = null;
    remoteAnchorUserIdNotifier.value = null;
    remoteVideoAvailable.value = false;
    _boundRemoteViewId = null;
    _boundRemoteUserId = null;
  }

  void _tryBindPendingRemoteView(String userId) {
    final viewId = _boundRemoteViewId;
    if (viewId != null && _boundRemoteUserId == userId && _cloud != null) {
      _cloud!.startRemoteView(userId, TRTCVideoStreamType.big, viewId);
    }
  }

  void startLocalPreview(int viewId) {
    if (_audioOnly) return;
    if (_cloud == null) return;
    if (!_inRoom && !_previewOnly) return;
    _cloud!.muteLocalVideo(TRTCVideoStreamType.big, false);
    _cloud!.startLocalPreview(true, viewId);
    _cameraOn = true;
    _trtcLog('local_video', {'viewId': viewId, 'enabled': true});
  }

  void stopLocalPreview() {
    _cloud?.stopLocalPreview();
    _cloud?.muteLocalVideo(TRTCVideoStreamType.big, true);
    _cameraOn = false;
    _trtcLog('local_video', {'enabled': false});
  }

  void startRemoteView(String userId, int viewId) {
    if (_audioOnly) return;
    if (_cloud == null || !_inRoom) return;
    _boundRemoteUserId = userId;
    _boundRemoteViewId = viewId;
    _cloud!.startRemoteView(userId, TRTCVideoStreamType.big, viewId);
    _cloud!.muteRemoteAudio(userId, false);
    _trtcLog('remote_video', {'userId': userId, 'viewId': viewId, 'enabled': true});
    _trtcLog('remote_audio', {'userId': userId, 'muted': false});
  }

  void stopRemoteView(String userId) {
    _cloud?.stopRemoteView(userId, TRTCVideoStreamType.big);
    _trtcLog('remote_video', {'userId': userId, 'enabled': false});
    if (_boundRemoteUserId == userId) {
      _boundRemoteViewId = null;
      _boundRemoteUserId = null;
    }
  }

  void setMicEnabled(bool enabled) {
    if (!_inRoom && !_previewOnly) return;
    if (enabled) {
      _cloud?.startLocalAudio(TRTCAudioQuality.speech);
      _cloud?.muteLocalAudio(false);
    } else {
      _cloud?.muteLocalAudio(true);
    }
    _micOn = enabled;
    _trtcLog('mute_unmute', {'micEnabled': enabled});
  }

  void setCameraEnabled(bool enabled) {
    if (_cloud == null) return;
    if (!_inRoom && !_previewOnly) return;
    if (!_isHost && !_twoWayVideo && !_previewOnly) return;
    _cloud!.muteLocalVideo(TRTCVideoStreamType.big, !enabled);
    _cameraOn = enabled;
    _trtcLog('camera_on_off', {'cameraEnabled': enabled});
  }

  void setAllRemoteAudioMuted(bool mute) {
    _cloud?.muteAllRemoteAudio(mute);
  }

  void switchCamera() {
    _device?.switchCamera(_cameraOn);
  }

  Future<void> leave() async {
    _trtcLog('leave', {'inRoom': _inRoom});
    stopPublishedMusic();
    onConnectionLost = null;
    networkQuality.value = null;
    remoteVideoAvailable.value = false;
    _expectedAnchorUserId = null;
    _clearRemoteAnchor();
    _remoteUserIds.clear();
    remoteUserIdsNotifier.value = const [];
    remoteVideoByUser.value = const {};
    remoteAudioByUser.value = const {};
    if (_cloud != null) {
      _cloud!.stopLocalPreview();
      _cloud!.stopLocalAudio();
      if (_inRoom) {
        _exitRoomCompleter = Completer<void>();
        _cloud!.exitRoom();
        try {
          await _exitRoomCompleter!.future.timeout(
            const Duration(milliseconds: 500),
            onTimeout: () {},
          );
        } catch (_) {}
        _exitRoomCompleter = null;
      }
      if (_listener != null) {
        _cloud!.unRegisterListener(_listener!);
        _listener = null;
      }
    }
    _inRoom = false;
    _previewOnly = false;
    _audioOnly = false;
    _isHost = false;
    _twoWayVideo = false;
    _localUserId = null;
    _micOn = false;
    _cameraOn = false;
    if (_activeSession == this) {
      _activeSession = null;
    }
  }

  static const int voiceRoomMusicId = 88001;
  var _publishedMusicPlaying = false;

  /// DJ / !istek müziğini TRTC uplink'e karıştır (uzak dinleyiciler duyar).
  Future<void> playPublishedMusic(
    String url, {
    int startMs = 0,
    int publishVolume = 80,
  }) async {
    if (!isSupported || _cloud == null || url.trim().isEmpty) return;
    final path = url.trim();
    stopPublishedMusic();
    final effect = _cloud!.getAudioEffectManager();
    effect.startPlayMusic(
      AudioMusicParam(
        id: voiceRoomMusicId,
        path: path,
        publish: true,
        loopCount: 0,
        startTimeMS: startMs.clamp(0, 1 << 30),
      ),
    );
    effect.setMusicPublishVolume(voiceRoomMusicId, publishVolume);
    _publishedMusicPlaying = true;
    VoiceRoomDebugLog.log('trtc.music.publish.start', {
      'url': path.length > 64 ? '${path.substring(0, 64)}…' : path,
      'startMs': startMs,
    });
  }

  void pausePublishedMusic() {
    if (_cloud == null || !_publishedMusicPlaying) return;
    _cloud!.getAudioEffectManager().pausePlayMusic(voiceRoomMusicId);
    _publishedMusicPlaying = false;
    VoiceRoomDebugLog.log('trtc.music.publish.pause', {});
  }

  void resumePublishedMusic() {
    if (_cloud == null) return;
    _cloud!.getAudioEffectManager().resumePlayMusic(voiceRoomMusicId);
    _publishedMusicPlaying = true;
    VoiceRoomDebugLog.log('trtc.music.publish.resume', {});
  }

  void stopPublishedMusic() {
    if (_cloud == null) return;
    try {
      _cloud!.getAudioEffectManager().stopPlayMusic(voiceRoomMusicId);
    } catch (_) {}
    _publishedMusicPlaying = false;
  }

  Future<void> disposeAsync() async {
    _trtcLog('dispose');
    stopPublishedMusic();
    await leave();
    _cloud = null;
    _device = null;
  }

  void dispose() {
    unawaited(disposeAsync());
  }

  static void destroyEngine() {
    try {
      TRTCCloud.destroySharedInstance();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TRTC destroy: $e');
      }
    }
  }
}

/// Yerel kamera önizlemesi.
class TrtcLocalVideoView extends StatelessWidget {
  const TrtcLocalVideoView({super.key, required this.manager});

  final TrtcRoomManager manager;

  @override
  Widget build(BuildContext context) {
    return TRTCCloudVideoView(
      onViewCreated: (viewId) => manager.startLocalPreview(viewId),
    );
  }
}

/// Uzak yayıncı videosu.
class TrtcRemoteVideoView extends StatelessWidget {
  const TrtcRemoteVideoView({
    super.key,
    required this.manager,
    required this.userId,
  });

  final TrtcRoomManager manager;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return TRTCCloudVideoView(
      key: ValueKey('remote-$userId'),
      onViewCreated: (viewId) => manager.startRemoteView(userId, viewId),
    );
  }
}
