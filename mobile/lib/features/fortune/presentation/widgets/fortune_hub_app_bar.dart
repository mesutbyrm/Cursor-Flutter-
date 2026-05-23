import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/premium/premium_icon_button.dart';
import '../../../messages/presentation/providers/messages_providers.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';

/// Fal & Tarot sekmesi üst çubuk — menü, başlık, mesajlar, bildirimler.
class FortuneHubAppBar extends ConsumerWidget {
  const FortuneHubAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.paddingOf(context).top;
    final messagesUnread = ref.watch(messagesUnreadCountProvider);
    final notificationsUnread = ref.watch(notificationsUnreadCountProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(8, top + 4, 12, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
            onPressed: () => _openMenu(context),
          ),
          const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFE9C46A)),
          const SizedBox(width: 6),
          Expanded(
            child: ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFF5E6C8), Color(0xFFD4A853), Color(0xFFE9C46A)],
              ).createShader(b),
              child: const Text(
                'Fal & Tarot',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: Colors.white,
                  fontFamily: 'serif',
                ),
              ),
            ),
          ),
          const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFE9C46A)),
          PremiumIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            size: 40,
            showBadge: messagesUnread > 0,
            badgeCount: messagesUnread,
            onTap: () => context.push('/messages'),
          ),
          const SizedBox(width: 4),
          PremiumIconButton(
            icon: Icons.notifications_none_rounded,
            size: 40,
            showBadge: notificationsUnread > 0,
            badgeCount: notificationsUnread,
            onTap: () => context.push('/notifications'),
          ),
        ],
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
