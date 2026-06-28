import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/bootstrap/startup_perf.dart';
import '../../../../messages/presentation/providers/messages_providers.dart';
import '../../../../notifications/presentation/providers/notifications_providers.dart';
import 'ultra_fortune_liquid_surface.dart';
import 'ultra_fortune_tokens.dart';

/// Ultra premium header — Liquid Glass butonlar, altın başlık.
class UltraFortuneAppBar extends StatelessWidget {
  const UltraFortuneAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    final titleStyle = GoogleFonts.playfairDisplay(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      height: 1.15,
      color: Colors.white,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(8, top + 4, 12, 8),
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.menu_rounded,
            onTap: () => _openMenu(context),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 6),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          UltraFortuneTokens.goldTypography.createShader(bounds),
                      child: Text('Fal & Tarot', style: titleStyle),
                    ),
                    const SizedBox(width: 6),
                    const Text('✨', style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'MİSTİK • KEŞFET • AYDINLAN',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: UltraFortuneTokens.softLilac.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const _FortuneAppBarBadgesGate(),
        ],
      ),
    );
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: UltraFortuneTokens.deepNight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home_rounded, color: Colors.white70),
              title: const Text('Ana Sayfa', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/feed');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded, color: Colors.white70),
              title: const Text('Profil', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/profile');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FortuneAppBarBadgesGate extends StatefulWidget {
  const _FortuneAppBarBadgesGate();

  @override
  State<_FortuneAppBarBadgesGate> createState() => _FortuneAppBarBadgesGateState();
}

class _FortuneAppBarBadgesGateState extends State<_FortuneAppBarBadgesGate> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(LazyLoadPerf.fortuneBadges, () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GlassIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () => context.push('/messages'),
          ),
          const SizedBox(width: 8),
          _GlassIconButton(
            icon: Icons.notifications_none_rounded,
            onTap: () => context.push('/notifications'),
          ),
        ],
      );
    }
    return const _FortuneAppBarBadges();
  }
}

class _FortuneAppBarBadges extends ConsumerWidget {
  const _FortuneAppBarBadges();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadMessages = ref.watch(messagesUnreadCountProvider);
    final unreadNotifications = ref.watch(notificationsUnreadCountProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GlassIconButton(
          icon: Icons.chat_bubble_outline_rounded,
          badgeCount: unreadMessages,
          onTap: () => context.push('/messages'),
        ),
        const SizedBox(width: 8),
        _GlassIconButton(
          icon: Icons.notifications_none_rounded,
          badgeCount: unreadNotifications,
          onTap: () => context.push('/notifications'),
        ),
      ],
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return UltraFortuneLiquidSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(10),
      blur: 36,
      child: SizedBox(
        width: 22,
        height: 22,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.92)),
            if (badgeCount > 0)
              Positioned(
                top: -6,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B5C),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: UltraFortuneTokens.deepNight),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
