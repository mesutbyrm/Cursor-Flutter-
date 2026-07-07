import 'package:flutter/material.dart';

import 'voice_rooms_svg_icons.dart';
import 'voice_rooms_ui_tokens.dart';
import 'voice_glass_container.dart';

class MyRoomCard extends StatelessWidget {
  const MyRoomCard({super.key});

  @override
  Widget build(BuildContext context) {
    return VoiceGlassContainer(
      radius: VoiceRoomsUiTokens.radiusLg,
      glowColor: VoiceRoomsUiTokens.purpleGlow,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: VoiceRoomsUiTokens.fabGradient,
              boxShadow: VoiceRoomsUiTokens.purpleGlowShadow(blur: 28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: Center(
              child: VoiceRoomsSvgIcons.icon('mic', size: 32, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Odalarım',
            style: TextStyle(
              color: VoiceRoomsUiTokens.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kendi odanı oluştur',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: VoiceRoomsUiTokens.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusPill),
              splashColor: Colors.white24,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: VoiceRoomsUiTokens.purpleGradient,
                  borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusPill),
                  boxShadow: VoiceRoomsUiTokens.purpleGlowShadow(blur: 16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VoiceRoomsSvgIcons.icon('sparkle', size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      const Text(
                        'Oda Oluştur',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      VoiceRoomsSvgIcons.icon('sparkle', size: 14, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
