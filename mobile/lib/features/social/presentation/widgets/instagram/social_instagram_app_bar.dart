import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/canlifal_brand_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/ui/premium/premium_icon_button.dart';
import '../../../../../core/widgets/messages_notifications_actions.dart';
import '../../utils/open_social_create_post.dart';

/// CanlıFal Sosyal üst çubuk — paylaşım + mesajlar + bildirimler.
class SocialInstagramAppBar extends ConsumerWidget {
  const SocialInstagramAppBar({
    super.key,
    this.onPostPublished,
    this.onTitleTap,
  });

  /// Tam ekran paylaşım başarılı olunca (ör. akışı üste kaydır).
  final VoidCallback? onPostPublished;

  /// Başlığa dokununca (ör. akışın başına dön).
  final VoidCallback? onTitleTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.paddingOf(context).top;
    final dark = context.isDarkTheme;

    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 6, 8, 8),
      decoration: BoxDecoration(
        color: context.scaffoldBg.withValues(alpha: 0.98),
        border: Border(
          bottom: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.06)
                : context.colors.divider,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              button: onTitleTap != null,
              label: 'CanlıFal Sosyal',
              onTap: onTitleTap,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onTitleTap,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (b) =>
                          CanlifalBrandColors.accentGradient.createShader(b),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'CanlıFal Sosyal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          fontSize: 19,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          PremiumIconButton(
            icon: Icons.search_rounded,
            size: 38,
            tooltip: 'Ara',
            onTap: () => context.push('/search'),
          ),
          const SizedBox(width: 4),
          PremiumIconButton(
            icon: Icons.play_circle_outline_rounded,
            size: 38,
            tooltip: 'Kısa videolar',
            onTap: () => context.push('/shorts'),
          ),
          const SizedBox(width: 4),
          PremiumIconButton(
            icon: Icons.add_box_outlined,
            size: 38,
            tooltip: 'Gönderi oluştur',
            onTap: () => openSocialCreatePost(
              context,
              ref,
              onPublished: onPostPublished,
            ),
          ),
          const MessagesNotificationsActions(spacing: 2),
        ],
      ),
    );
  }
}
