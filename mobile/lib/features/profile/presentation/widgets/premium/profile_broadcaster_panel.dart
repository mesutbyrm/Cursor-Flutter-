import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

import 'profile_glass.dart';

class ProfileBroadcasterPanel extends StatelessWidget {
  const ProfileBroadcasterPanel({
    super.key,
    this.onHistory,
    this.onSchedule,
    this.onStats,
    this.onEquipment,
    this.onSettings,
  });

  final VoidCallback? onHistory;
  final VoidCallback? onSchedule;
  final VoidCallback? onStats;
  final VoidCallback? onEquipment;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final items = [
      (icon: Icons.history_rounded, label: 'Yayın Geçmişi', onTap: onHistory),
      (icon: Icons.event_rounded, label: 'Yayın Planla', onTap: onSchedule),
      (icon: Icons.insights_rounded, label: 'İstatistikler', onTap: onStats),
      (
        icon: Icons.mic_external_on_rounded,
        label: 'Ekipmanım',
        onTap: onEquipment,
      ),
      (icon: Icons.tune_rounded, label: 'Yayın Ayarları', onTap: onSettings),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle(title: 'Yayıncı Paneli'),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            const cols = 3;
            final tileW = (constraints.maxWidth - spacing * (cols - 1)) / cols;
            final tileH = tileW / 0.92;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final item in items)
                  SizedBox(
                    width: tileW,
                    height: tileH,
                    child: _BroadcasterTile(
                      icon: item.icon,
                      label: item.label,
                      onTap: item.onTap,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BroadcasterTile extends StatelessWidget {
  const _BroadcasterTile({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ProfileGlass(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      borderRadius: 18,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppThemeColors.accentPurple.withValues(alpha: 0.28),
                  AppThemeColors.accentPink.withValues(alpha: 0.18),
                ],
              ),
            ),
            child: Icon(
              icon,
              size: 24,
              color: AppThemeColors.accentCyan.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ProfileTypography.actionLabel(context),
          ),
        ],
      ),
    );
  }
}
