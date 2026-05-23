import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/canlifal_tokens.dart';
import '../../../../../core/ui/premium/premium_icon_button.dart';
import '../../utils/open_social_create_post.dart';

/// CanlıFal Sosyal üst çubuk — gradyan başlık, bildirim noktaları.
class SocialInstagramAppBar extends ConsumerWidget {
  const SocialInstagramAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.paddingOf(context).top;
    final tokens = context.tokens;

    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 8, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.98),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 22,
            color: AppColors.accentPurple.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (b) => tokens.brandGradient.createShader(b),
            child: Text(
              'CanlıFal Sosyal',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
            ),
          ),
          const Spacer(),
          PremiumIconButton(
            icon: Icons.add_box_outlined,
            size: 40,
            onTap: () => openSocialCreatePost(context, ref),
          ),
          const SizedBox(width: 4),
          _NotifyIconButton(
            icon: Icons.favorite_border_rounded,
            showDot: true,
            onTap: () => context.push('/notifications'),
          ),
          const SizedBox(width: 4),
          _NotifyIconButton(
            icon: Icons.send_outlined,
            showDot: true,
            onTap: () => context.push('/messages'),
          ),
        ],
      ),
    );
  }
}

class _NotifyIconButton extends StatelessWidget {
  const _NotifyIconButton({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PremiumIconButton(icon: icon, size: 40, onTap: onTap),
        if (showDot)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.accentPink,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 1.5),
                boxShadow: AppColors.glowShadow(
                  AppColors.accentPink,
                  blur: 8,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
