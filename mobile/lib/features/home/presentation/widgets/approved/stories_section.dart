import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/widgets/user_avatar.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../auth/domain/entities/user_entity.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../social/domain/entities/social_story_ring_entity.dart';
import '../../../../social/presentation/pages/story_viewer_page.dart';
import '../../../../social/presentation/providers/social_providers.dart';
import '../../theme/home_approved_design.dart';

/// Onaylı mockup — yatay hikâye halkaları.
class StoriesSection extends ConsumerWidget {
  const StoriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ringsAsync = ref.watch(socialStoryRingsProvider);
    final me = ref.watch(authControllerProvider).valueOrNull;

    return SizedBox(
      height: HomeApprovedDesign.storySize + 36,
      child: ringsAsync.when(
        loading: () => const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (rings) {
          final others = rings.where((r) => r.user.id != me?.id).toList();
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
            children: [
              _OwnStoryChip(user: me),
              ...others.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _StoryChip(ring: r),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OwnStoryChip extends ConsumerWidget {
  const _OwnStoryChip({this.user});

  final UserEntity? user;

  Future<void> _addStory(BuildContext context, WidgetRef ref) async {
    final me = ref.read(authControllerProvider).valueOrNull;
    if (me == null) {
      if (context.mounted) context.push('/login');
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !context.mounted) return;
    try {
      await ref.read(socialRepositoryProvider).createStoryImage(picked.path);
      ref.invalidate(socialStoryRingsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _addStory(context, ref),
      child: SizedBox(
        width: HomeApprovedDesign.storySize + 4,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: HomeApprovedDesign.storySize + 4,
                  height: HomeApprovedDesign.storySize + 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: HomeApprovedDesign.border, width: 2),
                  ),
                  child: UserAvatar(url: user?.avatarUrl, radius: 32),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: HomeApprovedDesign.purple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Senin Hikayen',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: HomeApprovedDesign.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryChip extends StatelessWidget {
  const _StoryChip({required this.ring});

  final SocialStoryRingEntity ring;

  @override
  Widget build(BuildContext context) {
    final name = ring.user.displayName?.trim().isNotEmpty == true
        ? ring.user.displayName!.trim()
        : ring.user.username;
    return GestureDetector(
      onTap: () {
        if (ring.previewUrl != null && ring.previewUrl!.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => StoryViewerPage(ring: ring),
            ),
          );
        } else {
          context.push('/user/${ring.user.id}');
        }
      },
      child: SizedBox(
        width: HomeApprovedDesign.storySize + 4,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: HomeApprovedDesign.storySize + 4,
                  height: HomeApprovedDesign.storySize + 4,
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: HomeApprovedDesign.storyRingGradient,
                  ),
                  child: ClipOval(
                    child: ring.user.avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: ring.user.avatarUrl!,
                            fit: BoxFit.cover,
                            width: HomeApprovedDesign.storySize,
                            height: HomeApprovedDesign.storySize,
                          )
                        : UserAvatar(url: null, radius: 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: HomeApprovedDesign.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
