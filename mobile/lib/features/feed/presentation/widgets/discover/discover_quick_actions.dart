import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_design.dart';
import 'discover_section_header.dart';

class DiscoverQuickActions extends StatelessWidget {
  const DiscoverQuickActions({super.key});

  static const _actions = <_QuickAction>[
    _QuickAction(
      icon: Icons.videocam_rounded,
      label: 'Canlı Yayın\nBaşlat',
      gradient: [Color(0xFFFF4EC8), Color(0xFFD52DFF)],
    ),
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
        SizedBox(
          height: AppDesign.quickActionSize + 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _actions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) {
              final a = _actions[i];
              return _QuickActionTile(
                action: a,
                onTap: () => _handleTap(context, i),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _handleTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/live');
      case 1:
        context.push('/voice-rooms');
      case 2:
        context.go('/profile');
      case 3:
        context.go('/live');
      case 4:
        context.go('/profile');
    }
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

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.action,
    required this.onTap,
  });

  final _QuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDesign.quickActionSize,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: action.gradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: action.gradient.first.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action.icon, color: Colors.white, size: 28),
                  const SizedBox(height: 10),
                  Text(
                    action.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
