import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tencent_rtc_sdk/trtc_cloud.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_def.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_listener.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_video_view.dart';
import 'package:tencent_rtc_sdk/tx_device_manager.dart';

import '../domain/entities/trtc_credentials.dart';

/// Tencent TRTC oda oturumu — canlı yayın ve sesli sohbet.
class TrtcRoomManager {
  TRTCCloud? _cloud;
  TXDeviceManager? _device;
  TRTCCloudListener? _listener;
  Completer<int>? _enterRoomCompleter;

  bool _inRoom = false;
  bool _micOn = true;
  bool _cameraOn = true;
  bool _isHost = false;

  String? remoteAnchorUserId;
  final ValueNotifier<String?> remoteAnchorUserIdNotifier =
      ValueNotifier<String?>(null);
  final ValueNotifier<bool> remoteVideoAvailable = ValueNotifier(false);

  int? _boundRemoteViewId;
  String? _boundRemoteUserId;

  bool get isSupported => !kIsWeb;
  bool get inRoom => _inRoom;
  bool get micOn => _micOn;
  bool get cameraOn => _cameraOn;

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
      debugPrint(
        'permission_handler kayıtlı değil — uygulamayı tamamen kapatıp yeniden kurun.',
      );
      return false;
    } catch (e) {
      debugPrint('İzin hatası: $e');
      return false;
    }
  }

  Future<void> join({
    required TrtcCredentials credentials,
    required bool isHost,
    required bool audioOnly,
  }) async {
    if (!isSupported) {
      throw StateError('TRTC yalnızca Android/iOS üzerinde desteklenir');
    }

    final roomId = credentials.roomId.trim();
    if (roomId.isEmpty) {
      throw StateError('TRTC oda kimliği boş — yayına bağlanılamadı');
    }

    try {
      await TRTCCloud.sharedInstance();
    } catch (e) {
      throw StateError(
        'Tencent RTC bu cihazda başlatılamadı. Lütfen uygulamayı yeniden başlatın.',
      );
    }

    final ok = await requestPermissions(video: !audioOnly && isHost);
    if (!ok) {
      throw StateError('Mikrofon veya kamera izni verilmedi');
    }

    if (_inRoom) {
      await leave();
    }

    _cloud ??= await TRTCCloud.sharedInstance();
    _device ??= _cloud!.getDeviceManager();
    _isHost = isHost;

    _enterRoomCompleter = Completer<int>();
    if (_cloud != null && _listener != null) {
      _cloud!.unRegisterListener(_listener!);
    }
    _listener = TRTCCloudListener(
      onError: (code, msg) => debugPrint('TRTC error $code: $msg'),
      onEnterRoom: (result) {
        _inRoom = result > 0;
        debugPrint('TRTC enterRoom: $result room=$roomId host=$_isHost');
        final c = _enterRoomCompleter;
        if (c != null && !c.isCompleted) c.complete(result);
      },
      onRemoteUserEnterRoom: (userId) {
        debugPrint('TRTC remote enter: $userId');
        if (!_isHost) {
          _setRemoteAnchor(userId);
        }
      },
      onRemoteUserLeaveRoom: (userId, _) {
        if (remoteAnchorUserId == userId) {
          _clearRemoteAnchor();
        }
      },
      onUserVideoAvailable: (userId, available) {
        debugPrint('TRTC video $userId available=$available');
        if (!_isHost && available) {
          _setRemoteAnchor(userId);
          _tryBindPendingRemoteView(userId);
        } else if (remoteAnchorUserId == userId && !available) {
          remoteVideoAvailable.value = false;
          stopRemoteView(userId);
        }
      },
      onUserAudioAvailable: (userId, available) {
        debugPrint('TRTC audio $userId available=$available');
        if (!_isHost) {
          if (available) {
            _setRemoteAnchor(userId);
            _cloud?.muteRemoteAudio(userId, false);
          } else {
            _cloud?.muteRemoteAudio(userId, true);
          }
        }
      },
    );
    _cloud!.registerListener(_listener!);

    // Canlı yayın izleyicisi: otomatik ses/video alımı (enterRoom öncesi).
    if (!audioOnly) {
      _cloud!.setDefaultStreamRecvMode(true, true);
    }

    final params = TRTCParams(
      sdkAppId: credentials.sdkAppId,
      userId: credentials.userId,
      userSig: credentials.userSig,
      roomId: 0,
      strRoomId: roomId,
      role: isHost ? TRTCRoleType.anchor : TRTCRoleType.audience,
    );

    final scene =
        audioOnly ? TRTCAppScene.voiceChatRoom : TRTCAppScene.live;
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

    if (audioOnly) {
      _cloud!.startLocalAudio(TRTCAudioQuality.defaultMode);
      _device?.setAudioRoute(TXAudioRoute.speakerPhone);
      _micOn = true;
    } else if (isHost) {
      _cloud!.startLocalAudio(TRTCAudioQuality.defaultMode);
      _cloud!.muteLocalVideo(TRTCVideoStreamType.big, false);
      _micOn = true;
    } else {
      _device?.setAudioRoute(TXAudioRoute.speakerPhone);
    }
  }

  void _setRemoteAnchor(String userId) {
    if (userId.isEmpty) return;
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
    if (_cloud == null || !_inRoom) return;
    _cloud!.muteLocalVideo(TRTCVideoStreamType.big, false);
    _cloud!.startLocalPreview(true, viewId);
    _cameraOn = true;
  }

  void stopLocalPreview() {
    _cloud?.stopLocalPreview();
    _cloud?.muteLocalVideo(TRTCVideoStreamType.big, true);
    _cameraOn = false;
  }

  void startRemoteView(String userId, int viewId) {
    if (_cloud == null || !_inRoom) return;
    _boundRemoteUserId = userId;
    _boundRemoteViewId = viewId;
    _cloud!.startRemoteView(userId, TRTCVideoStreamType.big, viewId);
    _cloud!.muteRemoteAudio(userId, false);
  }

  void stopRemoteView(String userId) {
    _cloud?.stopRemoteView(userId, TRTCVideoStreamType.big);
    if (_boundRemoteUserId == userId) {
      _boundRemoteViewId = null;
      _boundRemoteUserId = null;
    }
  }

  void setMicEnabled(bool enabled) {
    if (enabled) {
      _cloud?.startLocalAudio(TRTCAudioQuality.defaultMode);
    } else {
      _cloud?.stopLocalAudio();
    }
    _micOn = enabled;
  }

  void switchCamera() {
    _device?.switchCamera(_cameraOn);
  }

  Future<void> leave() async {
    remoteVideoAvailable.value = false;
    _clearRemoteAnchor();
    if (_cloud != null) {
      _cloud!.stopLocalPreview();
      _cloud!.stopLocalAudio();
      _cloud!.exitRoom();
      if (_listener != null) {
        _cloud!.unRegisterListener(_listener!);
      }
    }
    _inRoom = false;
    _isHost = false;
    _micOn = false;
    _cameraOn = false;
  }

  void dispose() {
    leave();
    _cloud = null;
    _device = null;
    _listener = null;
  }

  static void destroyEngine() {
    try {
      TRTCCloud.destroySharedInstance();
    } catch (e) {
      debugPrint('TRTC destroy: $e');
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
