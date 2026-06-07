import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../vip_gold/domain/voice_room_access.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../live/domain/entities/voice_room_sort.dart';
import '../../../../vip_gold/presentation/utils/open_voice_room_vip.dart';
import '../../providers/home_providers.dart';
import '../../theme/home_approved_design.dart';
import 'home_section_title.dart';

/// Onaylı mockup — geniş yatay sesli oda kartları.
class VoiceRoomSection extends ConsumerWidget {
  const VoiceRoomSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(homeVoiceRoomsProvider);

    return rooms.when(
      loading: () => Column(
        children: [
          HomeSectionTitle(
            emoji: '🎙️',
            title: 'Sesli Sohbet Odaları',
            actionLabel: 'Tüm Odalar >',
            onAction: () => context.push('/voice-rooms'),
          ),
          SizedBox(
            height: HomeApprovedDesign.voiceCardH,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
              itemCount: 2,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, __) => const PremiumSkeleton(
                width: HomeApprovedDesign.voiceCardW,
                height: HomeApprovedDesign.voiceCardH,
                borderRadius: BorderRadius.all(
                  Radius.circular(HomeApprovedDesign.cardRadius),
                ),
              ),
            ),
          ),
        ],
      ),
      error: (_, __) => _content(context, ref, _fallbackRooms),
      data: (items) {
        final sorted = items.isEmpty
            ? _fallbackRooms
            : sortVoiceRoomsByPopularity(items).take(12).toList();
        return _content(context, ref, sorted);
      },
    );
  }

  static Widget _content(
    BuildContext context,
    WidgetRef ref,
    List<VoiceRoomEntity> rooms,
  ) {
    return Column(
      children: [
        HomeSectionTitle(
          emoji: '🎙️',
          title: 'Sesli Sohbet Odaları',
          actionLabel: 'Tüm Odalar >',
          onAction: () => context.push('/voice-rooms'),
        ),
        SizedBox(
          height: HomeApprovedDesign.voiceCardH,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _VoiceRoomCard(
              room: rooms[i],
              onTap: rooms[i].id.startsWith('demo-')
                  ? () => context.push('/voice-rooms')
                  : () => openVoiceRoomWithVipGate(context, ref, rooms[i]),
            ),
          ),
        ),
      ],
    );
  }

  static const _fallbackRooms = [
    VoiceRoomEntity(
      id: 'demo-1',
      slug: 'demo-tarot',
      nameTr: 'Tarot Sohbet',
      descTr: 'Müzik • Sohbet',
      onlineCount: 24,
      icon: '🔮',
    ),
    VoiceRoomEntity(
      id: 'demo-2',
      slug: 'demo-kahve',
      nameTr: 'Kahve Falı Odası',
      descTr: 'Fal • Sohbet',
      onlineCount: 18,
      icon: '☕',
    ),
  ];
}

class _VoiceRoomCard extends StatelessWidget {
  const _VoiceRoomCard({required this.room, required this.onTap});

  final VoiceRoomEntity room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tags = _tagsFor(room);
    final avatars = room.recentUserAvatars.take(4).toList();
    final musicOn = room.activeDjId != null && room.activeDjId!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: HomeApprovedDesign.voiceCardW,
        height: HomeApprovedDesign.voiceCardH,
        padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
        decoration: BoxDecoration(
          color: HomeApprovedDesign.surface,
          borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
          border: Border.all(color: HomeApprovedDesign.border),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipOval(
                  child: room.ownerAvatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: room.ownerAvatarUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          color: HomeApprovedDesign.border,
                          child: Center(
                            child: Text(
                              room.icon ?? '🎤',
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                ),
                if (room.isVipGoldRoom)
                  const Positioned(
                    top: -2,
                    right: -2,
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      size: 16,
                      color: HomeApprovedDesign.gold,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    room.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: HomeApprovedDesign.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tags,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: HomeApprovedDesign.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (avatars.isNotEmpty)
                    SizedBox(
                      height: 18,
                      child: Stack(
                        children: [
                          for (var i = 0; i < avatars.length; i++)
                            Positioned(
                              left: i * 12.0,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: HomeApprovedDesign.surface,
                                    width: 1.2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: avatars[i],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '👤 ${room.displayOnline}/50',
                        style: const TextStyle(
                          fontSize: 9,
                          color: HomeApprovedDesign.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        musicOn ? '● Müzik Açık' : '● Hediyeler Aktif',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: musicOn
                              ? HomeApprovedDesign.green
                              : HomeApprovedDesign.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const _SoundWave(),
          ],
        ),
      ),
    );
  }

  String _tagsFor(VoiceRoomEntity room) {
    final d = room.descTr?.trim();
    if (d != null && d.isNotEmpty) return d;
    return 'Müzik • Sohbet';
  }
}

class _SoundWave extends StatelessWidget {
  const _SoundWave();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _bar(8),
          const SizedBox(width: 2),
          _bar(14),
          const SizedBox(width: 2),
          _bar(10),
          const SizedBox(width: 2),
          _bar(16),
        ],
      ),
    );
  }

  Widget _bar(double h) {
    return Container(
      width: 3,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [HomeApprovedDesign.purple, HomeApprovedDesign.pink],
        ),
      ),
    );
  }
}
