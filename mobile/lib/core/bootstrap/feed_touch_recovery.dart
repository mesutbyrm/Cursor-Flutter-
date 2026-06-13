import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'app_startup_log.dart';
import 'stuck_overlay_guard.dart';

/// Ana kabuk ilk karelerinde yetim [ModalBarrier] varsa tek seferlik kurtarma.
class FeedTouchRecovery extends StatefulWidget {
  const FeedTouchRecovery({super.key, required this.child});

  final Widget child;

  @override
  State<FeedTouchRecovery> createState() => _FeedTouchRecoveryState();
}

class _FeedTouchRecoveryState extends State<FeedTouchRecovery> {
  var _pass = 0;
  static const _maxPasses = 6;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.scheduleFrameCallback(_tick);
  }

  void _tick(Duration _) {
    if (!mounted || _pass >= _maxPasses) return;
    _pass++;
    final removed = StuckOverlayGuard.recoverOrphanBarriersOnce(
      reason: 'feed-touch-$_pass',
    );
    if (removed > 0) {
      AppStartupLog.log('FeedTouchRecovery pass=$_pass removed=$removed');
    }
    if (_pass < _maxPasses) {
      SchedulerBinding.instance.scheduleFrameCallback(_tick);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
