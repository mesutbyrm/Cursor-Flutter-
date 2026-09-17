import 'package:flutter/material.dart';

/// Tek PK video hücresi — cover, gradient, alt-sol profil overlay.
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
    this.leagueLabel,
    this.footerOverlay,
    this.profileFooter,
    this.followAccent = const Color(0xFFFF2D7A),
    this.chipTopInset = 8,
    this.showInlineMediaIcons = false,
    this.localMediaCorner,
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
  final String? leagueLabel;
  final Widget? footerOverlay;
  final Widget? profileFooter;
  final Color followAccent;
  final double chipTopInset;
  final bool showInlineMediaIcons;
  final Widget? localMediaCorner;

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
          if (profileFooter != null)
            Positioned(
              left: 6,
              right: 6,
              bottom: 6,
              child: profileFooter!,
            ),
          if (localMediaCorner != null)
            Positioned(
              top: chipTopInset,
              right: 8,
              child: localMediaCorner!,
            ),
          if (footerOverlay != null)
            Positioned(
              left: chipAlignment == Alignment.topLeft ? 10 : null,
              right: chipAlignment == Alignment.topRight ? 10 : null,
              bottom: 10,
              child: footerOverlay!,
            ),
        ],
      ),
    );
  }
}
