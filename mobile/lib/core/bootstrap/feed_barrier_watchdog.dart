import 'dart:async';

import 'package:flutter/material.dart';

import 'stuck_overlay_guard.dart';

/// Ana sayfada takılı kalan modal barrier — sürekli temizlik.
class FeedBarrierWatchdog extends StatefulWidget {
  const FeedBarrierWatchdog({super.key, required this.child});

  final Widget child;

  @override
  State<FeedBarrierWatchdog> createState() => _FeedBarrierWatchdogState();
}

class _FeedBarrierWatchdogState extends State<FeedBarrierWatchdog> {
  Timer? _timer;
  var _ticks = 0;
  var _consecutiveClean = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StuckOverlayGuard.dismissAll(reason: 'feed-mount', aggressive: true);
      StuckOverlayGuard.armFeedBarrierWatch(onDone: () {});
    });
    // Takılı modal barrier yalnızca mount anında (önceki ekrandan taşınmış)
    // ortaya çıkar; onu ilk saniyelerde temizlemek yeterli. Eskiden 200 ms'de
    // 30 sn boyunca TÜM widget ağacı taranıyordu (feed kayarken saniyede 5 kez
    // tam ağaç gezintisi → ciddi jank). Artık ağaç temizlendiği an durur:
    // ard arda 3 tur (≈600 ms) hiçbir şey kaldırılmazsa iptal; en fazla ~2.4 sn.
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || _ticks >= 12) {
        _timer?.cancel();
        return;
      }
      _ticks++;
      final removed =
          StuckOverlayGuard.scrubEntireAppTree(reason: 'feed-tick-$_ticks');
      if (removed == 0) {
        if (++_consecutiveClean >= 3) _timer?.cancel();
      } else {
        _consecutiveClean = 0;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
