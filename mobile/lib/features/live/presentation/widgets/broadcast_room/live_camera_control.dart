import 'package:flutter/material.dart';

import '../../../../trtc/presentation/trtc_room_manager.dart';

/// Kamera aç/kapat — Tencent TRTC.
class LiveCameraToggleButton extends StatelessWidget {
  const LiveCameraToggleButton({
    super.key,
    required this.trtc,
    this.size = 48,
    this.onChanged,
  });

  final TrtcRoomManager trtc;
  final double size;
  final VoidCallback? onChanged;

  bool get _cameraOn => trtc.cameraOn;

  Future<void> _toggle() async {
    trtc.setCameraEnabled(!trtc.cameraOn);
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _toggle,
      icon: Icon(
        _cameraOn ? Icons.videocam : Icons.videocam_off,
        size: size * 0.5,
        color: Colors.white,
      ),
    );
  }
}

class LiveCameraSwitchButton extends StatelessWidget {
  const LiveCameraSwitchButton({super.key, required this.trtc});

  final TrtcRoomManager trtc;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: trtc.switchCamera,
      icon: const Icon(Icons.cameraswitch, color: Colors.white),
    );
  }
}

class LiveMicToggleButton extends StatelessWidget {
  const LiveMicToggleButton({
    super.key,
    required this.trtc,
    this.size = 48,
    this.onChanged,
  });

  final TrtcRoomManager trtc;
  final double size;
  final VoidCallback? onChanged;

  bool get _micOn => trtc.micOn;

  Future<void> _toggle() async {
    trtc.setMicEnabled(!trtc.micOn);
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _toggle,
      icon: Icon(
        _micOn ? Icons.mic : Icons.mic_off,
        size: size * 0.5,
        color: Colors.white,
      ),
    );
  }
}

class LiveBroadcastControls extends StatelessWidget {
  const LiveBroadcastControls({
    super.key,
    required this.trtc,
    this.onCameraChanged,
    this.onMicChanged,
  });

  final TrtcRoomManager trtc;
  final VoidCallback? onCameraChanged;
  final VoidCallback? onMicChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LiveMicToggleButton(
          trtc: trtc,
          onChanged: onMicChanged,
        ),
        LiveCameraToggleButton(
          trtc: trtc,
          onChanged: onCameraChanged,
        ),
        LiveCameraSwitchButton(trtc: trtc),
      ],
    );
  }
}
