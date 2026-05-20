import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_design.dart';
import '../../../core/widgets/discover_tab_layout.dart';
import '../../live/domain/entities/voice_room_entity.dart';
import '../../live/presentation/providers/live_providers.dart';
import 'widgets/voice_room_card.dart';

/// Sesli sohbet listesi — benim odam + responsive popüler odalar (native Flutter).
class VoiceRoomsBody extends ConsumerWidget {
  const VoiceRoomsBody({
    super.key,
    this.embeddedInLiveShellTab = false,
  });

  final bool embeddedInLiveShellTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.useNextAuth) {
      return const DiscoverEmptyState(
        icon: Icons.headset_mic_outlined,
        message:
            'Bu özellik canlifal.com oturumu ile kullanılabilir.\nGiriş yaptıktan sonra odalar burada listelenir.',
      );
    }

    final rooms = ref.watch(voiceRoomsProvider);
    final myRoom = ref.watch(myVoiceRoomProvider);

    return rooms.when(
      loading: () => const DiscoverAccentLoader(),
      error: (e, _) => DiscoverEmptyState(
        icon: Icons.mic_off_rounded,
        message: ApiException.userMessage(e),
        actionLabel: 'Yenile',
        action: () => ref.invalidate(voiceRoomsProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const DiscoverEmptyState(
            icon: Icons.nights_stay_rounded,
            message: 'Henüz oda yok.\nYeni sesli sohbet odaları burada görünecek.',
          );
        }

        final popular = _popularRooms(list, myRoom);

        return RefreshIndicator(
          color: AppDesign.accentPink,
          backgroundColor: AppDesign.bgPurpleGlow,
          onRefresh: () async => ref.invalidate(voiceRoomsProvider),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossCount = width >= 520 ? 2 : 1;
              final pad = embeddedInLiveShellTab ? 8.0 : 4.0;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(16, pad, 16, 100),
                children: [
                  if (myRoom != null) ...[
                    const _SectionTitle(
                      title: 'Benim odam',
                      subtitle: 'Kendi sesli sohbet odanıza doğrudan girin',
                    ),
                    const SizedBox(height: 12),
                    VoiceRoomCard(
                      room: myRoom,
                      large: true,
                      highlight: true,
                      onTap: () => _openRoom(context, myRoom),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const _SectionTitle(
                    title: 'Popüler odalar',
                    subtitle: 'Canlı sesli sohbet — uygulama içi TRTC',
                  ),
                  const SizedBox(height: 12),
                  if (popular.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Şu an listelenecek başka oda yok',
                          style: TextStyle(color: AppDesign.textMuted, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: crossCount == 1 ? 1.55 : 0.92,
                      ),
                      itemCount: popular.length,
                      itemBuilder: (context, i) {
                        final r = popular[i];
                        return VoiceRoomCard(
                          room: r,
                          onTap: () => _openRoom(context, r),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  static List<VoiceRoomEntity> _popularRooms(
    List<VoiceRoomEntity> all,
    VoiceRoomEntity? mine,
  ) {
    if (mine == null) return all;
    return all.where((r) => r.id != mine.id).toList();
  }

  static void _openRoom(BuildContext context, VoiceRoomEntity room) {
    context.push('/voice-room/${room.id}', extra: room);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: AppDesign.textMuted.withValues(alpha: 0.95),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
