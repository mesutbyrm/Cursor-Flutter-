import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/native_site_routes.dart';
import '../../../domain/entities/home_page_button_entity.dart';
import '../../providers/home_providers.dart';
import '../../theme/home_approved_design.dart';

/// Ana sayfa hızlı erişim — API butonları veya statik yedek.
class HomeQuickActions extends ConsumerWidget {
  const HomeQuickActions({super.key});

  static const _staticActions = <_QuickActionData>[
    _QuickActionData(
      icon: Icons.mic_rounded,
      label: 'Sesli Oda',
      colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
      route: '/voice-rooms',
    ),
    _QuickActionData(
      icon: Icons.groups_rounded,
      label: 'Sosyal',
      colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
      route: '/social',
    ),
    _QuickActionData(
      icon: Icons.auto_awesome_rounded,
      label: 'Fal & Tarot',
      colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
      route: '/fortune',
    ),
  ];

  static const _chipPalettes = <List<Color>>[
    [Color(0xFF7C3AED), Color(0xFFDB2777)],
    [Color(0xFF2563EB), Color(0xFF7C3AED)],
    [Color(0xFF06B6D4), Color(0xFF0E7490)],
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
                      colors: _chipPalettes[i % _chipPalettes.length],
                    )
                  : _StaticActionChip(action: _staticActions[i]),
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
    required this.colors,
    required this.route,
  });

  final IconData icon;
  final String label;
  final List<Color> colors;
  final String route;
}

class _StaticActionChip extends StatelessWidget {
  const _StaticActionChip({required this.action});

  final _QuickActionData action;

  @override
  Widget build(BuildContext context) {
    return _ActionChip(
      icon: action.icon,
      label: action.label,
      colors: action.colors,
      onTap: () {
        if (action.route == '/social' || action.route == '/fortune') {
          context.go(action.route);
        } else {
          context.push(action.route);
        }
      },
    );
  }
}

class _ApiActionChip extends StatelessWidget {
  const _ApiActionChip({required this.button, required this.colors});

  final HomePageButtonEntity button;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return _ActionChip(
      icon: _iconForLink(button.linkUrl),
      label: button.label,
      colors: colors,
      onTap: () {
        final link = button.linkUrl?.trim();
        if (link != null && link.contains('bana-ozel')) {
          context.push('/fortune/bana-ozel');
          return;
        }
        if (link != null && link.isNotEmpty) {
          openNativeSitePath(context, link);
        }
      },
    );
  }

  static IconData _iconForLink(String? link) {
    final path = (link ?? '').toLowerCase();
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
    if (path.contains('live') || path.contains('canli')) {
      return Icons.sensors_rounded;
    }
    return Icons.bolt_rounded;
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(colors: colors),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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
