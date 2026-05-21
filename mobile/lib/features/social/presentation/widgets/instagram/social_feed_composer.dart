import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/user_avatar.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../utils/open_social_create_post.dart';

/// Facebook tarzı «Ne düşünüyorsun?» paylaşım şeridi — hikâyelerin altında.
class SocialFeedComposer extends ConsumerWidget {
  const SocialFeedComposer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF16162A).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => openSocialCreatePost(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Row(
                    children: [
                      UserAvatar(url: me?.avatarUrl, radius: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ne düşünüyorsun, ${me?.display ?? 'dostum'}?',
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.95),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.06),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ComposerAction(
                    icon: Icons.photo_library_rounded,
                    label: 'Fotoğraf',
                    color: const Color(0xFF45BD62),
                    onTap: () => openSocialCreatePost(context),
                  ),
                  _ComposerAction(
                    icon: Icons.videocam_rounded,
                    label: 'Video',
                    color: const Color(0xFFE85D4A),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Video paylaşımı yakında'),
                        ),
                      );
                    },
                  ),
                  _ComposerAction(
                    icon: Icons.emoji_emotions_outlined,
                    label: 'Duygu',
                    color: const Color(0xFFF7B928),
                    onTap: () => openSocialCreatePost(
                      context,
                      initialCaption: '😊 ',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerAction extends StatelessWidget {
  const _ComposerAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
