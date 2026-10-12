import 'dart:async';

import 'package:flutter/material.dart';

import '../../../domain/pk/pk_battle_remote_models.dart';
import '../../../domain/pk/pk_opponent_room_filter.dart';
import '../../../../../live/domain/entities/voice_room_entity.dart';

/// PK bittiğinde tam sayfa yerine PK ekranında kompakt sonuç şeridi.
class VoicePkInlineResultStrip extends StatefulWidget {
  const VoicePkInlineResultStrip({
    super.key,
    required this.remote,
    required this.room,
    required this.myUserId,
    this.onDismiss,
    this.onRematch,
  });

  final PkBattleRemote remote;
  final VoiceRoomEntity room;
  final String? myUserId;
  final VoidCallback? onDismiss;
  final VoidCallback? onRematch;

  @override
  State<VoicePkInlineResultStrip> createState() =>
      _VoicePkInlineResultStripState();
}

class _VoicePkInlineResultStripState extends State<VoicePkInlineResultStrip> {
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    _autoClose = Timer(const Duration(seconds: 6), _dismiss);
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    super.dispose();
  }

  void _dismiss() {
    _autoClose?.cancel();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    final remote = widget.remote;
    final left = remote.challengerScore;
    final right = remote.opponentScore;
    final draw = left == right;
    final mineChallenger = isPkChallengerRoom(remote, widget.room);
    final myScore = mineChallenger ? left : right;
    final theirScore = mineChallenger ? right : left;
    final iWon = !draw && myScore > theirScore;

    final title = draw
        ? 'Berabere'
        : iWon
            ? 'Kazandınız'
            : 'Kaybettiniz';

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF1A0F2E).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'PK bitti · $title',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$myScore — $theirScore',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onRematch != null)
                      TextButton(
                        onPressed: widget.onRematch,
                        child: const Text('Tekrar PK'),
                      ),
                    IconButton(
                      tooltip: 'Kapat',
                      onPressed: _dismiss,
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: Colors.white70,
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
