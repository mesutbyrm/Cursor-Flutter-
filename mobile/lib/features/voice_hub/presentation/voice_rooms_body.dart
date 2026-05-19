import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_design.dart';
import '../../../core/widgets/discover_tab_layout.dart';
import '../../live/domain/entities/voice_room_entity.dart';
import '../../live/presentation/providers/live_providers.dart';

/// Sesli sohbet odaları — site `/api/chat/rooms` ile aynı liste.
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
        return RefreshIndicator(
          color: AppDesign.accentPink,
          backgroundColor: AppDesign.bgPurpleGlow,
          onRefresh: () async => ref.invalidate(voiceRoomsProvider),
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.78,
            ),
            itemCount: list.length,
            itemBuilder: (ctx, i) => _VoiceRoomHeroCard(room: list[i]),
          ),
        );
      },
    );
  }
}

class _VoiceRoomHeroCard extends StatelessWidget {
  const _VoiceRoomHeroCard({required this.room});

  final VoiceRoomEntity room;

  @override
  Widget build(BuildContext context) {
    final bg = room.backgroundImageUrl;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDesign.radiusCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDesign.radiusCard),
        onTap: () => context.push(
          '/voice-room/${room.id}',
          extra: room,
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDesign.radiusCard),
            border: Border.all(
              color: AppDesign.accentPurple.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: AppDesign.accentPink.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDesign.radiusCard - 1),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (bg != null && bg.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: bg,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => _fallbackBg(),
                  )
                else
                  _fallbackBg(),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(room.icon ?? '💬',
                              style: const TextStyle(fontSize: 26)),
                          const Spacer(),
                          if (room.onlineCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppDesign.onlineGreen
                                    .withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppDesign.onlineGreen
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppDesign.onlineGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${room.onlineCount}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        room.nameTr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          height: 1.15,
                        ),
                      ),
                      if (room.ownerName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          room.ownerName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppDesign.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.login_rounded,
                            size: 16,
                            color: AppDesign.accentCyan.withValues(alpha: 0.95),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Odaya gir',
                            style: TextStyle(
                              color: AppDesign.accentCyan
                                  .withValues(alpha: 0.95),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _fallbackBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D1F5C), Color(0xFF120A1C)],
        ),
      ),
    );
  }
}
