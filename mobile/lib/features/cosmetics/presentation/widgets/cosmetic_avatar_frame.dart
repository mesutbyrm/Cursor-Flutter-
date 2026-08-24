import 'package:flutter/material.dart';

import '../../domain/cosmetic_effect_kind.dart';
import '../../domain/cosmetic_item.dart';
import 'cosmetic_frame_painter.dart';
import 'cosmetic_particle_overlay.dart';

/// Yetkiye / Gold seçimine göre animasyonlu profil çerçevesi.
class CosmeticAvatarFrame extends StatefulWidget {
  const CosmeticAvatarFrame({
    super.key,
    required this.child,
    required this.item,
    this.size = 88,
    this.showParticles = true,
  });

  final Widget child;
  final CosmeticItem? item;
  final double size;
  final bool showParticles;

  @override
  State<CosmeticAvatarFrame> createState() => _CosmeticAvatarFrameState();
}

class _CosmeticAvatarFrameState extends State<CosmeticAvatarFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (item == null || item.effectKind == CosmeticEffectKind.plain) {
      return widget.child;
    }

    final colors = item.colors
        .map((c) => _parseHex(c.hex))
        .whereType<Color>()
        .toList();

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (widget.showParticles && item.effectKind.isParticle)
            CosmeticParticleOverlay(
              kind: item.effectKind,
              size: widget.size,
              controller: _ctrl,
            ),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return CustomPaint(
                size: Size.square(widget.size),
                painter: CosmeticFramePainter(
                  kind: item.effectKind,
                  progress: _ctrl.value,
                  colors: colors,
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(5),
            child: ClipOval(child: widget.child),
          ),
        ],
      ),
    );
  }

  Color? _parseHex(String hex) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    return Color(int.parse(h, radix: 16));
  }
}
