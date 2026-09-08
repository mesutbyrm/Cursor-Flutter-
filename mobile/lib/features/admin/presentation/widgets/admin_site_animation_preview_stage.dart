import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/site_animation/presentation/site_animation_provider.dart';
import '../../../../core/site_animation/presentation/widgets/site_animation_overlay_host.dart';
import '../../../voice_hub/presentation/theme/voice_room_tokens.dart';
import '../../domain/admin_site_animation.dart';
import '../../domain/admin_site_animation_preview_mapper.dart';

/// Gerçek sesli oda mock — animasyon önizlemesi.
class AdminSiteAnimationPreviewStage extends ConsumerStatefulWidget {
  const AdminSiteAnimationPreviewStage({
    super.key,
    required this.animation,
    this.userName = 'Ayşe Yıldız',
    this.autoPlay = true,
  });

  final AdminSiteAnimation animation;
  final String userName;
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
    if (oldWidget.animation.id != widget.animation.id) {
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
    ref.read(siteAnimationProvider(AdminSiteAnimationPreviewStage.previewRoomId).notifier)
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
              Container(
                decoration: const BoxDecoration(
                  gradient: VoiceRoomTokens.roomGradient,
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    const Text(
                      'CanlıFal',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '968.240',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MockSeat(label: 'HOST', highlight: true),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MockSeat(label: '2'),
                        const SizedBox(width: 12),
                        _MockSeat(label: '3', occupied: true),
                        const SizedBox(width: 12),
                        _MockSeat(label: '4'),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(Icons.mic_none_rounded, color: Colors.white70),
                      Icon(Icons.card_giftcard_outlined, color: Colors.white70),
                      Icon(Icons.chat_bubble_outline_rounded, color: Colors.white70),
                      Icon(Icons.settings_outlined, color: Colors.white70),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockSeat extends StatelessWidget {
  const _MockSeat({
    required this.label,
    this.highlight = false,
    this.occupied = false,
  });

  final String label;
  final bool highlight;
  final bool occupied;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? VoiceRoomTokens.gold : VoiceRoomTokens.neonPurple;
    return Column(
      children: [
        Container(
          width: highlight ? 64 : 52,
          height: highlight ? 64 : 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.7), width: 2),
            color: Colors.white.withValues(alpha: occupied ? 0.12 : 0.05),
          ),
          child: occupied
              ? Icon(Icons.person, color: color.withValues(alpha: 0.8), size: 24)
              : Icon(Icons.add, color: Colors.white38, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
