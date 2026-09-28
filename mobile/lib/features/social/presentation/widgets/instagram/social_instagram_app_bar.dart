import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/canlifal_brand_colors.dart';

import '../../../../inbox/domain/inbox_tab.dart';
import '../../../../inbox/presentation/inbox_routes.dart';
import '../../../../inbox/presentation/providers/inbox_unread_providers.dart';

/// CanlıFal Sosyal üst çubuk — logo + bildirim + mesajlar.
class SocialInstagramAppBar extends ConsumerWidget {
  const SocialInstagramAppBar({
    super.key,
    this.onPostPublished,
    this.onTitleTap,
  });

  final VoidCallback? onPostPublished;

  /// Başlığa dokununca (ör. akışın başına dön).
  final VoidCallback? onTitleTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.paddingOf(context).top;
    final systemUnread = ref.watch(inboxSystemUnreadCountProvider);
    final messagesUnread = ref.watch(inboxMessagesUnreadCountProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, top + 8, 10, 6),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              button: onTitleTap != null,
              label: 'CanlıFal',
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
                        Icons.auto_awesome,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'CanlıFal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          fontSize: 26,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _BadgeIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Bildirimler',
            dotOnly: true,
            count: systemUnread,
            onTap: () => InboxRoutes.open(context, tab: InboxTab.system),
          ),
          const SizedBox(width: 6),
          _BadgeIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: 'Mesajlar',
            count: messagesUnread,
            onTap: () => InboxRoutes.open(context, tab: InboxTab.messages),
          ),
        ],
      ),
    );
  }
}

class _BadgeIconButton extends StatelessWidget {
  const _BadgeIconButton({
    required this.icon,
    required this.tooltip,
    required this.count,
    required this.onTap,
    this.dotOnly = false,
  });

  final IconData icon;
  final String tooltip;
  final int count;
  final VoidCallback onTap;
  final bool dotOnly;

  @override
  Widget build(BuildContext context) {
    const badgeColor = Color(0xFFFF2D55);
    return Semantics(
      button: true,
      label: count > 0 ? '$tooltip, $count okunmamış' : tooltip,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: InkResponse(
          onTap: onTap,
          radius: 26,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 30, color: context.colors.onSurface),
                if (count > 0)
                  Positioned(
                    top: dotOnly ? 8 : 2,
                    right: dotOnly ? 8 : 0,
                    child: dotOnly
                        ? Container(
                            width: 11,
                            height: 11,
                            decoration: const BoxDecoration(
                              color: badgeColor,
                              shape: BoxShape.circle,
                            ),
                          )
                        : Container(
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
