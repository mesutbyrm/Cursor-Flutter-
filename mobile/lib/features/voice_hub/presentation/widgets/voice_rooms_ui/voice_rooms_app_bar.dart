import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/images/canlifal_network_image.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../../vip_gold/presentation/providers/vip_membership_provider.dart';
import 'voice_rooms_hero.dart';
import 'voice_rooms_mock_data.dart';
import 'voice_rooms_svg_icons.dart';
import 'voice_rooms_ui_tokens.dart';

class VoiceRoomsAppBar extends ConsumerWidget {
  const VoiceRoomsAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(
      authControllerProvider.select(
        (a) => a.valueOrNull?.display ?? VoiceRoomsMockData.userName,
      ),
    );
    final vipLevel = ref.watch(vipTierProvider.select((t) => t.index + 1));
    final notificationCount = ref.watch(notificationsUnreadCountProvider);
    final avatarUrl = ref.watch(
      authControllerProvider.select((a) => a.valueOrNull?.avatarUrl),
    );

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VoiceRoomsUiTokens.padScreenH,
          8,
          VoiceRoomsUiTokens.padScreenH,
          4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileAvatar(
              userName: userName,
              vipLevel: vipLevel,
              avatarUrl: avatarUrl,
            ),
            const SizedBox(width: VoiceRoomsUiTokens.gapMd),
            const Expanded(child: _TitleBlock()),
            _ActionIcons(notificationCount: notificationCount),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.userName,
    required this.vipLevel,
    this.avatarUrl,
  });

  final String userName;
  final int vipLevel;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim() ?? '';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        VoiceRoomsHero(
          tag: 'voice_rooms_profile',
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: VoiceRoomsUiTokens.purpleGradient,
              boxShadow: VoiceRoomsUiTokens.purpleGlowShadow(blur: 16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: url.isNotEmpty
                ? CanlifalNetworkImage(
                    url: url,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    thumbnailWidth: 96,
                    fadeIn: false,
                  )
                : Text(
                    userName.characters.first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
          ),
        ),
        Positioned(
          bottom: -4,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                gradient: VoiceRoomsUiTokens.purpleGradient,
                borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusPill),
                boxShadow: VoiceRoomsUiTokens.glowShadow(
                  VoiceRoomsUiTokens.purpleGlow,
                  blur: 10,
                ),
              ),
              child: Text(
                'VIP $vipLevel',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Sesli Odalar',
              style: TextStyle(
                color: VoiceRoomsUiTokens.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(width: 6),
            VoiceRoomsSvgIcons.icon(
              'soundwave',
              size: 20,
              color: VoiceRoomsUiTokens.purpleGlow,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Konuş, dinle, yeni insanlarla tanış!',
          style: TextStyle(
            color: VoiceRoomsUiTokens.textSecondary.withValues(alpha: 0.95),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _ActionIcons extends StatelessWidget {
  const _ActionIcons({required this.notificationCount});

  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _IconButton(iconKey: 'search'),
        const _IconButton(iconKey: 'trophy'),
        _NotificationButton(count: notificationCount),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.iconKey});

  final String iconKey;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        customBorder: const CircleBorder(),
        splashColor: VoiceRoomsUiTokens.purpleGlow.withValues(alpha: 0.2),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: VoiceRoomsSvgIcons.icon(
            iconKey,
            size: 22,
            color: VoiceRoomsUiTokens.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        customBorder: const CircleBorder(),
        splashColor: VoiceRoomsUiTokens.purpleGlow.withValues(alpha: 0.2),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              VoiceRoomsSvgIcons.icon(
                'bell',
                size: 22,
                color: VoiceRoomsUiTokens.textPrimary,
              ),
              if (count > 0)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: VoiceRoomsUiTokens.badgeRed,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: VoiceRoomsUiTokens.glowShadow(
                        VoiceRoomsUiTokens.badgeRed,
                        blur: 8,
                      ),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
