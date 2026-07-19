import 'package:flutter/material.dart';

import '../../domain/cosmetic_effect_kind.dart';
import '../../domain/cosmetic_item.dart';

/// Backend / katalog isim efektleri — gradient, neon, shine.
class CosmeticNameLabel extends StatefulWidget {
  const CosmeticNameLabel({
    super.key,
    required this.text,
    required this.item,
    this.style,
    this.maxLines = 1,
  });

  final String text;
  final CosmeticItem? item;
  final TextStyle? style;
  final int maxLines;

  @override
  State<CosmeticNameLabel> createState() => _CosmeticNameLabelState();
}

class _CosmeticNameLabelState extends State<CosmeticNameLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.style ??
        const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: Colors.white,
        );
    final kind = widget.item?.effectKind;
    if (kind == null || kind == CosmeticEffectKind.plain) {
      return Text(
        widget.text,
        maxLines: widget.maxLines,
        overflow: TextOverflow.ellipsis,
        style: base,
      );
    }

    final colors = _gradientFor(kind);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: colors,
              begin: Alignment(-1 + _ctrl.value * 2, 0),
              end: Alignment(1 + _ctrl.value * 2, 0),
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            maxLines: widget.maxLines,
            overflow: TextOverflow.ellipsis,
            style: base.copyWith(
              shadows: [
                Shadow(
                  color: colors.first.withValues(alpha: 0.6),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Color> _gradientFor(CosmeticEffectKind kind) {
    return switch (kind) {
      CosmeticEffectKind.goldText => const [
          Color(0xFFFFF8E1),
          Color(0xFFFFD54F),
          Color(0xFFFF8F00),
        ],
      CosmeticEffectKind.silverText => const [
          Color(0xFFECEFF1),
          Color(0xFFB0BEC5),
          Color(0xFFCFD8DC),
        ],
      CosmeticEffectKind.diamondText => const [
          Color(0xFFE0F7FA),
          Color(0xFF00D2FF),
          Color(0xFFB388FF),
        ],
      CosmeticEffectKind.neonText => const [
          Color(0xFF00E5FF),
          Color(0xFFB832FF),
          Color(0xFFFF4081),
        ],
      CosmeticEffectKind.rainbowText => const [
          Colors.red,
          Colors.orange,
          Colors.yellow,
          Colors.green,
          Colors.blue,
          Colors.purple,
        ],
      CosmeticEffectKind.fireText => const [
          Color(0xFFFF5722),
          Color(0xFFFFD54F),
          Color(0xFFFF5722),
        ],
      CosmeticEffectKind.crystalText => const [
          Color(0xFFE1F5FE),
          Color(0xFF80DEEA),
          Color(0xFFFFFFFF),
        ],
      CosmeticEffectKind.hologramText => const [
          Color(0xFF69F0AE),
          Color(0xFF40C4FF),
          Color(0xFFFF4081),
        ],
      CosmeticEffectKind.glowText => const [
          Color(0xFFFFFFFF),
          Color(0xFFE1BEE7),
          Color(0xFFFFFFFF),
        ],
      _ => const [Colors.white, Color(0xFFB832FF), Colors.white],
    };
  }
}
