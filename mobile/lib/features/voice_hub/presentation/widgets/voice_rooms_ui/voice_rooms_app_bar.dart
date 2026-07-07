import 'package:flutter/material.dart';

import 'voice_rooms_mock_data.dart';
import 'voice_rooms_svg_icons.dart';
import 'voice_rooms_ui_tokens.dart';

class VoiceRoomsAppBar extends StatelessWidget {
  const VoiceRoomsAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VoiceRoomsUiTokens.padScreenH,
        8,
        VoiceRoomsUiTokens.padScreenH,
        4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileAvatar(),
          const SizedBox(width: VoiceRoomsUiTokens.gapMd),
          const Expanded(child: _TitleBlock()),
          _ActionIcons(),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Hero(
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
            alignment: Alignment.center,
            child: Text(
              VoiceRoomsMockData.userName.characters.first,
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
                'VIP ${VoiceRoomsMockData.vipLevel}',
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
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconButton(iconKey: 'search'),
        _IconButton(iconKey: 'trophy'),
        _NotificationButton(),
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
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: VoiceRoomsUiTokens.badgeRed,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: VoiceRoomsUiTokens.glowShadow(
                      VoiceRoomsUiTokens.badgeRed,
                      blur: 8,
                    ),
                  ),
                  child: Text(
                    '${VoiceRoomsMockData.notificationCount}',
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