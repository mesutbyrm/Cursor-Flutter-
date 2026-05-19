import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_theme.dart';
import '../../canlifal_web/presentation/canlifal_web_view_page.dart';
import '../../live/domain/entities/voice_room_entity.dart';
import '../../live/presentation/providers/live_providers.dart';

/// Sesli sohbet odaları — site `/api/chat/rooms` ile aynı liste; karta basınca uygulama içi WebView.
class VoiceRoomsBody extends ConsumerWidget {
  const VoiceRoomsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.useNextAuth) {
      return const Center(
        child: Text('Bu özellik canlifal.com oturumu ile kullanılabilir.'),
      );
    }
    final rooms = ref.watch(voiceRoomsProvider);
    return rooms.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            ApiException.userMessage(e),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Henüz oda yok veya liste boş.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.muted),
              ),
            ),
          );
        }
        return RefreshIndicator(
          color: AppTheme.accent,
          onRefresh: () async => ref.invalidate(voiceRoomsProvider),
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
      color: AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          CanlifalWebRoute.location(
            relativePath: '/sohbet/${room.slug}',
            title: room.nameTr,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bg != null && bg.isNotEmpty)
              CachedNetworkImage(
                imageUrl: bg,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const ColoredBox(
                  color: Color(0xFF1E1530),
                ),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3D1F5C), Color(0xFF120A1C)],
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.82),
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
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.lightGreenAccent,
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
                        color: AppTheme.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.login_rounded,
                          size: 16, color: AppTheme.accentSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Odaya gir',
                        style: TextStyle(
                          color: AppTheme.accentSecondary.withValues(alpha: 0.95),
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
    );
  }
}
