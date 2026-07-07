import 'package:flutter/material.dart';

import '../../performance/voice_rooms_perf.dart';
import 'voice_rooms_mock_data.dart';
import 'voice_rooms_svg_icons.dart';
import 'voice_rooms_ui_tokens.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<VoiceCategoryItem> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        scrollCacheExtent: VoiceRoomsPerf.scrollCacheExtent,
        padding: const EdgeInsets.symmetric(
          horizontal: VoiceRoomsUiTokens.padScreenH,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final item = categories[index];
          final active = index == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(
              right: index == categories.length - 1
                  ? 0
                  : VoiceRoomsUiTokens.gapMd,
            ),
            child: RepaintBoundary(
              child: _CategoryChip(
                item: item,
                active: active,
                onTap: () => onSelected(index),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final VoiceCategoryItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: active ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: active
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: item.colors,
                        )
                      : null,
                  color: active ? null : const Color(0xFF141414),
                  border: Border.all(
                    color: active
                        ? Colors.white.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                  boxShadow: active
                      ? VoiceRoomsUiTokens.glowShadow(item.colors.first, blur: 22)
                      : null,
                ),
                child: Center(
                  child: VoiceRoomsSvgIcons.icon(
                    item.iconKey,
                    size: 22,
                    color: active ? Colors.white : item.colors.first,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  color: active
                      ? VoiceRoomsUiTokens.textPrimary
                      : VoiceRoomsUiTokens.textSecondary,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
