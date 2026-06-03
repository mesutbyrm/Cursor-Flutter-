import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/profile_stats_entity.dart';
import '../../providers/profile_providers.dart';
import 'profile_glass.dart';

class ProfileGiftsRow extends ConsumerWidget {
  const ProfileGiftsRow({super.key, this.onViewAll});

  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gifts = ref.watch(giftsReceivedSummaryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionTitle(
          title: 'Hediyelerim',
          trailing: TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              foregroundColor: AppThemeColors.accentCyan,
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
        gifts.when(
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, _) => const _EmptyGiftsHint(),
          data: (items) {
            if (items.isEmpty) return const _EmptyGiftsHint();
            return SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length.clamp(0, 8),
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) => _GiftTile(gift: items[i]),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _EmptyGiftsHint extends StatelessWidget {
  const _EmptyGiftsHint();

  @override
  Widget build(BuildContext context) {
    return ProfileGlass(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Yayınlarda aldığın hediyeler burada görünür.',
        style: TextStyle(
          fontSize: 13,
          color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _GiftTile extends StatelessWidget {
  const _GiftTile({required this.gift});

  final GiftReceivedSummaryEntity gift;

  @override
  Widget build(BuildContext context) {
    final display = gift.icon.startsWith('http') ? '🎁' : gift.icon;
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
                      colors: [
                        AppThemeColors.accentPink.withValues(alpha: 0.8),
                        AppThemeColors.accentPurple.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: Text(display, style: const TextStyle(fontSize: 26)),
                ),
              ],
            ),
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: context.colors.brandGradient,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.scaffoldBg, width: 1.5),
                ),
                child: Text(
                  'x${gift.count}',
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
