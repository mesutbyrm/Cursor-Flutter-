import 'package:flutter/material.dart';

import 'popular_room_card.dart';
import 'voice_rooms_mock_data.dart';
import 'voice_rooms_svg_icons.dart';
import 'voice_rooms_ui_tokens.dart';

class PopularRoomsCarousel extends StatelessWidget {
  const PopularRoomsCarousel({super.key, required this.rooms});

  final List<PopularRoomItem> rooms;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VoiceRoomsUiTokens.padScreenH,
            VoiceRoomsUiTokens.gapLg,
            VoiceRoomsUiTokens.padScreenH,
            VoiceRoomsUiTokens.gapSm,
          ),
          child: Row(
            children: [
              VoiceRoomsSvgIcons.icon(
                'fire',
                size: 18,
                color: VoiceRoomsUiTokens.orange,
              ),
              const SizedBox(width: 6),
              const Text(
                'Popüler Sesli Odalar',
                style: TextStyle(
                  color: VoiceRoomsUiTokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          'Tümünü Gör',
                          style: TextStyle(
                            color: VoiceRoomsUiTokens.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        VoiceRoomsSvgIcons.icon(
                          'chevron_right',
                          size: 14,
                          color: VoiceRoomsUiTokens.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: VoiceRoomsUiTokens.padScreenH,
            ),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == rooms.length - 1
                      ? 0
                      : VoiceRoomsUiTokens.gapMd,
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 320 + index * 60),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.scale(scale: 0.92 + 0.08 * value, child: child),
                  ),
                  child: PopularRoomCard(room: room),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
