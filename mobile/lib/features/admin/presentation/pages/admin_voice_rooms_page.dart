import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/voice_rooms_list_notifier.dart';
import '../providers/staff_access_provider.dart';
import '../widgets/admin_voice_room_mini_panel.dart';

/// Admin — aktif sesli odalar (`GET /api/chat/rooms`).
class AdminVoiceRoomsPage extends ConsumerWidget {
  const AdminVoiceRoomsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManageVoiceRooms && !access.canManagePayments) {
      return _locked(context);
    }

    final roomsAsync = ref.watch(voiceRoomsListNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: DiscoverTabHeader(
                      title: 'Sesli Oda Yönetimi',
                      subtitle: 'Aktif odalar — katılımcı ve moderasyon',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: () =>
                        ref.invalidate(voiceRoomsListNotifierProvider),
                  ),
                ],
              ),
            ),
            Expanded(
              child: roomsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppThemeColors.accentPink,
                  ),
                ),
                error: (e, _) => Center(
                  child: DiscoverEmptyState(
                    icon: Icons.error_outline_rounded,
                    message: ApiException.userMessage(e),
                    actionLabel: 'Tekrar',
                    action: () =>
                        ref.invalidate(voiceRoomsListNotifierProvider),
                  ),
                ),
                data: (rooms) {
                  if (rooms.isEmpty) {
                    return Center(
                      child: DiscoverEmptyState(
                        icon: Icons.meeting_room_outlined,
                        message: 'Aktif sesli oda bulunamadı.',
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppThemeColors.accentPink,
                    onRefresh: () async {
                      ref.invalidate(voiceRoomsListNotifierProvider);
                      await ref.read(voiceRoomsListNotifierProvider.future);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      itemCount: rooms.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        return _RoomCard(room: rooms[i]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locked(BuildContext context) {
    return Scaffold(
      body: DiscoverBackground(
        child: Center(
          child: DiscoverEmptyState(
            icon: Icons.lock_outline_rounded,
            message: 'Sesli oda yönetimi için yetkiniz yok.',
            actionLabel: 'Geri',
            action: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends ConsumerWidget {
  const _RoomCard({required this.room});
  final VoiceRoomEntity room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = room.displayOnline;
    return DiscoverGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.meeting_room_rounded,
                color: AppThemeColors.accentCyan,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  room.nameTr.isNotEmpty ? room.nameTr : 'Sesli Oda',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sahip: ${room.ownerName?.isNotEmpty == true ? room.ownerName : room.ownerId ?? '—'}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          Text(
            'Katılımcı: $members',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/voice-room/${room.id}', extra: room),
                  child: const Text('Odaya gir'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => showAdminVoiceRoomMiniPanel(
                    context: context,
                    ref: ref,
                    room: room,
                  ),
                  child: const Text('Admin panel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
