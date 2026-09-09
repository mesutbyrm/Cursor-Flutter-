import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/voice_rooms_list_notifier.dart';
import '../providers/voice_room_ranking_provider.dart';
import '../providers/voice_room_preview_goal_provider.dart';
import '../providers/voice_room_preview_pk_provider.dart';
import '../providers/voice_rooms_presence_provider.dart';
import '../../../../core/images/canlifal_network_image.dart';

/// Odaya girmeden önce önizleme — PK, sıralama, çevrimiçi sayısı.
Future<bool> showVoiceRoomPreviewSheet(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
}) async {
  await ref.read(voiceRoomRankingProvider.notifier).refresh();
  ref.invalidate(voiceRoomPreviewGoalProvider(room.apiRoomKey));
  ref.invalidate(voiceRoomPreviewPkProvider(room.apiRoomKey));
  ref.read(voiceRoomsPresenceProvider.notifier).mergeTrackRooms([room]);
  if (!context.mounted) return false;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _VoiceRoomPreviewSheet(room: room),
  );
  return result == true;
}

class _VoiceRoomPreviewSheet extends ConsumerWidget {
  const _VoiceRoomPreviewSheet({required this.room});

  final VoiceRoomEntity room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveRoom = ref.watch(
      voiceRoomsListNotifierProvider.select((async) {
        final rooms = async.valueOrNull;
        if (rooms == null) return room;
        final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
        for (final r in rooms) {
          if (r.apiRoomKey == key || r.id == key) return r;
        }
        return room;
      }),
    );
    final ranking = ref.watch(voiceRoomRankingProvider);
    final hourly = ref
        .read(voiceRoomRankingProvider.notifier)
        .rankForRoom(room.apiRoomKey, period: VoiceRoomRankingPeriod.hourly);
    final daily = ref
        .read(voiceRoomRankingProvider.notifier)
        .rankForRoom(room.apiRoomKey, period: VoiceRoomRankingPeriod.daily);
    final hourlyScore = ref
        .read(voiceRoomRankingProvider.notifier)
        .scoreForRoom(room.apiRoomKey, period: VoiceRoomRankingPeriod.hourly);
    final goalAsync = ref.watch(voiceRoomPreviewGoalProvider(room.apiRoomKey));
    final pkAsync = ref.watch(voiceRoomPreviewPkProvider(room.apiRoomKey));
    final activeGoal = goalAsync.valueOrNull;
    final activePk = pkAsync.valueOrNull;
    final onlineCount = ref.watch(
      voiceRoomsPresenceProvider.select((p) => p.countFor(liveRoom)),
    );
    final bottom = MediaQuery.paddingOf(context).bottom;
    final owner = room.ownerName?.trim().isNotEmpty == true
        ? room.ownerName!.trim()
        : 'Oda sahibi';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF14082E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Avatar(room: room),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sahip · $owner',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (room.descTr?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              room.descTr!.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                Icons.people_rounded,
                '$onlineCount çevrimiçi',
                const Color(0xFF5B8CFF),
              ),
              if (liveRoom.isPkLive)
                _chip(Icons.flash_on_rounded, 'PK canlı', const Color(0xFFB832FF)),
              if (activePk != null && activePk.isActive)
                _chip(
                  Icons.timer_rounded,
                  'PK ${_formatRemaining(Duration(seconds: activePk.resolvedSecondsLeft()))}',
                  const Color(0xFFFF5252),
                ),
              if (activePk != null && activePk.isPending)
                _chip(Icons.hourglass_top_rounded, 'PK daveti', const Color(0xFFFFB300)),
              if (liveRoom.hasMusicActivity)
                _chip(Icons.music_note_rounded, 'Müzik', const Color(0xFFFF2D7A)),
              if (liveRoom.isVip == true)
                _chip(Icons.diamond_rounded, 'VIP', const Color(0xFFFFD54F)),
              if (hourlyScore != null)
                _chip(
                  Icons.bolt_rounded,
                  '$hourlyScore puan',
                  const Color(0xFF7C4DFF),
                ),
              if (hourly != null && hourly <= 100)
                _chip(Icons.emoji_events_rounded, 'Saatlik #$hourly', const Color(0xFFFFB300)),
              if (daily != null && daily <= 100 && daily != hourly)
                _chip(Icons.calendar_today_rounded, 'Günlük #$daily', const Color(0xFF00E5C3)),
              if (activeGoal != null)
                _chip(
                  Icons.card_giftcard_rounded,
                  'Hedef %${(activeGoal.progress * 100).round()}',
                  const Color(0xFF9C27FF),
                ),
            ],
          ),
          if (activeGoal != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: activeGoal.progress,
                minHeight: 5,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF9C27FF)),
              ),
            ),
            if (activeGoal.endsAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Hedef süresi: ${_formatRemaining(activeGoal.remainingTime)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 10,
                ),
              ),
            ],
          ],
          if (ranking.lastUpdated != null) ...[
            const SizedBox(height: 10),
            Text(
              'Sıralama güncellendi · ${ranking.hourly.length} oda',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Vazgeç', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB832FF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Odaya Gir', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatRemaining(Duration? remaining) {
    if (remaining == null) return '';
    final total = remaining.inSeconds;
    if (total <= 0) return '00:00';
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.room});

  final VoiceRoomEntity room;

  @override
  Widget build(BuildContext context) {
    final url = room.ownerAvatarUrl;
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.white12,
      backgroundImage: url != null && url.isNotEmpty ? canlifalImageProvider(url) : null,
      child: url == null || url.isEmpty
          ? Text(room.icon ?? '🎤', style: const TextStyle(fontSize: 24))
          : null,
    );
  }
}
