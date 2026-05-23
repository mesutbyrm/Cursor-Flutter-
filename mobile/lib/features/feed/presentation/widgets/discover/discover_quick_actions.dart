import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/ui/premium/premium.dart';
import 'discover_section_header.dart';

class DiscoverQuickActions extends StatelessWidget {
  const DiscoverQuickActions({super.key});

  static const _otherActions = <_QuickAction>[
    _QuickAction(
      icon: Icons.graphic_eq_rounded,
      label: 'Sesli Odaya\nGir',
      gradient: [Color(0xFF6B21FF), Color(0xFF3B0764)],
    ),
    _QuickAction(
      icon: Icons.group_rounded,
      label: 'Arkadaşlarını\nDavet Et',
      gradient: [Color(0xFFFFB347), Color(0xFFFF8C00)],
    ),
    _QuickAction(
      icon: Icons.card_giftcard_rounded,
      label: 'Hediye\nYolla',
      gradient: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    ),
    _QuickAction(
      icon: Icons.diamond_rounded,
      label: 'Jeton\nYükle',
      gradient: [Color(0xFF2DD4BF), Color(0xFF0891B2)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiscoverSectionHeader(
          title: 'Hızlı İşlemler',
          actionLabel: 'Tümünü gör',
          onAction: () => context.go('/live'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LiveStartSlot(onTap: () => context.push('/live/prep')),
                const SizedBox(width: 6),
                ...List.generate(_otherActions.length, (i) {
                  final a = _otherActions[i];
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: i == 0 ? 0 : 4,
                        right: i == _otherActions.length - 1 ? 0 : 4,
                      ),
                      child: PremiumQuickActionTile(
                        icon: a.icon,
                        label: a.label,
                        gradient: a.gradient,
                        onTap: () => _handleOtherTap(context, i),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _handleOtherTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.push('/voice-rooms');
      case 1:
        context.push('/invite-friends');
      case 2:
        context.go('/live');
      case 3:
        context.push('/jeton-store');
    }
  }
}

class _LiveStartSlot extends StatelessWidget {
  const _LiveStartSlot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GradientFab(
            icon: Icons.videocam_rounded,
            onTap: onTap,
            size: 64,
            offsetY: 0,
          ),
          const SizedBox(height: 6),
          Text(
            'Canlı Yayın\nBaşlat',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  fontSize: 9,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
}
