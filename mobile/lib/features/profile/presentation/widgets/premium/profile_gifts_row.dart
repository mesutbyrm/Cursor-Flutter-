import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

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
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ),
        gifts.when(
          loading: () => const SizedBox(
            height: 118,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, _) => const _EmptyGiftsHint(),
          data: (items) {
            if (items.isEmpty) return const _EmptyGiftsHint();
            return SizedBox(
              height: 118,
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
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppThemeColors.accentPink.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: AppThemeColors.accentPink,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Yayınlarda aldığın hediyeler burada görünür.',
              style: ProfileTypography.cardSubtitle(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftTile extends StatelessWidget {
  const _GiftTile({required this.gift});

  final GiftReceivedSummaryEntity gift;

  @override
  Widget build(BuildContext context) {
    final isUrl = gift.icon.startsWith('http');
    return SizedBox(
      width: 88,
      child: ProfileGlass(
        padding: const EdgeInsets.all(12),
        borderRadius: 20,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppThemeColors.accentPink.withValues(alpha: 0.75),
                        AppThemeColors.accentPurple.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                  child: isUrl
                      ? ClipOval(
                          child: CanlifalNetworkImage(
                            url: gift.icon,
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                            errorWidget: const Text(
                              '🎁',
                              style: TextStyle(fontSize: 26),
                            ),
                          ),
                        )
                      : Text(
                          gift.icon.isNotEmpty ? gift.icon : '🎁',
                          style: const TextStyle(fontSize: 28),
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  'x${gift.count}',
                  style: ProfileTypography.statLabel(context),
                ),
              ],
            ),
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  gradient: context.colors.brandGradient,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.scaffoldBg, width: 1.5),
                ),
                child: Text(
                  '${gift.count}',
                  style: const TextStyle(
                    fontSize: 11,
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
