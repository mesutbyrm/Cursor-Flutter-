import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/lazy_list_views.dart';
import '../../../auth/presentation/auth_navigation.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/social_story_ring_entity.dart';
import '../providers/social_providers.dart';
import '../providers/story_seen_provider.dart';
import '../utils/story_navigation.dart';
import 'story_create_sheet.dart';
import 'story_ring_tile.dart';

/// Yatay hikâye şeridi — ana sayfa ve sosyal akışta ortak.
///
/// İlk öğe kullanıcının kendi halkası (hikâyesi yoksa "ekle"); diğerleri
/// izlenmemişler önde olacak şekilde sıralanır ve görüntüleyiciye tüm liste
/// verilir, böylece bir kişinin hikâyeleri bitince sıradakine geçilir.
class StoriesStrip extends ConsumerWidget {
  const StoriesStrip({
    super.key,
    this.ringSize = 68,
    this.horizontalPadding = 12,
    this.spacing = 8,
    this.ownLabel = 'Hikâyen',
  });

  final double ringSize;
  final double horizontalPadding;
  final double spacing;
  final String ownLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ringsAsync = ref.watch(socialStoryRingsProvider);
    final seen = ref.watch(storySeenProvider);
    final me = ref.watch(authControllerProvider).valueOrNull;
    final padding = EdgeInsets.symmetric(horizontal: horizontalPadding);

    return SizedBox(
      height: StoryRingTile.tileHeight(ringSize) + 8,
      child: ringsAsync.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        loading: () => StoryRingSkeletonRow(
          size: ringSize,
          padding: padding,
          spacing: spacing,
        ),
        error: (e, _) => _StoriesError(
          message: ApiException.userMessage(e),
          onRetry: () => ref.invalidate(socialStoryRingsProvider),
        ),
        data: (rings) {
          final own = rings.where((r) => r.isOwn).firstOrNull;
          final others = sortRingsUnseenFirst(
            rings.where((r) => !r.isOwn && _hasContent(r)).toList(),
            seen,
          );
          return LazyHorizontalListView(
            padding: padding.copyWith(top: 4),
            itemCount: 1 + others.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _OwnRing(
                  label: ownLabel,
                  avatarUrl: me?.avatarUrl,
                  ownRing: own,
                  seen: seen,
                  size: ringSize,
                );
              }
              final ring = others[index - 1];
              final state = isStoryRingSeen(ring, seen)
                  ? StoryRingState.seen
                  : StoryRingState.unseen;
              return Padding(
                padding: EdgeInsets.only(left: spacing),
                child: StoryRingTile(
                  size: ringSize,
                  label: ring.user.display,
                  avatarUrl: ring.user.avatarUrl,
                  state: state,
                  semanticsLabel: state == StoryRingState.unseen
                      ? '${ring.user.display} hikâyesi, yeni'
                      : '${ring.user.display} hikâyesi, izlendi',
                  onTap: () => openStoryViewer(context, ring, rings: others),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static bool _hasContent(SocialStoryRingEntity r) =>
      r.stories.isNotEmpty || (r.previewUrl?.trim().isNotEmpty ?? false);
}

class _OwnRing extends ConsumerWidget {
  const _OwnRing({
    required this.label,
    required this.avatarUrl,
    required this.ownRing,
    required this.seen,
    required this.size,
  });

  final String label;
  final String? avatarUrl;
  final SocialStoryRingEntity? ownRing;
  final Set<String> seen;
  final double size;

  Future<void> _addStory(BuildContext context, WidgetRef ref) async {
    final me = ref.read(authControllerProvider).valueOrNull;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hikâye eklemek için giriş yapın')),
      );
      AuthNavigation.toLogin(context);
      return;
    }
    await showStoryCreateSheet(context, ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ring = ownRing;
    final hasStories = ring != null && ring.stories.isNotEmpty;
    final state = !hasStories
        ? StoryRingState.none
        : isStoryRingSeen(ring, seen)
        ? StoryRingState.seen
        : StoryRingState.unseen;
    return StoryRingTile(
      size: size,
      label: label,
      avatarUrl: avatarUrl,
      state: state,
      showAddBadge: true,
      semanticsLabel: hasStories
          ? 'Hikâyeni görüntüle. Yeni eklemek için basılı tut.'
          : 'Hikâye ekle',
      onTap: hasStories
          ? () => openStoryViewer(context, ring.copyWith(isOwn: true))
          : () => _addStory(context, ref),
      onLongPress: hasStories ? () => _addStory(context, ref) : null,
    );
  }
}

class _StoriesError extends StatelessWidget {
  const _StoriesError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 18,
            color: context.colors.onSurfaceMuted,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.length > 60 ? 'Hikâyeler yüklenemedi' : message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.colors.onSurfaceMuted,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Tekrar dene')),
        ],
      ),
    );
  }
}
