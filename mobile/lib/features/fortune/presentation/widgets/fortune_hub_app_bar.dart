import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../messages/presentation/providers/messages_providers.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import 'fortune_hub_action_button.dart';
import 'fortune_hub_gold_stars.dart';

/// Fal & Tarot sekmesi üst çubuk — mockup: menü, altın başlık, mesaj/bildirim.
class FortuneHubAppBar extends ConsumerWidget {
  const FortuneHubAppBar({super.key});

  static const _goldLight = Color(0xFFF5E6C8);
  static const _goldMid = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.paddingOf(context).top;
    final unreadMessages = ref.watch(messagesUnreadCountProvider);
    final unreadNotifications = ref.watch(notificationsUnreadCountProvider);

    final titleStyle = GoogleFonts.playfairDisplay(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      height: 1.1,
      color: Colors.white,
    );

    return Container(
      color: const Color(0xFF0A0118),
      child: Padding(
        padding: EdgeInsets.fromLTRB(4, top + 6, 12, 10),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
              onPressed: () => _openMenu(context),
            ),
            const FortuneHubGoldStars(size: 11),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 12, color: _goldMid),
                  const SizedBox(width: 6),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [_goldLight, _goldMid, Color(0xFFE9C46A)],
                    ).createShader(bounds),
                    child: Text('Fal & Tarot', style: titleStyle),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.auto_awesome, size: 12, color: _goldMid),
                ],
              ),
            ),
            FortuneHubActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              badgeCount: unreadMessages,
              onTap: () => context.push('/messages'),
            ),
            const SizedBox(width: 8),
            FortuneHubActionButton(
              icon: Icons.notifications_none_rounded,
              badgeCount: unreadNotifications,
              onTap: () => context.push('/notifications'),
            ),
          ],
        ),
      ),
    );
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A0B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home_rounded),
              title: const Text('Ana Sayfa'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/feed');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('Profil'),
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
