import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../theme/home_palette.dart';

/// canlifal.com üst çubuk — profil + hızlı eylemler.
class HomeSiteTopBar extends ConsumerWidget {
  const HomeSiteTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final unread = ref.watch(notificationsUnreadCountProvider);
    final top = MediaQuery.paddingOf(context).top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, top + 6, 12, 10),
          decoration: BoxDecoration(
            color: HomePalette.darkBackground.withValues(alpha: 0.75),
            border: Border(
              bottom: BorderSide(
                color: context.colors.outline.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B2FF7), Color(0xFFFF4FD8)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B2FF7).withValues(alpha: 0.45),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: UserAvatar(url: user?.avatarUrl, radius: 22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  (user?.display ?? 'CanlıFal').toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
              _TopAction(
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                onTap: () => context.go('/profile'),
              ),
              _TopAction(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Mesaj',
                onTap: () => context.push('/messages'),
              ),
              _TopAction(
                icon: Icons.notifications_none_rounded,
                label: 'Bildirim',
                badge: unread > 0 ? unread : null,
                onTap: () => context.push('/notifications'),
              ),
              _TopAction(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Admin',
                onTap: () => context.push('/admin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopAction extends StatelessWidget {
  const _TopAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 52,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 22, color: Colors.white.withValues(alpha: 0.92)),
                  if (badge != null)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4FD8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge! > 9 ? '9+' : '$badge',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
