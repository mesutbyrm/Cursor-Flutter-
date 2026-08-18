import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/images/canlifal_image_prefetch.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../feed/presentation/widgets/discover_premium_2026/discover_premium_room_card.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../vip_gold/presentation/utils/open_voice_room_vip.dart';
import '../../../../voice_hub/presentation/providers/voice_rooms_presence_provider.dart';
import '../../../../voice_hub/presentation/utils/open_voice_chat_room_flow.dart';
import '../../providers/home_providers.dart';
import '../../theme/home_approved_design.dart';
import 'home_section_title.dart';

/// Ana sayfa — premium neon sesli oda kartları.
class VoiceRoomSection extends ConsumerStatefulWidget {
  const VoiceRoomSection({super.key});

  static const _cardH = 220.0;
  static const _cardW = 168.0;

  @override
  ConsumerState<VoiceRoomSection> createState() => _VoiceRoomSectionState();
}

class _VoiceRoomSectionState extends ConsumerState<VoiceRoomSection> {
  var _prefetched = false;
  var _presenceSynced = false;

  void _syncPresenceOnce(List<VoiceRoomEntity> rooms) {
    if (_presenceSynced || rooms.isEmpty) return;
    _presenceSynced = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(voiceRoomsPresenceProvider.notifier).mergeTrackRooms(
            rooms.take(VoiceRoomsPresenceNotifier.maxTrackedRooms).toList(),
          );
    });
  }

  void _prefetchCovers(List<VoiceRoomEntity> rooms) {
    if (_prefetched || !mounted) return;
    _prefetched = true;
    final urls = rooms
        .map((r) => r.backgroundImageUrl)
        .whereType<String>()
        .where((u) => u.isNotEmpty)
        .take(12)
        .toList();
    if (urls.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      prefetchCanlifalImages(context, urls: urls, thumbnailWidth: 360);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(homeLiveVoiceRoomsProvider);

    if (rooms.isLoading && !rooms.hasValue) {
      return _sectionShell(
        context,
        ref,
        child: SizedBox(
          height: VoiceRoomSection._cardH,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
            itemCount: 2,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, _) => const PremiumSkeleton(
              width: VoiceRoomSection._cardW,
              height: VoiceRoomSection._cardH,
              borderRadius: BorderRadius.all(
                Radius.circular(HomeApprovedDesign.cardRadius),
              ),
            ),
          ),
        ),
      );
    }
    if (rooms.hasError && !rooms.hasValue) {
      return _sectionShell(
        context,
        ref,
        message: ApiException.userMessage(rooms.error!),
      );
    }
    final items = rooms.valueOrNull ?? const <VoiceRoomEntity>[];
    if (items.isEmpty) {
      return _sectionShell(context, ref, empty: true);
    }
    _syncPresenceOnce(items);
    final sorted = items;
    _prefetchCovers(sorted);

    return _sectionShell(
      context,
      ref,
      child: SizedBox(
        height: VoiceRoomSection._cardH,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemCount: sorted.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final room = sorted[i];
            return DiscoverPremiumRoomCard(
              room: room,
              width: VoiceRoomSection._cardW,
              enableMotion: false,
              onTap: () => openVoiceRoomWithVipGate(context, ref, room),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionShell(
    BuildContext context,
    WidgetRef ref, {
    Widget? child,
    String? message,
    bool empty = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: HomeSectionTitle(
                emoji: '🎙️',
                title: 'Sesli Sohbet Odaları',
                actionLabel: 'Tüm Odalar >',
                onAction: () => context.push('/voice-rooms'),
              ),
            ),
            TextButton.icon(
              onPressed: () => showOpenVoiceChatRoomFlow(context, ref),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Oda Aç'),
              style: TextButton.styleFrom(
                foregroundColor: HomeApprovedDesign.purple,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        if (child != null)
          child
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(
              HomeApprovedDesign.hPad,
              8,
              HomeApprovedDesign.hPad,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  message ??
                      'Henüz oda yok. İlk sesli sohbet odanızı açın.',
                  style: TextStyle(
                    fontSize: 13,
                    color: HomeApprovedDesign.textMuted.withValues(alpha: 0.9),
                  ),
                ),
                if (empty || message != null) ...[
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: empty
                        ? () => showOpenVoiceChatRoomFlow(context, ref)
                        : () => ref.invalidate(homeVoiceRoomsProvider),
                    icon: Icon(empty ? Icons.mic_rounded : Icons.refresh_rounded),
                    label: Text(empty ? 'Sesli Oda Aç · 100 Jeton' : 'Yenile'),
                    style: FilledButton.styleFrom(
                      backgroundColor: HomeApprovedDesign.purple,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
