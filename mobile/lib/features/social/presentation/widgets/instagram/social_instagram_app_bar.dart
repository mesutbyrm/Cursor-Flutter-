import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/canlifal_tokens.dart';
import '../../../../../core/ui/premium/premium_icon_button.dart';
import '../../utils/open_social_create_post.dart';

/// Instagram tarzı üst çubuk — gradyan logo, cam aksiyonlar.
class SocialInstagramAppBar extends StatelessWidget {
  const SocialInstagramAppBar({super.key});

  @override
  Widget build(BuildContext context) {
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
          ShaderMask(
            shaderCallback: (b) => tokens.brandGradient.createShader(b),
            child: Text(
              'Canlifal',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
          const Spacer(),
          PremiumIconButton(
            icon: Icons.add_box_outlined,
            size: 40,
            onTap: () => openSocialCreatePost(context),
          ),
          const SizedBox(width: 4),
          PremiumIconButton(
            icon: Icons.favorite_border_rounded,
            size: 40,
            onTap: () => context.push('/notifications'),
          ),
          const SizedBox(width: 4),
          PremiumIconButton(
            icon: Icons.send_outlined,
            size: 40,
            onTap: () => context.go('/messages'),
          ),
        ],
      ),
    );
  }
}
