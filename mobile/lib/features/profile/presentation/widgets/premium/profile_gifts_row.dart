import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'profile_glass.dart';

class ProfileGiftsRow extends StatelessWidget {
  const ProfileGiftsRow({super.key, this.onViewAll});

  final VoidCallback? onViewAll;

  static const _gifts = [
    (emoji: '🌹', label: 'Gül', count: 12, colors: [Color(0xFFFF6B9D), Color(0xFFC9184A)]),
    (emoji: '💖', label: 'Kalp', count: 23, colors: [Color(0xFFFF5E9A), Color(0xFFFF2D9A)]),
    (emoji: '⭐', label: 'Yıldız', count: 8, colors: [Color(0xFFFFD54F), Color(0xFFFF9800)]),
    (emoji: '🧸', label: 'Ayıcık', count: 5, colors: [Color(0xFFD4A574), Color(0xFF8B5A2B)]),
    (emoji: '👑', label: 'Taç', count: 3, colors: [Color(0xFFFFD54F), Color(0xFFB8860B)]),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionTitle(
          title: 'Hediyelerim',
          trailing: TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accentCyan,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Tümünü Gör',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _gifts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) {
              final g = _gifts[i];
              return _GiftTile(
                emoji: g.emoji,
                count: g.count,
                colors: g.colors,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GiftTile extends StatelessWidget {
  const _GiftTile({
    required this.emoji,
    required this.count,
    required this.colors,
  });

  final String emoji;
  final int count;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: ProfileGlass(
        padding: const EdgeInsets.all(10),
        borderRadius: 18,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.first.withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
              ],
            ),
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.background, width: 1.5),
                ),
                child: Text(
                  'x$count',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
