import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_design.dart';
import 'profile_glass.dart';

class ProfileSettingsMenu extends StatelessWidget {
  const ProfileSettingsMenu({
    super.key,
    this.onEditProfile,
    this.onSecurity,
    this.onNotifications,
    this.onHelp,
    this.onAbout,
  });

  final VoidCallback? onEditProfile;
  final VoidCallback? onSecurity;
  final VoidCallback? onNotifications;
  final VoidCallback? onHelp;
  final VoidCallback? onAbout;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.person_outline_rounded,
        label: 'Profili Düzenle',
        onTap: onEditProfile ?? () => context.push('/user/me'),
      ),
      (
        icon: Icons.shield_outlined,
        label: 'Hesap Güvenliği',
        onTap: onSecurity ?? () {},
      ),
      (
        icon: Icons.notifications_outlined,
        label: 'Bildirim Ayarları',
        onTap: onNotifications ?? () => context.push('/notifications'),
      ),
      (
        icon: Icons.help_outline_rounded,
        label: 'Yardım & Destek',
        onTap: onHelp ?? () {},
      ),
      (
        icon: Icons.info_outline_rounded,
        label: 'Hakkımızda',
        onTap: onAbout ?? () {},
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        ProfileGlass(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _SettingsTile(
                  icon: items[i].icon,
                  label: items[i].label,
                  onTap: items[i].onTap,
                ),
                if (i < items.length - 1)
                  Divider(
                    height: 1,
                    indent: 52,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppDesign.textSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppDesign.textMuted.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
