import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/bootstrap/startup_perf.dart';
import '../../../gifts/presentation/global/global_gift_event_bridge.dart';
import '../../../home/presentation/providers/home_providers.dart';

/// Site geneli kayan şerit verisi — 1000+ hediye, Gold/admin giriş, homepage ticker.
/// Ana sayfa arama altında ayrı widget yok; [StaffEntranceMarqueeHost] gösterir.
class GlobalSiteMarqueeListener extends ConsumerStatefulWidget {
  const GlobalSiteMarqueeListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GlobalSiteMarqueeListener> createState() =>
      _GlobalSiteMarqueeListenerState();
}

class _GlobalSiteMarqueeListenerState
    extends ConsumerState<GlobalSiteMarqueeListener> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(StartupPerf.homeRealtimeBridgeDelay, () {
        if (!mounted) return;
        unawaited(_refresh());
        _poll = Timer.periodic(const Duration(seconds: 20), (_) {
          unawaited(_refresh());
        });
      });
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    try {
      final cached = ref.read(homeTickerProvider).valueOrNull;
      if (cached != null && cached.isNotEmpty) return;
      ref.invalidate(homeTickerProvider);
      await ref.read(homeTickerProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
