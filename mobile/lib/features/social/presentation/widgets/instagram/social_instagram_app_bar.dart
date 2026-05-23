import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/canlifal_tokens.dart';
import '../../../../../core/ui/premium/premium_icon_button.dart';
import '../../../../../core/widgets/messages_notifications_actions.dart';
import '../../utils/open_social_create_post.dart';

/// CanlıFal Sosyal üst çubuk — paylaşım + mesajlar + bildirimler.
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
          const MessagesNotificationsActions(spacing: 4),
        ],
      ),
    );
  }
}
