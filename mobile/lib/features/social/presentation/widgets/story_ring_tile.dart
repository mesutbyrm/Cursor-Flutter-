import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/cds_skeleton.dart';
import '../../../../core/images/canlifal_network_image.dart';
import '../../../../core/motion/canlifal_motion_widgets.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/theme/canlifal_brand_colors.dart';
import '../../../../core/widgets/user_avatar.dart';

/// Hikâye halkası durumu.
enum StoryRingState {
  /// İzlenmemiş hikâye — renkli halka.
  unseen,

  /// Tüm hikâyeler izlendi — ince gri halka.
  seen,

  /// Hikâye yok (kendi halkası, ekle) — halkasız.
  none,
}

/// Ana sayfa ve sosyal akıştaki hikâye halkası — tek görsel dil.
class StoryRingTile extends StatelessWidget {
  const StoryRingTile({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
    this.avatarUrl,
    this.onLongPress,
    this.showAddBadge = false,
    this.size = 68,
    this.semanticsLabel,
  });

  final String label;
  final String? avatarUrl;
  final StoryRingState state;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool showAddBadge;

  /// Halka dış çapı.
  final double size;
  final String? semanticsLabel;

  static const double ringWidth = 2.5;
  static const double gap = 2.5;

  static double tileWidth(double size) => size + 10;

  static double tileHeight(double size) => size + 26;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final inner = size - (ringWidth + gap) * 2;
    final url = avatarUrl?.trim();

    final Decoration ring = switch (state) {
      StoryRingState.unseen => const BoxDecoration(
        shape: BoxShape.circle,
        gradient: CanlifalBrandColors.storyRingGradient,
      ),
      StoryRingState.seen => BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.outline, width: 1.5),
      ),
      StoryRingState.none => const BoxDecoration(shape: BoxShape.circle),
    };

    final avatar = ClipOval(
      child: SizedBox(
        width: inner,
        height: inner,
        child: url != null && url.isNotEmpty
            ? CanlifalNetworkImage(
                url: url,
                width: inner,
                height: inner,
                fit: BoxFit.cover,
                placeholder: ColoredBox(color: colors.surfaceElevated),
                errorWidget: UserAvatar(url: null, radius: inner / 2),
              )
            : UserAvatar(url: null, radius: inner / 2),
      ),
    );

    void handleTap() {
      HapticFeedback.selectionClick();
      onTap();
    }

    return Semantics(
      button: true,
      label: semanticsLabel ?? label,
      onTap: handleTap,
      onLongPress: onLongPress,
      excludeSemantics: true,
      child: CanlifalPressable(
        scale: 0.94,
        onTap: handleTap,
        onLongPress: onLongPress,
        child: SizedBox(
          width: tileWidth(size),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: ring,
                        child: Padding(
                          padding: const EdgeInsets.all(ringWidth),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.scaffoldBg,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(gap),
                              child: avatar,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (showAddBadge)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.scaffoldBg,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.2),
                style: TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: state == StoryRingState.unseen
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: state == StoryRingState.seen
                      ? colors.onSurfaceMuted
                      : colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Yükleme iskeleti — halka satırının birebir ölçüsünde.
class StoryRingSkeletonRow extends StatelessWidget {
  const StoryRingSkeletonRow({
    super.key,
    this.size = 68,
    this.count = 6,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.spacing = 8,
  });

  final double size;
  final int count;
  final EdgeInsets padding;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: count,
        separatorBuilder: (_, _) => SizedBox(width: spacing),
        itemBuilder: (_, _) => SizedBox(
          width: StoryRingTile.tileWidth(size),
          child: Column(
            children: [
              CdsSkeleton.circle(size: size),
              const SizedBox(height: 8),
              CdsSkeleton.box(
                width: size * 0.7,
                height: 9,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
