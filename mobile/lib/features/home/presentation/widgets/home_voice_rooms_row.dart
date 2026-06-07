import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/domain/entities/voice_room_sort.dart';
import '../../../vip_gold/presentation/utils/open_voice_room_vip.dart';
import '../providers/home_providers.dart';
import '../theme/home_palette.dart';
import 'home_circular_orb.dart';
import 'home_section_header.dart';

/// Sesli sohbet — yuvarlak oda halkaları (canlifal.com ana sayfa).
class HomeVoiceRoomsRow extends ConsumerWidget {
  const HomeVoiceRoomsRow({super.key});

  static const _placeholderTitles = [
    'Sohbet',
    'CanlıFal',
    'Müzik',
    'Gece',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.useNextAuth) {
      return _section(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Sesli odalar için giriş yapın.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ),
      );
    }

    final rooms = ref.watch(homeVoiceRoomsProvider);

    return rooms.when(
      loading: () => _section(
        child: SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, __) => const PremiumSkeleton(
              width: 72,
              height: 72,
              borderRadius: BorderRadius.all(Radius.circular(36)),
            ),
          ),
        ),
      ),
      error: (e, _) => _section(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            ApiException.userMessage(e),
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
      data: (items) => _section(
        child: _buildRow(context, ref, sortVoiceRoomsByPopularity(items)),
      ),
    );
  }

  Widget _section({required Widget child}) {
    return Builder(
      builder: (context) => Column(
        children: [
          HomeSectionHeader(
            title: 'Sesli Sohbet Odaları',
            leadingDotColor: HomePalette.secondary,
            onTrailing: () => context.push('/voice-rooms'),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    WidgetRef ref,
    List<VoiceRoomEntity> rooms,
  ) {
    final preview = rooms.take(12).toList();
    final count =
        preview.isEmpty ? _placeholderTitles.length : preview.length;

    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) {
          if (preview.isEmpty) {
            return HomeCircularOrb(
              title: _placeholderTitles[i % _placeholderTitles.length],
              subtitle: '0 kişi',
              ringColor: _ringColor(i),
              onTap: () => context.push('/voice-rooms'),
            );
          }
          final room = preview[i];
          return HomeCircularOrb(
            title: room.displayTitle,
            subtitle: '${room.displayOnline} kişi',
            imageUrl: room.ownerAvatarUrl,
            ringColor: _ringColor(i),
            onTap: () => openVoiceRoomWithVipGate(context, ref, room),
          );
        },
      ),
    );
  }

  Color _ringColor(int i) {
    const colors = [
      Color(0xFFFF4FD8),
      Color(0xFF25F4EE),
      Color(0xFF7B2FF7),
      Color(0xFFFF6B35),
      Color(0xFF22C55E),
      Color(0xFFFBBF24),
    ];
    return colors[i % colors.length];
  }
}
