import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/home_page_button_entity.dart';
import '../../navigation/home_page_button_navigation.dart';
import '../../providers/home_providers.dart';
import '../../theme/home_approved_design.dart';
import '../../theme/home_premium_design.dart';

/// Ana sayfa hızlı erişim — API butonları veya spec yedek (Oyunlar/Hediyeler/Yayıncı Ol).
class HomeQuickActions extends ConsumerWidget {
  const HomeQuickActions({super.key});

  static const _staticActions = <_QuickActionData>[
    _QuickActionData(
      icon: Icons.sports_esports_rounded,
      label: 'Oyunlar',
      route: '/games-hub',
    ),
    _QuickActionData(
      icon: Icons.card_giftcard_rounded,
      label: 'Hediyeler',
      route: '/gifts/hub',
    ),
    _QuickActionData(
      icon: Icons.sensors_rounded,
      label: 'Yayıncı Ol',
      route: '/falci-ol',
    ),
  ];

  static const _chipAccents = <Color>[
    Color(0xFF6366F1),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttons = ref.watch(homeHomepageButtonsProvider);
    final apiItems = buttons.valueOrNull ?? const <HomePageButtonEntity>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeApprovedDesign.hPad,
        4,
        HomeApprovedDesign.hPad,
        12,
      ),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: i < apiItems.length
                  ? _ApiActionChip(
                      button: apiItems[i],
                      accent: _chipAccents[i % _chipAccents.length],
                    )
                  : _StaticActionChip(
                      action: _staticActions[i],
                      accent: _chipAccents[i % _chipAccents.length],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;
}

class _StaticActionChip extends StatelessWidget {
  const _StaticActionChip({required this.action, required this.accent});

  final _QuickActionData action;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _ActionChip(
      icon: action.icon,
      label: action.label,
      accent: accent,
      onTap: () => context.push(action.route),
    );
  }
}

class _ApiActionChip extends StatelessWidget {
  const _ApiActionChip({required this.button, required this.accent});

  final HomePageButtonEntity button;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _ActionChip(
      icon: _iconForLink(button.linkUrl, button.label),
      label: button.label,
      accent: accent,
      onTap: () => navigateHomePageButton(context, button),
    );
  }

  static IconData _iconForLink(String? link, String label) {
    final path = '${link ?? ''} ${label}'.toLowerCase();
    if (path.contains('voice') || path.contains('sesli')) {
      return Icons.mic_rounded;
    }
    if (path.contains('social') || path.contains('sosyal')) {
      return Icons.groups_rounded;
    }
    if (path.contains('fortune') || path.contains('fal')) {
      return Icons.auto_awesome_rounded;
    }
    if (path.contains('game') || path.contains('oyun')) {
      return Icons.sports_esports_rounded;
    }
    if (path.contains('gift') || path.contains('hediye')) {
      return Icons.card_giftcard_rounded;
    }
    if (path.contains('live') ||
        path.contains('canli') ||
        path.contains('yayin') ||
        path.contains('yayıncı')) {
      return Icons.sensors_rounded;
    }
    return Icons.bolt_rounded;
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomePremiumDesign.chipRadius),
        child: Ink(
          decoration: HomePremiumDesign.glassCard(
            tint: HomePremiumDesign.surface,
            radius: HomePremiumDesign.chipRadius,
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.18),
                    border: Border.all(color: accent.withValues(alpha: 0.45)),
                  ),
                  child: Icon(icon, color: accent, size: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: HomeApprovedDesign.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
