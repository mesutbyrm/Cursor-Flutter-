import 'package:flutter/material.dart';

import '../../performance/voice_rooms_perf.dart';
import 'popular_room_card.dart';
import 'voice_rooms_svg_icons.dart';
import 'voice_rooms_ui_tokens.dart';
import 'voice_rooms_mock_data.dart';

class PopularRoomsCarousel extends StatelessWidget {
  const PopularRoomsCarousel({
    super.key,
    required this.rooms,
    required this.onRoomTap,
  });

  final List<PopularRoomItem> rooms;
  final ValueChanged<PopularRoomItem> onRoomTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            VoiceRoomsUiTokens.padScreenH,
            VoiceRoomsUiTokens.gapLg,
            VoiceRoomsUiTokens.padScreenH,
            VoiceRoomsUiTokens.gapSm,
          ),
          child: _PopularHeader(),
        ),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            scrollCacheExtent: VoiceRoomsPerf.scrollCacheExtent,
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
                child: RepaintBoundary(
                  key: ValueKey('popular_${room.id}'),
                  child: PopularRoomCard(
                    room: room,
                    onTap: () => onRoomTap(room),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PopularHeader extends StatelessWidget {
  const _PopularHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
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
      ],
    );
  }
}
