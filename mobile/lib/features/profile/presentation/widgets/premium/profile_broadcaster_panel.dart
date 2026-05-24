import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
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
      (icon: Icons.mic_external_on_rounded, label: 'Ekipmanım', onTap: onEquipment),
      (icon: Icons.tune_rounded, label: 'Yayın Ayarları', onTap: onSettings),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle(title: 'Yayıncı Paneli'),
        Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _BroadcasterTile(
                  icon: items[i].icon,
                  label: items[i].label,
                  onTap: items[i].onTap,
                ),
              ),
            ],
          ],
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      borderRadius: 16,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.accentPurple.withValues(alpha: 0.2),
            ),
            child: Icon(
              icon,
              size: 22,
              color: AppColors.accentPurple.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
