import 'package:flutter/material.dart';

import 'voice_rooms_ui_tokens.dart';

/// Yakındaki odalar sekme şeridi — ana scroll'dan bağımsız, hafif widget.
class VoiceRoomsNearbyTabs extends StatelessWidget {
  const VoiceRoomsNearbyTabs({
    super.key,
    required this.tabs,
    required this.selectedTab,
    required this.onTabChanged,
  });

  final List<String> tabs;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: VoiceRoomsUiTokens.padScreenH,
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == selectedTab;
          return Padding(
            padding: EdgeInsets.only(
              right: i == tabs.length - 1 ? 0 : VoiceRoomsUiTokens.gapSm,
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
                  tabs[i],
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
    );
  }
}
