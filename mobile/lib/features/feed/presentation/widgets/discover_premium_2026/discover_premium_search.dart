import 'package:flutter/material.dart';
import '../../../../../core/ui/premium_2026/liquid_glass.dart';
import 'discover_premium_visual.dart';
import '../../../../../core/ui/premium_2026/premium_motion.dart';

/// Cam arama çubuğu — keşfet üstü.
class DiscoverPremiumSearchBar extends StatelessWidget {
  const DiscoverPremiumSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onOpenGlobalSearch,
    this.hint = 'Oda, yayın veya kullanıcı ara…',
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onOpenGlobalSearch;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: LiquidGlass(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        borderRadius: BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
        blur: DiscoverPremiumVisual.glassBlur,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onOpenGlobalSearch != null)
                  IconButton(
                    tooltip: 'Kullanıcı ara',
                    icon: Icon(
                      Icons.person_search_rounded,
                      color: Colors.white.withValues(alpha: 0.65),
                      size: 22,
                    ),
                    onPressed: onOpenGlobalSearch,
                  ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (_, value, __) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 20,
                      ),
                      onPressed: () {
                        controller.clear();
                        onChanged?.call('');
                      },
                    );
                  },
                ),
              ],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}

/// Sekme geçişi — Trend | Sesli | Canlı.
class DiscoverPremiumTabs extends StatelessWidget {
  const DiscoverPremiumTabs({
    super.key,
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  static const labels = ['Trend', 'Sesli', 'Canlı'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LiquidGlass(
        padding: const EdgeInsets.all(4),
        borderRadius: BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
        blur: DiscoverPremiumVisual.glassBlur,
        child: Row(
          children: List.generate(labels.length, (i) {
            final selected = index == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: PremiumMotion.medium,
                  curve: PremiumMotion.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: selected
                        ? DiscoverPremiumVisual.brandGradient
                        : null,
                    boxShadow: selected
                        ? DiscoverPremiumVisual.cardGlow(pressed: true)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
