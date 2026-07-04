import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/widgets/theme_mode_selector.dart';
import '../../widgets/premium/profile_glass.dart';

/// Ayarlar — gruplu liste; tema, hesap, keşfet, destek.
class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({
    super.key,
    this.onLogout,
  });

  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProfileSectionTitle(title: 'Ayarlar'),
          const _Group(
            title: 'Görünüm',
            children: [
              ThemeModeSelector(),
            ],
            skipGlass: true,
          ),
          const SizedBox(height: 16),
          _Group(
            title: 'Hesap',
            children: [
              _SettingsRow(
                icon: Icons.person_outline_rounded,
                label: 'Profil Düzenle',
                onTap: () => context.push('/profile/edit'),
              ),
              Divider(height: 1, indent: 52, color: palette.divider),
              _SettingsRow(
                icon: Icons.shield_outlined,
                label: 'Hesap Güvenliği',
                onTap: () => context.push('/profile/security'),
              ),
              Divider(height: 1, indent: 52, color: palette.divider),
              _SettingsRow(
                icon: Icons.notifications_outlined,
                label: 'Bildirimler',
                onTap: () => context.push('/notifications'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Group(
            title: 'Keşfet',
            children: [
              _SettingsRow(
                icon: Icons.bookmark_outline_rounded,
                label: 'Favoriler',
                onTap: () => context.push('/favorites'),
              ),
              Divider(height: 1, indent: 52, color: palette.divider),
              _SettingsRow(
                icon: Icons.emoji_events_outlined,
                label: 'Görevler & Rozetler',
                onTap: () => context.push('/profile/growth'),
              ),
              Divider(height: 1, indent: 52, color: palette.divider),
              _SettingsRow(
                icon: Icons.menu_book_rounded,
                label: 'Blog',
                onTap: () => context.push('/blog-hub'),
              ),
              Divider(height: 1, indent: 52, color: palette.divider),
              _SettingsRow(
                icon: Icons.nights_stay_outlined,
                label: 'Rüyalarım',
                onTap: () => context.push('/dreams-hub'),
              ),
              Divider(height: 1, indent: 52, color: palette.divider),
              _SettingsRow(
                icon: Icons.search_rounded,
                label: 'Kullanıcı Ara',
                onTap: () => context.push('/search'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Group(
            title: 'Destek',
            children: [
              _SettingsRow(
                icon: Icons.help_outline_rounded,
                label: 'Yardım',
                onTap: () => context.push('/profile/help'),
              ),
              Divider(height: 1, indent: 52, color: palette.divider),
              _SettingsRow(
                icon: Icons.info_outline_rounded,
                label: 'Hakkımızda',
                onTap: () => context.push('/profile/about'),
              ),
              Divider(height: 1, indent: 52, color: palette.divider),
              _SettingsRow(
                icon: Icons.logout_rounded,
                label: 'Çıkış',
                onTap: onLogout ?? () {},
                danger: true,
              ),
            ],
          ),
        ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.children,
    this.skipGlass = false,
  });

  final String title;
  final List<Widget> children;
  final bool skipGlass;

  @override
  Widget build(BuildContext context) {
    final content = skipGlass
        ? Column(children: children)
        : ProfileGlass(
            padding: EdgeInsets.zero,
            child: Column(children: children),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: context.palette.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ),
        content,
      ],
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
