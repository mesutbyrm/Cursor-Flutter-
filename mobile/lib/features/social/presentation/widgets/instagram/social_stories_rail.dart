import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_design.dart';
import '../../../../../core/widgets/user_avatar.dart';
import '../../../../auth/domain/entities/user_entity.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../domain/entities/social_story_ring_entity.dart';
import '../../providers/social_providers.dart';

/// Instagram tarzı yatay hikâye şeridi (`/api/stories`).
class SocialStoriesRail extends ConsumerWidget {
  const SocialStoriesRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ringsAsync = ref.watch(socialStoryRingsProvider);
    final me = ref.watch(authControllerProvider).valueOrNull;

    return SizedBox(
      height: 108,
      child: ringsAsync.when(
        loading: () => const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, _) => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [_OwnStoryChip(user: me)],
        ),
        data: (rings) {
          final items = <Widget>[
            _OwnStoryChip(user: me),
            ...rings
                .where((r) => r.user.id != me?.id)
                .map((r) => _StoryRingChip(ring: r)),
          ];
          if (items.length == 1 && rings.isEmpty) {
            return ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: items,
            );
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, i) => items[i],
          );
        },
      ),
    );
  }
}

class _OwnStoryChip extends StatelessWidget {
  const _OwnStoryChip({this.user});

  final UserEntity? user;

  @override
  Widget build(BuildContext context) {
    return _StoryRingFrame(
      label: 'Hikâyen',
      isOwn: true,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hikâye ekleme yakında')),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          UserAvatar(url: user?.avatarUrl, radius: 30),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppDesign.accentCyan,
                shape: BoxShape.circle,
                border: Border.all(color: AppDesign.bgBase, width: 2),
              ),
              child: const Icon(Icons.add, size: 14, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryRingChip extends StatelessWidget {
  const _StoryRingChip({required this.ring});

  final SocialStoryRingEntity ring;

  @override
  Widget build(BuildContext context) {
    return _StoryRingFrame(
      label: ring.user.display,
      onTap: () => context.push('/user/${ring.user.id}'),
      child: _RingAvatar(
        avatarUrl: ring.user.avatarUrl,
        previewUrl: ring.previewUrl,
      ),
    );
  }
}

class _StoryRingFrame extends StatelessWidget {
  const _StoryRingFrame({
    required this.label,
    required this.child,
    this.onTap,
    this.isOwn = false,
  });

  final String label;
  final Widget child;
  final VoidCallback? onTap;
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isOwn
                    ? LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.35),
                          Colors.white.withValues(alpha: 0.15),
                        ],
                      )
                    : AppDesign.heroGradient,
              ),
              child: child,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppDesign.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingAvatar extends StatelessWidget {
  const _RingAvatar({this.avatarUrl, this.previewUrl});

  final String? avatarUrl;
  final String? previewUrl;

  @override
  Widget build(BuildContext context) {
    final url = (previewUrl != null && previewUrl!.isNotEmpty)
        ? previewUrl!
        : avatarUrl;

    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: 66,
          height: 66,
          fit: BoxFit.cover,
          placeholder: (_, _) => const _AvatarPlaceholder(),
          errorWidget: (_, _, _) => UserAvatar(url: avatarUrl, radius: 33),
        ),
      );
    }
    return UserAvatar(url: avatarUrl, radius: 33);
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E2E),
      child: const Center(
        child: Icon(Icons.person, color: AppDesign.textMuted),
      ),
    );
  }
}
