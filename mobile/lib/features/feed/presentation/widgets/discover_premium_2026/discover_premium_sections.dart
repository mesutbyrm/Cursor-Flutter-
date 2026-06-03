import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/config/env.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/ui/premium/premium.dart';
import '../../../domain/discover_category.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../live/domain/entities/voice_room_sort.dart';
import '../../../../live/presentation/providers/live_providers.dart';
import '../discover/discover_live_carousel.dart';
import '../discover/discover_section_header.dart';
import 'discover_premium_room_card.dart';

String _sectionTitle(String? categoryId) {
  if (categoryId == null) return 'Sesli sohbet';
  for (final c in DiscoverCategories.all) {
    if (c.id == categoryId) return c.label;
  }
  return 'Sesli sohbet';
}

/// Bölüm başlığı + yatay oda listesi.
class DiscoverPremiumRoomRow extends StatelessWidget {
  const DiscoverPremiumRoomRow({
    super.key,
    required this.title,
    required this.rooms,
    this.actionLabel = 'Tümü',
    this.onAction,
    this.onRoomTap,
  });

  final String title;
  final List<VoiceRoomEntity> rooms;
  final String actionLabel;
  final VoidCallback? onAction;
  final ValueChanged<VoiceRoomEntity>? onRoomTap;

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiscoverSectionHeader(
          title: title,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
        SizedBox(
          height: 228,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final room = rooms[i];
              return DiscoverPremiumRoomCard(
                room: room,
                onTap: () => onRoomTap?.call(room),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Sesli oda içerikleri — provider + filtre.
class DiscoverPremiumVoicePanel extends ConsumerWidget {
  const DiscoverPremiumVoicePanel({
    super.key,
    required this.categoryId,
    required this.query,
    required this.onRoomTap,
  });

  final String? categoryId;
  final String query;
  final ValueChanged<VoiceRoomEntity> onRoomTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.useNextAuth) {
      return PremiumEmptyHint(
        message: 'Sesli odalar için giriş yapın.',
        onRetry: () => context.push('/login'),
      );
    }

    final rooms = ref.watch(voiceRoomsProvider);
    return rooms.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppThemeColors.accentPink,
          ),
        ),
      ),
      error: (e, _) => PremiumEmptyHint(
        message: ApiException.userMessage(e),
        onRetry: () => ref.invalidate(voiceRoomsProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const PremiumEmptyHint(
            message: 'Henüz açık sesli oda yok.',
          );
        }
        final sorted = sortVoiceRoomsByPopularity(list);
        final filtered = filterDiscoverRooms(
          rooms: sorted,
          categoryId: categoryId,
          query: query,
        );
        final trending = trendingRooms(sorted);
        final vip = vipRooms(sorted);

        if (filtered.isEmpty && query.isNotEmpty) {
          return const PremiumEmptyHint(
            message: 'Aramanıza uygun oda bulunamadı.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (categoryId == null || categoryId == 'pk')
              DiscoverPremiumRoomRow(
                title: 'Trend odalar',
                rooms: trending,
                onAction: () => context.push('/voice-rooms'),
                onRoomTap: onRoomTap,
              ),
            if (vip.isNotEmpty)
              DiscoverPremiumRoomRow(
                title: 'VIP odalar',
                rooms: vip.take(6).toList(),
                onAction: () => context.push('/voice-rooms'),
                onRoomTap: onRoomTap,
              ),
            DiscoverPremiumRoomRow(
              title: _sectionTitle(categoryId),
              rooms: (categoryId != null ? filtered : sorted).take(12).toList(),
              onAction: () => context.push('/voice-rooms'),
              onRoomTap: onRoomTap,
            ),
          ],
        );
      },
    );
  }
}

/// Canlı yayın paneli.
class DiscoverPremiumLivePanel extends ConsumerWidget {
  const DiscoverPremiumLivePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const DiscoverLiveCarousel();
  }
}

/// Trend sekmesi — sesli + canlı özet.
class DiscoverPremiumTrendPanel extends ConsumerWidget {
  const DiscoverPremiumTrendPanel({
    super.key,
    required this.categoryId,
    required this.query,
    required this.onRoomTap,
  });

  final String? categoryId;
  final String query;
  final ValueChanged<VoiceRoomEntity> onRoomTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DiscoverLiveCarousel(),
        DiscoverPremiumVoicePanel(
          categoryId: categoryId,
          query: query,
          onRoomTap: onRoomTap,
        ),
      ],
    );
  }
}
