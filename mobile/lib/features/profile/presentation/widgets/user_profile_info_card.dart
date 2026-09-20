import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../providers/profile_providers.dart';
import 'premium/profile_glass.dart';

/// Ziyaret edilen profil için zengin "Bilgiler" kartı — şehir, burç, favori
/// takım, katılma tarihi, günlük seri, çevrimiçi durumu. `userProfileExtended`
/// verisinden beslenir; hiç bilgi yoksa görünmez.
class UserProfileInfoCard extends ConsumerWidget {
  const UserProfileInfoCard({super.key, required this.userId});

  final String userId;

  static const _monthsTr = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = ref.watch(userProfileExtendedProvider(userId)).valueOrNull;
    if (ext == null) return const SizedBox.shrink();

    final chips = <Widget>[];
    void add(IconData icon, String? value) {
      final v = value?.trim() ?? '';
      if (v.isEmpty) return;
      chips.add(_InfoChip(icon: icon, label: v));
    }

    if (ext.isOnline) {
      chips.add(const _InfoChip(
        icon: Icons.circle,
        label: 'Çevrimiçi',
        accent: Color(0xFF4ADE80),
      ));
    }
    add(Icons.location_city_rounded, ext.city);
    add(Icons.auto_awesome_rounded, ext.zodiacSign);
    add(Icons.sports_soccer_rounded, ext.favoriteTeam);
    if ((ext.vipLevel?.trim().isNotEmpty ?? false)) {
      chips.add(_InfoChip(
        icon: Icons.workspace_premium_rounded,
        label: ext.vipLevel!.trim(),
        accent: const Color(0xFFFFD54F),
      ));
    }
    if (ext.dailyStreak > 0) {
      add(Icons.local_fire_department_rounded, '${ext.dailyStreak} gün seri');
    }
    final joined = ext.joinedAt;
    if (joined != null) {
      add(
        Icons.calendar_today_rounded,
        'Katıldı: ${_monthsTr[(joined.month - 1).clamp(0, 11)]} ${joined.year}',
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: ProfileGlass(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.badge_rounded,
                  size: 18,
                  color: AppThemeColors.accentPink,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bilgiler',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.accent,
  });

  final IconData icon;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Colors.white.withValues(alpha: 0.85);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
