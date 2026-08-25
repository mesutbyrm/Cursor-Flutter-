import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/ui/premium/premium_skeleton.dart';
import '../providers/profile_providers.dart';
import '../widgets/premium/profile_glass.dart';
import '../premium_2026/profile_theme.dart';
import 'profile_hub_error_banner.dart';

/// En çok gönderilen hediyeler.
class ProfileHubTopGiftsSection extends ConsumerWidget {
  const ProfileHubTopGiftsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(giftsReceivedSummaryProvider);

    return async.when(
      loading: () => const PremiumSkeleton(
        height: 140,
        width: double.infinity,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      error: (_, _) => ProfileHubSectionRetry(
        message: 'Hediyeler yüklenemedi',
        onRetry: () => ref.invalidate(giftsReceivedSummaryProvider),
      ),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final top = items.take(5).toList();

        return ProfileGlass(
          padding: const EdgeInsets.all(16),
          borderRadius: ProfilePremiumTheme.radiusMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'En Çok Gönderilen Hediyeler',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/profile/gifts'),
                    child: const Text('Tümü >'),
                  ),
                ],
              ),
              for (final gift in top)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      _GiftIcon(icon: gift.icon),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gift.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            if (gift.coins > 0)
                              Text(
                                '${profileFormatCount(gift.coins)} jeton',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '×${profileFormatCount(gift.count)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GiftIcon extends StatelessWidget {
  const _GiftIcon({required this.icon});

  final String icon;

  @override
  Widget build(BuildContext context) {
    final isUrl = icon.startsWith('http');
  final isEmoji = !isUrl && icon.length <= 4;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.08),
      ),
      alignment: Alignment.center,
      child: isUrl
          ? ClipOval(
              child: CanlifalNetworkImage(
                url: icon,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            )
          : Text(isEmoji ? icon : '🎁', style: const TextStyle(fontSize: 18)),
    );
  }
}
