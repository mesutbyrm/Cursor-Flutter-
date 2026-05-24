import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../theme/voice_room_tokens.dart';
import 'voice_glass.dart';

/// Keşfet — arama ve kategori çipleri.
class VoiceDiscoverHeader extends StatelessWidget {
  const VoiceDiscoverHeader({
    super.key,
    required this.searchController,
    required this.selectedCategory,
    required this.onCategory,
    this.onSearchChanged,
    this.roomCount = 0,
  });

  final TextEditingController searchController;
  final String selectedCategory;
  final ValueChanged<String> onCategory;
  final ValueChanged<String>? onSearchChanged;
  final int roomCount;

  static const categories = [
    'Tümü',
    'Popüler',
    'Sohbet',
    'Müzik',
    'Oyun',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VoiceGlass(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          borderRadius: 24,
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Oda veya kullanıcı ara…',
              hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.9)),
              border: InputBorder.none,
              icon: Icon(Icons.search_rounded,
                  color: VoiceRoomTokens.neonBlue.withValues(alpha: 0.9)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final c in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(c),
                    selected: selectedCategory == c,
                    onSelected: (_) => onCategory(c),
                    selectedColor: VoiceRoomTokens.neonPurple.withValues(alpha: 0.35),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      fontWeight:
                          selectedCategory == c ? FontWeight.w800 : FontWeight.w600,
                      color: selectedCategory == c ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$roomCount sesli sohbet odası',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted.withValues(alpha: 0.95),
          ),
        ),
      ],
    );
  }
}
