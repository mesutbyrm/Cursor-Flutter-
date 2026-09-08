import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'ultra_fortune_liquid_surface.dart';
import 'ultra_fortune_tokens.dart';

/// Fal hub — hızlı erişim butonları (hazır yorum, geçmiş, canlı falcı, bana özel).
class UltraFortuneQuickActions extends StatelessWidget {
  const UltraFortuneQuickActions({super.key});

  static const _items = [
    _QuickAction(
      label: 'Hazır\nYorumlar',
      icon: Icons.menu_book_rounded,
      color: UltraFortuneTokens.metallicGold,
      route: '/fortune/ready',
    ),
    _QuickAction(
      label: 'Fal\nGeçmişim',
      icon: Icons.history_rounded,
      color: UltraFortuneTokens.softLilac,
      route: '/favorites',
    ),
    _QuickAction(
      label: 'Canlı\nFalcılar',
      icon: Icons.psychology_rounded,
      color: UltraFortuneTokens.electricPurple,
      route: '/canli-falcilar',
    ),
    _QuickAction(
      label: 'Bana\nÖzel',
      icon: Icons.auto_fix_high_rounded,
      color: const Color(0xFF4ADE80),
      route: '/fortune/bana-ozel',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _QuickActionTile(item: _items[i])),
          ],
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String route;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.item});

  final _QuickAction item;

  @override
  Widget build(BuildContext context) {
    return UltraFortuneLiquidSurface(
      onTap: () => context.push(item.route),
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      blur: 36,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.color.withValues(alpha: 0.2),
              boxShadow: [
                BoxShadow(
                  color: item.color.withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
