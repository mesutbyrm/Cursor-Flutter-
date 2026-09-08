import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/site_animation/presentation/site_animation_provider.dart';
import '../../../../core/site_animation/presentation/widgets/site_animation_overlay_host.dart';
import '../../domain/admin_site_animation.dart';
import '../../domain/admin_site_animation_preview_mapper.dart';
import 'admin_site_animation_preview_backgrounds.dart';

/// CanlıFal ekran mock üzerinde animasyon önizlemesi.
class AdminSiteAnimationPreviewStage extends ConsumerStatefulWidget {
  const AdminSiteAnimationPreviewStage({
    super.key,
    required this.animation,
    this.userName = 'Mesut Bayram',
    this.screen = AdminSiteAnimationPreviewScreen.voice,
    this.autoPlay = true,
  });

  final AdminSiteAnimation animation;
  final String userName;
  final AdminSiteAnimationPreviewScreen screen;
  final bool autoPlay;

  static const previewRoomId = '__admin_preview_room__';

  @override
  ConsumerState<AdminSiteAnimationPreviewStage> createState() =>
      _AdminSiteAnimationPreviewStageState();
}

class _AdminSiteAnimationPreviewStageState
    extends ConsumerState<AdminSiteAnimationPreviewStage> {
  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  @override
  void didUpdateWidget(covariant AdminSiteAnimationPreviewStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation.id != widget.animation.id ||
        oldWidget.screen != widget.screen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  void _play() {
    if (!widget.animation.isActive) return;
    final cmd = adminAnimationToPreviewCommand(
      widget.animation,
      userName: widget.userName,
      roomId: AdminSiteAnimationPreviewStage.previewRoomId,
    );
    ref
        .read(siteAnimationProvider(AdminSiteAnimationPreviewStage.previewRoomId)
            .notifier)
        .play(cmd);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SiteAnimationOverlayHost(
          roomId: AdminSiteAnimationPreviewStage.previewRoomId,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AdminSiteAnimationPreviewBackground(screen: widget.screen),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.screen.label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (widget.screen == AdminSiteAnimationPreviewScreen.voice)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '968.240',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
