import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/utils/live_discover_category.dart';
import '../providers/live_fortune_request_provider.dart';

/// Canlı keşfet — yatay kategori chip'leri.
class LiveDiscoverCategoryChips extends ConsumerWidget {
  const LiveDiscoverCategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(liveDiscoverCategoryProvider);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: liveDiscoverChipCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = liveDiscoverChipCategories[i];
          final active = cat == selected;
          return FilterChip(
            label: Text(cat.label),
            selected: active,
            onSelected: (_) {
              ref.read(liveDiscoverCategoryProvider.notifier).state = cat;
            },
            selectedColor: const Color(0xFF7C3AED).withValues(alpha: 0.35),
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              color: active ? Colors.white : Colors.white70,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12,
            ),
            side: BorderSide(
              color: active
                  ? const Color(0xFFB832FF)
                  : Colors.white.withValues(alpha: 0.2),
            ),
            backgroundColor: Colors.black.withValues(alpha: 0.25),
          );
        },
      ),
    );
  }
}
