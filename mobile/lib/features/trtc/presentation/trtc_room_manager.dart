import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  bool _inRoom = false;
  bool _micOn = true;
  bool _cameraOn = true;

  String? remoteAnchorUserId;
  final ValueNotifier<bool> remoteVideoAvailable = ValueNotifier(false);

  bool get isSupported => !kIsWeb;
  bool get inRoom => _inRoom;
  bool get micOn => _micOn;
  bool get cameraOn => _cameraOn;

  static Future<bool> requestPermissions({required bool video}) async {
    if (kIsWeb) return false;
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return false;
    if (video) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) return false;
    }
    return true;
  }

  Future<void> join({
    required TrtcCredentials credentials,
    required bool isHost,
    required bool audioOnly,
  }) async {
    if (!isSupported) {
      throw StateError('TRTC yalnızca Android/iOS üzerinde desteklenir');
    }

    final ok = await requestPermissions(video: !audioOnly && isHost);
    if (!ok) {
      throw StateError('Mikrofon veya kamera izni verilmedi');
    }

    _cloud ??= await TRTCCloud.sharedInstance();
    _device ??= _cloud!.getDeviceManager();

    _listener ??= TRTCCloudListener(
      onError: (code, msg) => debugPrint('TRTC error $code: $msg'),
      onEnterRoom: (result) {
        _inRoom = result > 0;
        debugPrint('TRTC enterRoom: $result');
      },
      onRemoteUserEnterRoom: (userId) {
        debugPrint('TRTC remote enter: $userId');
      },
      onUserVideoAvailable: (userId, available) {
        if (available) {
          remoteAnchorUserId = userId;
          remoteVideoAvailable.value = true;
        } else if (remoteAnchorUserId == userId) {
          remoteVideoAvailable.value = false;
        }
      },
    );
    _cloud!.registerListener(_listener!);

    final params = TRTCParams(
      sdkAppId: credentials.sdkAppId,
      userId: credentials.userId,
      userSig: credentials.userSig,
      strRoomId: credentials.roomId,
      role: isHost ? TRTCRoleType.anchor : TRTCRoleType.audience,
    );

    final scene =
        audioOnly ? TRTCAppScene.voiceChatRoom : TRTCAppScene.live;
    _cloud!.enterRoom(params, scene);

    if (audioOnly) {
      _cloud!.startLocalAudio(TRTCAudioQuality.defaultMode);
      _device?.setAudioRoute(TXAudioRoute.speakerPhone);
      _micOn = true;
    } else if (isHost) {
      _cloud!.startLocalAudio(TRTCAudioQuality.defaultMode);
      _micOn = true;
    }
  }

  void startLocalPreview(int viewId) {
    _cloud?.startLocalPreview(true, viewId);
    _cameraOn = true;
  }

  void stopLocalPreview() {
    _cloud?.stopLocalPreview();
    _cameraOn = false;
  }

  void startRemoteView(String userId, int viewId) {
    _cloud?.startRemoteView(userId, TRTCVideoStreamType.big, viewId);
  }

  void stopRemoteView(String userId) {
    _cloud?.stopRemoteView(userId, TRTCVideoStreamType.big);
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
    remoteAnchorUserId = null;
    if (_cloud != null) {
      _cloud!.stopLocalPreview();
      _cloud!.stopLocalAudio();
      _cloud!.exitRoom();
      if (_listener != null) {
        _cloud!.unRegisterListener(_listener!);
      }
    }
    _inRoom = false;
    _micOn = false;
    _cameraOn = false;
  }

  void dispose() {
    leave();
    _cloud = null;
    _device = null;
    _listener = null;
    // destroySharedInstance() uygulama açılışında native çökme yapabiliyor;
    // paylaşılan örneği yalnızca process sonunda bırakıyoruz.
  }

  /// Uygulama kapanırken (isteğe bağlı) çağrılabilir.
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
      onViewCreated: (viewId) => manager.startRemoteView(userId, viewId),
    );
  }
}
