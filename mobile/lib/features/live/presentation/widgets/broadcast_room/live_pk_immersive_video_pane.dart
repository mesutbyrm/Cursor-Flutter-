import 'package:flutter/material.dart';

import 'live_pk_streamer_chip.dart';

/// Tek PK video hücresi — cover, gradient, yayıncı chip.
class LivePkImmersiveVideoPane extends StatelessWidget {
  const LivePkImmersiveVideoPane({
    super.key,
    required this.video,
    required this.displayName,
    this.avatarUrl,
    this.micOn = true,
    this.cameraOn = true,
    this.isLocal = false,
    this.chipAlignment = Alignment.topLeft,
    this.streamerUserId,
    this.showFollowOnChip = false,
  });

  final Widget video;
  final String displayName;
  final String? avatarUrl;
  final bool micOn;
  final bool cameraOn;
  final bool isLocal;
  final Alignment chipAlignment;
  final String? streamerUserId;
  final bool showFollowOnChip;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment.center,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.5,
                  height: MediaQuery.sizeOf(context).height,
                  child: video,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.15),
                  ],
                  stops: const [0, 0.35, 1],
                ),
              ),
            ),
          ),
          LivePkStreamerChip(
            displayName: displayName,
            avatarUrl: avatarUrl,
            micOn: micOn,
            cameraOn: cameraOn,
            isLocal: isLocal,
            alignment: chipAlignment,
            userId: streamerUserId,
            showFollow: showFollowOnChip,
          ),
        ],
      ),
    );
  }
}
