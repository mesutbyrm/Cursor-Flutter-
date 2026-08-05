import 'package:flutter/material.dart';

import 'package:canlifal_social/features/profile/presentation/widgets/premium/profile_glass.dart';
import '../../../live/presentation/widgets/broadcast_room/live_room_video_background.dart';
import '../../../trtc/presentation/trtc_room_manager.dart';
import '../../domain/entities/psychic_session_entity.dart';
import '../controllers/psychic_video_controller.dart';

/// Karşılıklı görüşme — uzak tam ekran + yerel PiP (kamera aç/kapa döngüsü yok).
class PsychicVideoCallLayer extends StatelessWidget {
  const PsychicVideoCallLayer({
    super.key,
    required this.session,
    required this.state,
    required this.ctrl,
  });

  final PsychicSessionEntity session;
  final PsychicVideoState state;
  final PsychicVideoController ctrl;

  @override
  Widget build(BuildContext context) {
    if (!state.rtcReady) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const LiveRoomVideoBackground(),
          Center(
            child: ProfileGlass(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              borderRadius: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.rtcError != null) ...[
                    Text(
                      state.rtcError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: ctrl.retryRtc,
                      child: const Text('Yeniden Bağlan'),
                    ),
                  ] else ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Bağlantı kuruluyor…',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ValueListenableBuilder<String?>(
      valueListenable: ctrl.trtc.remoteAnchorUserIdNotifier,
      builder: (context, remoteUserId, _) {
        final hasRemote =
            remoteUserId != null && remoteUserId.trim().isNotEmpty;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (hasRemote)
              TrtcRemoteVideoView(
                key: ValueKey('remote-$remoteUserId'),
                manager: ctrl.trtc,
                userId: remoteUserId!,
              )
            else
              const LiveRoomVideoBackground(),
            Positioned(
              top: 12,
              right: 12,
              width: 100,
              height: 140,
              child: Opacity(
                opacity: ctrl.cameraOn ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !ctrl.cameraOn,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: TrtcLocalVideoView(manager: ctrl.trtc),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
