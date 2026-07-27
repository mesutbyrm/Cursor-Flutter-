import 'package:flutter/material.dart';

/// Agora kaldırıldı — geriye dönük import uyumluluğu (TRTC kullanın).
@Deprecated('Tencent TRTC kullanın — Agora desteği kaldırıldı')
class AgoraRoomManager {
  bool get cameraOn => false;
  bool get micOn => false;
  bool get isHost => false;
  dynamic get engine => null;

  Future<void> setCameraEnabled(bool enabled) async {}
  void setMicEnabled(bool enabled) {}
  void switchCamera() {}
  Future<void> applyBeauty({
    required bool enabled,
    double smoothness = 0,
    double lightening = 0,
    double redness = 0,
    double sharpness = 0,
  }) async {}
}

@Deprecated('Tencent TRTC kullanın')
class AgoraLocalVideoView extends StatelessWidget {
  const AgoraLocalVideoView({super.key, required this.manager});

  final AgoraRoomManager manager;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

@Deprecated('Tencent TRTC kullanın')
class AgoraRemoteVideoView extends StatelessWidget {
  const AgoraRemoteVideoView({
    super.key,
    required this.manager,
    required this.uid,
  });

  final AgoraRoomManager manager;
  final int uid;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
