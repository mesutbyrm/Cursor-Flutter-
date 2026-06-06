import 'package:flutter/material.dart';

import '../../../../../core/ui/premium_2026/premium_motion.dart';
import 'discover_premium_visual.dart';
import '../../../domain/discover_category.dart';

/// Yatay neon kategori kartları (8 kategori).
class DiscoverPremiumCategories extends StatelessWidget {
  const DiscoverPremiumCategories({
    super.key,
    required this.selectedId,
    required this.onCategoryTap,
  });

  final String? selectedId;
  final ValueChanged<String?> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Text(
            'Kategoriler',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.95),
              letterSpacing: -0.3,
            ),
          ),
        ),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: PremiumMotion.listPhysics,
            itemCount: DiscoverCategories.all.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final c = DiscoverCategories.all[i];
              final selected = selectedId == c.id;
              return _CategoryPill(
                def: c,
                selected: selected,
                onTap: () => onCategoryTap(selected ? null : c.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryPill extends StatefulWidget {
  const _CategoryPill({
    required this.def,
    required this.selected,
    required this.onTap,
  });

  final DiscoverCategoryDef def;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_CategoryPill> createState() => _CategoryPillState();
}

class _CategoryPillState extends State<_CategoryPill> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: PremiumMotion.fast,
        curve: PremiumMotion.spring,
        child: AnimatedContainer(
          duration: PremiumMotion.medium,
          width: 118,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.def.gradient,
            ),
            border: widget.selected
                ? Border.all(color: Colors.white, width: 2)
                : Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: DiscoverPremiumVisual.cardGlow(
              color: widget.def.gradient.first,
              pressed: widget.selected,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.def.icon, color: Colors.white, size: 22),
              const Spacer(),
              Text(
                widget.def.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
