import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_design.dart';
import '../../../core/widgets/discover_tab_layout.dart';
import '../../live/domain/entities/voice_room_entity.dart';
import '../../live/presentation/providers/live_providers.dart';
import 'widgets/voice_room_web_card.dart';

/// Sesli sohbet listesi — canlifal.com web arayüzüne yakın neon düzen.
class VoiceRoomsBody extends ConsumerWidget {
  const VoiceRoomsBody({super.key});

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
        final featured = list.first;
        final rest = list.length > 1 ? list.sublist(1) : <VoiceRoomEntity>[];

        return RefreshIndicator(
          color: AppDesign.accentPink,
          backgroundColor: AppDesign.bgPurpleGlow,
          onRefresh: () async => ref.invalidate(voiceRoomsProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            children: [
              const Text(
                'Popüler odalar',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Web’deki gibi neon sesli sohbet odalarına katıl',
                style: TextStyle(
                  color: AppDesign.textMuted.withValues(alpha: 0.95),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              VoiceRoomWebCard(
                room: featured,
                large: true,
                onTap: () => context.push('/voice-room/${featured.id}', extra: featured),
              ),
              if (rest.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Tüm odalar',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                ...rest.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: VoiceRoomWebCard(
                      room: r,
                      onTap: () => context.push('/voice-room/${r.id}', extra: r),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
