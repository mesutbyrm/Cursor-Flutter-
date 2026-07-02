import 'package:flutter/material.dart';

import '../../../domain/okey101/okey101_models.dart';

class Okey101TileWidget extends StatelessWidget {
  const Okey101TileWidget({
    super.key,
    required this.tile,
    this.okey,
    this.selected = false,
    this.compact = false,
    this.onTap,
  });

  final Okey101Tile tile;
  final Okey101Tile? okey;
  final bool selected;
  final bool compact;
  final VoidCallback? onTap;

  Color get _faceColor {
    if (tile.isWild(okey)) return const Color(0xFF059669);
    return switch (tile.color) {
      OkeyColor.red => const Color(0xFFDC2626),
      OkeyColor.yellow => const Color(0xFFEAB308),
      OkeyColor.blue => const Color(0xFF2563EB),
      OkeyColor.black => const Color(0xFF1F2937),
      OkeyColor.joker => const Color(0xFF059669),
    };
  }

  @override
  Widget build(BuildContext context) {
    final w = compact ? 34.0 : 44.0;
    final h = compact ? 48.0 : 62.0;
    final label = tile.isFakeJoker || tile.color == OkeyColor.joker
        ? '★'
        : '${tile.value}';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: w,
        height: h,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? Colors.amber : Colors.black26,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: w - 10,
              height: 6,
              decoration: BoxDecoration(
                color: _faceColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 16 : 20,
                fontWeight: FontWeight.w900,
                color: _faceColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Okey101HiddenTile extends StatelessWidget {
  const Okey101HiddenTile({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final w = compact ? 34.0 : 44.0;
    final h = compact ? 48.0 : 62.0;
    return Container(
      width: w,
      height: h,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: const Icon(Icons.circle, size: 8, color: Colors.white38),
    );
  }
}
