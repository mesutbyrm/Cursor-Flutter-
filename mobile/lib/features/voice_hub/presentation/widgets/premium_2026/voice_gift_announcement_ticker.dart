import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/voice_recent_gifts_provider.dart';
import '../../theme/voice_room_tokens.dart';

/// Hediye duyurusu — kayan tek satır (ör. «Mesut, Suna … 🪙1000 jeton.🎉»).
class VoiceGiftAnnouncementTicker extends ConsumerStatefulWidget {
  const VoiceGiftAnnouncementTicker({super.key});

  @override
  ConsumerState<VoiceGiftAnnouncementTicker> createState() =>
      _VoiceGiftAnnouncementTickerState();
}

class _VoiceGiftAnnouncementTickerState
    extends ConsumerState<VoiceGiftAnnouncementTicker>
    with SingleTickerProviderStateMixin {
  final _scrollCtrl = ScrollController();
  late final Ticker _marqueeTicker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;
  String? _lastShownId;

  @override
  void initState() {
    super.initState();
    _marqueeTicker.start();
  }

  @override
  void dispose() {
    _marqueeTicker.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (!_scrollCtrl.hasClients) return;
    final max = _scrollCtrl.position.maxScrollExtent;
    if (max <= 0) return;
    var next = _scrollCtrl.offset + 36.0 * dt;
    if (next > max) next = 0;
    _scrollCtrl.jumpTo(next);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(voiceGiftAnnouncementsProvider);
    if (items.isEmpty) return const SizedBox.shrink();

    final latest = items.first;
    if (_lastShownId != latest.id) {
      _lastShownId = latest.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
      });
    }

    final text = items.map((e) => e.line).join('   •   ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              VoiceRoomTokens.neonPink.withValues(alpha: 0.22),
              Colors.black.withValues(alpha: 0.55),
            ],
          ),
          border: Border.all(
            color: VoiceRoomTokens.gold.withValues(alpha: 0.35),
          ),
        ),
        child: SizedBox(
          height: 28,
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
