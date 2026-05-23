import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/canlifal_tokens.dart';
import '../../../../../core/widgets/user_avatar.dart';
import '../../../../auth/domain/entities/user_entity.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../domain/entities/social_story_ring_entity.dart';
import '../../providers/social_providers.dart';

/// Yatay hikâye şeridi — «Hikayen», mistik dekor, diğer halkalar.
class SocialStoriesRail extends ConsumerWidget {
  const SocialStoriesRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ringsAsync = ref.watch(socialStoryRingsProvider);
    final me = ref.watch(authControllerProvider).valueOrNull;

    return SizedBox(
      height: 112,
      child: ringsAsync.when(
        loading: () => const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, _) => _StoriesList(
          me: me,
          rings: const [],
        ),
        data: (rings) => _StoriesList(me: me, rings: rings),
      ),
    );
  }
}

class _StoriesList extends StatelessWidget {
  const _StoriesList({required this.me, required this.rings});

  final UserEntity? me;
  final List<SocialStoryRingEntity> rings;

  @override
  Widget build(BuildContext context) {
    final others = rings.where((r) => r.user.id != me?.id).toList();

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        _OwnStoryChip(user: me),
        const SizedBox(width: 14),
        const _MysticStoryDeco(),
        ...others.map(
          (r) => Padding(
            padding: const EdgeInsets.only(left: 14),
            child: _StoryRingChip(ring: r),
          ),
        ),
      ],
    );
  }
}

class _MysticStoryDeco extends StatelessWidget {
  const _MysticStoryDeco();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SizedBox(
      width: 88,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.bgPurpleGlow,
                  tokens.brandGradient.colors.last.withValues(alpha: 0.5),
                ],
              ),
              border: Border.all(
                color: AppColors.accentPurple.withValues(alpha: 0.45),
              ),
              boxShadow: AppColors.glowShadow(
                AppColors.accentPurple,
                blur: 16,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🔮', style: TextStyle(fontSize: 26)),
                SizedBox(height: 2),
                Text('🃏', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Fal hikâyeleri',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
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
      label: 'Hikayen',
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
                gradient: AppColors.fabGradient,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2),
                boxShadow: AppColors.glowShadow(AppColors.accentPink, blur: 10),
              ),
              child: const Icon(Icons.add, size: 14, color: Colors.white),
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
                    ? const LinearGradient(
                        colors: [
                          Color(0xFFB832FF),
                          Color(0xFFFE2C55),
                        ],
                      )
                    : AppColors.brandGradient,
                boxShadow: isOwn
                    ? AppColors.glowShadow(AppColors.accentPurple, blur: 14)
                    : null,
              ),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                ),
                child: child,
              ),
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
                color: AppColors.textPrimary,
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
        child: Icon(Icons.person, color: AppColors.textMuted),
      ),
    );
  }
}
