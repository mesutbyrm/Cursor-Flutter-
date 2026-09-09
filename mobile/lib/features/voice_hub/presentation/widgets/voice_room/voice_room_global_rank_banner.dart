import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/voice_room_rank_celebration_provider.dart';
import '../../providers/voice_room_ranking_provider.dart';
import '../../sheets/voice_room_ranking_sheet.dart';

/// Top 3 oda sıralama başarısı — üstten premium bildirim.
class VoiceRoomGlobalRankBanner extends ConsumerStatefulWidget {
  const VoiceRoomGlobalRankBanner({super.key});

  static const autoDismissDuration = Duration(seconds: 8);

  @override
  ConsumerState<VoiceRoomGlobalRankBanner> createState() =>
      _VoiceRoomGlobalRankBannerState();
}

class _VoiceRoomGlobalRankBannerState
    extends ConsumerState<VoiceRoomGlobalRankBanner> {
  Timer? _autoDismiss;
  int? _trackedSeq;

  @override
  void dispose() {
    _autoDismiss?.cancel();
    super.dispose();
  }

  void _armAutoDismiss(VoiceRoomRankCelebration event) {
    if (_trackedSeq == event.seq) return;
    _trackedSeq = event.seq;
    _autoDismiss?.cancel();
    _autoDismiss = Timer(VoiceRoomGlobalRankBanner.autoDismissDuration, () {
      if (!mounted) return;
      ref.read(voiceRoomRankCelebrationProvider.notifier).dismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(voiceRoomRankCelebrationProvider);
    if (event == null) {
      _autoDismiss?.cancel();
      _trackedSeq = null;
      return const SizedBox.shrink();
    }
    _armAutoDismiss(event);

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
          key: ValueKey(event.seq),
          tween: Tween(begin: -0.15, end: 0),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (_, offset, child) => Transform.translate(
            offset: Offset(0, offset * 80),
            child: child,
          ),
          child: GestureDetector(
            onTap: () => showVoiceRoomRankingSheet(
              context,
              ref,
              initial: event.period,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A1450), Color(0xFF12082A)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.45),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB832FF).withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          const SizedBox(height: 2),
                          Text(
                            'Sıralamayı görmek için dokun',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref
                          .read(voiceRoomRankCelebrationProvider.notifier)
                          .dismiss(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
