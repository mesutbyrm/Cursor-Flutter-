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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StuckOverlayGuard.dismissAll(reason: 'feed-mount', aggressive: true);
      StuckOverlayGuard.armFeedBarrierWatch(onDone: () {});
    });
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || _ticks >= 150) {
        _timer?.cancel();
        return;
      }
      _ticks++;
      StuckOverlayGuard.scrubEntireAppTree(reason: 'feed-tick-$_ticks');
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
