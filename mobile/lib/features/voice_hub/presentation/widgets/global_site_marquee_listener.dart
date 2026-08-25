import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/bootstrap/startup_perf.dart';
import '../../../gifts/domain/homepage_gift_ticker.dart';
import '../../../gifts/presentation/global/global_gift_notification.dart';
import '../../../gifts/presentation/global/global_gift_overlay_notifier.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../providers/staff_entrance_marquee_provider.dart';

/// Site geneli kayan şerit + yeni hediye overlay.
/// Hediyeler ana sayfa arama altındaki şeritte dönmez.
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
        _poll = Timer.periodic(const Duration(seconds: 8), (_) {
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
      final lines = await ref.read(homeRemoteProvider).fetchHomepageTicker();
      if (!mounted) return;
      final marquee = ref.read(staffEntranceMarqueeProvider.notifier);
      for (final line in HomepageGiftTicker.newsLines(lines)) {
        marquee.enqueue(line);
      }
      final gifts =
          ref.read(homepageGiftTickerGateProvider).takeNewGiftAnnouncements(
                lines,
              );
      final overlay = ref.read(globalGiftOverlayProvider.notifier);
      for (final gift in gifts) {
        overlay.enqueue(GlobalGiftNotification.fromTicker(gift));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
