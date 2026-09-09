import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/voice_room_rank_celebration_provider.dart';
import '../providers/voice_room_ranking_provider.dart';

/// Top 3 oda sıralama başarısı — üstten premium bildirim.
class VoiceRoomGlobalRankBanner extends ConsumerWidget {
  const VoiceRoomGlobalRankBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(voiceRoomRankCelebrationProvider);
    if (event == null) return const SizedBox.shrink();

    final medal = switch (event.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '🏆',
    };
    final periodLabel =
        event.period == VoiceRoomRankingPeriod.hourly ? 'SAATLİK' : 'GÜNLÜK';

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: 12,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: -0.15, end: 0),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (_, offset, child) => Transform.translate(
            offset: Offset(0, offset * 80),
            child: child,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A1450), Color(0xFF12082A)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB832FF).withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Text(medal, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Canlifal Oda Başarısı',
                          style: TextStyle(
                            color: Color(0xFFFFD54F),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '🔥 ${event.roomName} şu anda $periodLabel sıralamada ${event.rank}. sırada!',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        ref.read(voiceRoomRankCelebrationProvider.notifier).dismiss(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
