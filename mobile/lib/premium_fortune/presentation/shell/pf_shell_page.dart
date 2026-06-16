import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/premium_2026/premium_2026_tokens.dart';
import '../../../core/ui/premium_2026/premium_immersive_background.dart';
import '../../core/di/pf_providers.dart';
import '../../core/theme/pf_theme.dart';
import '../widgets/pf_credit_badge.dart';

class PfShellPage extends ConsumerStatefulWidget {
  const PfShellPage({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PfShellPage> createState() => _PfShellPageState();
}

class _PfShellPageState extends ConsumerState<PfShellPage> {
  int _indexFromLocation(String location) {
    if (location.startsWith('/premium/live')) return 1;
    if (location.startsWith('/premium/chat')) return 2;
    if (location.startsWith('/premium/wallet')) return 3;
    if (location.startsWith('/premium/profile')) return 4;
    return 0;
  }

  void _onTap(int index) {
    switch (index) {
      case 0:
        context.go('/premium');
      case 1:
        context.go('/premium/live');
      case 2:
        context.go('/premium/chat');
      case 3:
        context.go('/premium/wallet');
      case 4:
        context.go('/premium/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _indexFromLocation(location);
    final user = ref.watch(pfEffectiveUserProvider);
    final credits = user != null
        ? ref.watch(pfCreditsProvider(user.id)).valueOrNull ?? user.credits
        : 0;

    return PremiumImmersiveBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: AppBar(
          title: const Text('Mistik Fal'),
          actions: [
            if (user != null) ...[
              PfCreditBadge(credits: credits),
              const SizedBox(width: 12),
            ],
          ],
        ),
        body: widget.child,
        bottomNavigationBar: _PfBottomNav(
          currentIndex: index,
          onTap: _onTap,
        ),
      ),
    );
  }
}

class _PfBottomNav extends StatelessWidget {
  const _PfBottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.p26;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(t.radiusLiquid),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: t.navFloater,
              borderRadius: BorderRadius.circular(t.radiusLiquid),
              border: Border.all(color: t.glassBorder.withValues(alpha: 0.4)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 64,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Ana Sayfa',
                      selected: currentIndex == 0,
                      onTap: () => onTap(0),
                    ),
                    _NavItem(
                      icon: Icons.mic_rounded,
                      label: 'Canlı',
                      selected: currentIndex == 1,
                      onTap: () => onTap(1),
                    ),
                    _NavItem(
                      icon: Icons.chat_bubble_rounded,
                      label: 'Sohbet',
                      selected: currentIndex == 2,
                      onTap: () => onTap(2),
                    ),
                    _NavItem(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Cüzdan',
                      selected: currentIndex == 3,
                      onTap: () => onTap(3),
                    ),
                    _NavItem(
                      icon: Icons.person_rounded,
                      label: 'Profil',
                      selected: currentIndex == 4,
                      onTap: () => onTap(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? PfTheme.gold : Colors.white54;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
