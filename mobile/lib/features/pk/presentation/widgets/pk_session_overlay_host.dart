import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/pk_models.dart';
import '../providers/pk_session_notifier.dart';
import 'pk_countdown_overlay.dart';
import 'pk_result_overlay.dart';

/// PK durum geçişlerinde tam ekran geri sayım / sonuç.
class PkSessionOverlayHost extends ConsumerStatefulWidget {
  const PkSessionOverlayHost({
    super.key,
    required this.args,
    required this.child,
  });

  final PkSessionArgs args;
  final Widget child;

  @override
  ConsumerState<PkSessionOverlayHost> createState() =>
      _PkSessionOverlayHostState();
}

class _PkSessionOverlayHostState extends ConsumerState<PkSessionOverlayHost> {
  PkStatus? _lastStatus;
  String? _lastBattleId;

  @override
  Widget build(BuildContext context) {
    // Canlı yayın PK'sinde tam ekran geri sayım / sonuç diyalogları
    // `LivePkSplitVideoLayer` içinde inline olarak gösteriliyor
    // (LivePkPreparingOverlay / LivePkResultFlashOverlay). Buradaki
    // showDialog tabanlı overlay'ler onlarla çakışıyor ve sonuç diyaloğu
    // ekranda takılı kalabiliyordu. Bu yüzden canlı akışta devre dışı.
    if (widget.args.kind == PkContextKind.live) {
      return widget.child;
    }
    ref.listen<PkSessionState>(pkSessionProvider(widget.args), (prev, next) {
      final battle = next.battle;
      if (battle == null) {
        _lastStatus = null;
        _lastBattleId = null;
        return;
      }
      final status = battle.status;
      final battleChanged = _lastBattleId != battle.id;
      _lastBattleId = battle.id;

      if (status == PkStatus.starting &&
          (battleChanged || _lastStatus != PkStatus.starting)) {
        unawaited(showPkCountdownOverlay(context, seconds: 5));
      }
      if (status == PkStatus.completed &&
          (battleChanged || _lastStatus != PkStatus.completed)) {
        final winner = battle.isDraw || battle.winnerId.isEmpty
            ? null
            : battle.winnerId == battle.user1Id
                ? (battle.user1?.name ?? 'Kazanan')
                : (battle.user2?.name ?? 'Kazanan');
        unawaited(
          showPkResultOverlay(
            context,
            battle: battle,
            winnerName: winner,
          ),
        );
      }
      _lastStatus = status;
    });

    return widget.child;
  }
}
