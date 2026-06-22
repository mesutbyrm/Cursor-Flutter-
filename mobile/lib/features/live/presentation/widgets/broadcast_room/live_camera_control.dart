import 'package:flutter/material.dart';

import '../../../../agora/presentation/agora_room_manager.dart';
import '../../../../trtc/presentation/trtc_room_manager.dart';

/// Kamera aç/kapat — Agora veya TRTC yöneticisi.
class LiveCameraToggleButton extends StatelessWidget {
  const LiveCameraToggleButton({
    super.key,
    this.agora,
    this.trtc,
    this.size = 48,
    this.onChanged,
  }) : assert(agora != null || trtc != null, 'agora veya trtc gerekli');

  final AgoraRoomManager? agora;
  final TrtcRoomManager? trtc;
  final double size;
  final VoidCallback? onChanged;

  bool get _cameraOn => agora?.cameraOn ?? trtc?.cameraOn ?? false;

  Future<void> _toggle() async {
    if (agora != null) {
      await agora!.setCameraEnabled(!agora!.cameraOn);
    } else {
      trtc!.setCameraEnabled(!trtc!.cameraOn);
    }
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isCameraOn = _cameraOn;

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCameraOn
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.red.withValues(alpha: 0.8),
        ),
        child: Icon(
          isCameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}

/// Ön / arka kamera geçişi.
class LiveCameraSwitchButton extends StatelessWidget {
  const LiveCameraSwitchButton({
    super.key,
    this.agora,
    this.trtc,
    this.size = 48,
  }) : assert(agora != null || trtc != null, 'agora veya trtc gerekli');

  final AgoraRoomManager? agora;
  final TrtcRoomManager? trtc;
  final double size;

  void _switch() {
    if (agora != null) {
      agora!.switchCamera();
    } else {
      trtc!.switchCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _switch,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.15),
        ),
        child: Icon(
          Icons.flip_camera_ios_rounded,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}

/// Mikrofon aç/kapat.
class LiveMicToggleButton extends StatelessWidget {
  const LiveMicToggleButton({
    super.key,
    this.agora,
    this.trtc,
    this.size = 48,
    this.onChanged,
  }) : assert(agora != null || trtc != null, 'agora veya trtc gerekli');

  final AgoraRoomManager? agora;
  final TrtcRoomManager? trtc;
  final double size;
  final VoidCallback? onChanged;

  bool get _micOn => agora?.micOn ?? trtc?.micOn ?? false;

  void _toggle() {
    if (agora != null) {
      agora!.setMicEnabled(!agora!.micOn);
    } else {
      trtc!.setMicEnabled(!trtc!.micOn);
    }
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isMuted = !_micOn;

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isMuted
              ? Colors.red.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.15),
        ),
        child: Icon(
          isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}

/// Yayıncı RTC kontrol şeridi — kamera, çevir, mikrofon.
class LiveHostRtcControlBar extends StatelessWidget {
  const LiveHostRtcControlBar({
    super.key,
    this.agora,
    this.trtc,
    this.onRtcStateChanged,
    this.onEnd,
  }) : assert(agora != null || trtc != null, 'agora veya trtc gerekli');

  final AgoraRoomManager? agora;
  final TrtcRoomManager? trtc;
  final VoidCallback? onRtcStateChanged;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LiveCameraToggleButton(
            agora: agora,
            trtc: trtc,
            onChanged: onRtcStateChanged,
          ),
          const SizedBox(width: 16),
          LiveCameraSwitchButton(agora: agora, trtc: trtc),
          const SizedBox(width: 16),
          LiveMicToggleButton(
            agora: agora,
            trtc: trtc,
            onChanged: onRtcStateChanged,
          ),
          if (onEnd != null) ...[
            const SizedBox(width: 16),
            GestureDetector(
              onTap: onEnd,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: 0.85),
                ),
                child: const Icon(Icons.stop_rounded, color: Colors.white, size: 24),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
