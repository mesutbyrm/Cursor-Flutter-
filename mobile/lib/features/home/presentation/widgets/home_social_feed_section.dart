import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../social/presentation/widgets/instagram/social_instagram_post_card.dart';
import '../providers/home_providers.dart';
import '../theme/home_palette.dart';
import 'home_section_header.dart';

class HomeSocialFeedSection extends ConsumerStatefulWidget {
  const HomeSocialFeedSection({super.key});

  @override
  ConsumerState<HomeSocialFeedSection> createState() =>
      _HomeSocialFeedSectionState();
}

class _HomeSocialFeedSectionState extends ConsumerState<HomeSocialFeedSection> {
  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(homeFeedNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeader(
          title: 'Sosyal Akış',
          onTrailing: () => context.push('/social/create'),
          trailingLabel: 'Paylaşım Yap',
        ),
        feed.when(
          loading: () => const Column(
            children: [
              PremiumPostSkeleton(),
              PremiumPostSkeleton(),
            ],
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Akış yüklenemedi: $e'),
          ),
          data: (posts) {
            if (posts.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Henüz paylaşım yok. İlk paylaşımı sen yap!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final post in posts)
                  SocialInstagramPostCard(post: post),
                if (ref.read(homeFeedNotifierProvider.notifier).canLoadMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: OutlinedButton(
                      onPressed: () => ref
                          .read(homeFeedNotifierProvider.notifier)
                          .loadMore(),
                      child: const Text('Daha fazla yükle'),
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
