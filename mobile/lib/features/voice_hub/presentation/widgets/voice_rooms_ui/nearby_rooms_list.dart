import 'package:flutter/material.dart';

import 'nearby_room_tile_card.dart';
import 'voice_rooms_mock_data.dart';
import 'voice_rooms_ui_tokens.dart';

class NearbyRoomsList extends StatelessWidget {
  const NearbyRoomsList({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: VoiceRoomsUiTokens.padScreenH,
          ),
          child: Row(
            children: List.generate(VoiceRoomsMockData.nearbyTabs.length, (i) {
              final active = i == selectedTab;
              return Padding(
                padding: EdgeInsets.only(
                  right: i == VoiceRoomsMockData.nearbyTabs.length - 1
                      ? 0
                      : VoiceRoomsUiTokens.gapSm,
                ),
                child: GestureDetector(
                  onTap: () => onTabChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: active ? VoiceRoomsUiTokens.purpleGradient : null,
                      color: active ? null : const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(
                        VoiceRoomsUiTokens.radiusPill,
                      ),
                      border: Border.all(
                        color: active
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                      boxShadow: active
                          ? VoiceRoomsUiTokens.purpleGlowShadow(blur: 14)
                          : null,
                    ),
                    child: Text(
                      VoiceRoomsMockData.nearbyTabs[i],
                      style: TextStyle(
                        color: active
                            ? Colors.white
                            : VoiceRoomsUiTokens.textSecondary,
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: VoiceRoomsUiTokens.gapMd),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: VoiceRoomsUiTokens.padScreenH,
          ),
          itemCount: VoiceRoomsMockData.nearbyRooms.length,
          itemBuilder: (context, index) {
            final room = VoiceRoomsMockData.nearbyRooms[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 280 + index * 40),
              curve: Curves.easeOut,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - value)),
                  child: child,
                ),
              ),
              child: NearbyRoomTileCard(room: room, onJoin: () {}),
            );
          },
        ),
      ],
    );
  }
}
