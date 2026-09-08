import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../domain/admin_site_animation.dart';

class AdminSiteAnimationStatsGrid extends StatelessWidget {
  const AdminSiteAnimationStatsGrid({super.key, required this.stats});

  final AdminSiteAnimationStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _Stat('Toplam', stats.total, Icons.animation_rounded),
      _Stat('Aktif', stats.active, Icons.check_circle_outline_rounded),
      _Stat('Pasif', stats.inactive, Icons.pause_circle_outline_rounded),
      _Stat('Giriş', stats.entrance, Icons.login_rounded),
      _Stat('Çıkış', stats.exit, Icons.logout_rounded),
      _Stat('Koltuk', stats.seat, Icons.event_seat_rounded),
      _Stat('VIP', stats.vip, Icons.workspace_premium_outlined),
      _Stat('Profil Çerçevesi', stats.profileFrame, Icons.crop_portrait_rounded),
      _Stat('Hediye', stats.gift, Icons.card_giftcard_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const cross = 3;
        const spacing = 8.0;
        const aspect = 1.45;
        final cellW = (constraints.maxWidth - spacing * (cross - 1)) / cross;
        final cellH = cellW / aspect;
        final rows = (items.length / cross).ceil();
        return SizedBox(
          height: rows * cellH + (rows - 1) * spacing,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cross,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: aspect,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => _StatTile(stat: items[i]),
          ),
        );
      },
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.icon);
  final String label;
  final int value;
  final IconData icon;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});
  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: AppThemeColors.accentPurple.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(stat.icon, size: 18, color: AppThemeColors.accentCyan),
          const Spacer(),
          Text(
            '${stat.value}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          Text(
            stat.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
