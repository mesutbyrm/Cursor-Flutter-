import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/widgets/theme_mode_selector.dart';
import '../../widgets/premium/profile_glass.dart';

/// Ayarlar listesi — tema, güvenlik, çıkış.
class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({
    super.key,
    this.onLogout,
  });

  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final items = <({IconData icon, String label, VoidCallback onTap, bool danger})>[
      (
        icon: Icons.person_outline_rounded,
        label: 'Profil Düzenle',
        onTap: () => context.push('/profile/edit'),
        danger: false,
      ),
      (
        icon: Icons.shield_outlined,
        label: 'Hesap Güvenliği',
        onTap: () => context.push('/settings'),
        danger: false,
      ),
      (
        icon: Icons.notifications_outlined,
        label: 'Bildirimler',
        onTap: () => context.push('/notifications'),
        danger: false,
      ),
      (
        icon: Icons.lock_outline_rounded,
        label: 'Gizlilik',
        onTap: () => context.push('/settings'),
        danger: false,
      ),
      (
        icon: Icons.bookmark_outline_rounded,
        label: 'Favoriler',
        onTap: () => context.push('/favorites'),
        danger: false,
      ),
      (
        icon: Icons.emoji_events_outlined,
        label: 'Görevler',
        onTap: () => context.push('/profile/growth'),
        danger: false,
      ),
      (
        icon: Icons.military_tech_outlined,
        label: 'Rozetler',
        onTap: () => context.push('/profile/growth'),
        danger: false,
      ),
      (
        icon: Icons.menu_book_rounded,
        label: 'Blog',
        onTap: () => context.push('/blog-hub'),
        danger: false,
      ),
      (
        icon: Icons.nights_stay_outlined,
        label: 'Rüyalarım',
        onTap: () => context.push('/dreams-hub'),
        danger: false,
      ),
      (
        icon: Icons.search_rounded,
        label: 'Kullanıcı Ara',
        onTap: () => context.push('/search'),
        danger: false,
      ),
      (
        icon: Icons.help_outline_rounded,
        label: 'Yardım',
        onTap: () => context.push('/profile/help'),
        danger: false,
      ),
      (
        icon: Icons.info_outline_rounded,
        label: 'Hakkımızda',
        onTap: () => context.push('/profile/about'),
        danger: false,
      ),
      (
        icon: Icons.logout_rounded,
        label: 'Çıkış',
        onTap: onLogout ?? () {},
        danger: true,
      ),
    ];

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProfileSectionTitle(title: 'Ayarlar'),
          const ThemeModeSelector(),
          const SizedBox(height: 12),
          ProfileGlass(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  _SettingsRow(
                    icon: items[i].icon,
                    label: items[i].label,
                    onTap: items[i].onTap,
                    danger: items[i].danger,
                  ),
                  if (i < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 52,
                      color: palette.divider,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = danger ? const Color(0xFFFF6B6B) : palette.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: danger ? const Color(0xFFFF6B6B) : palette.textSecondary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: color,
                    height: 1.2,
                  ),
                ),
              ),
              if (!danger)
                Icon(Icons.chevron_right_rounded, color: palette.iconMuted),
            ],
          ),
        ),
      ),
    );
  }
}
