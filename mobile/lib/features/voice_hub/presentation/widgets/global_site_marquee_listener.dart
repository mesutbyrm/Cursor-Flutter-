import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/bootstrap/startup_perf.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../gifts/presentation/global/global_gift_notification.dart';
import '../../../gifts/presentation/global/global_gift_overlay_notifier.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../data/services/voice_room_debug_log.dart';
import '../providers/staff_entrance_marquee_provider.dart';

/// Site geneli kayan şerit + yeni hediye overlay.
/// Hediyeler ana sayfa arama altındaki şeritte dönmez.
///
/// `/api/homepage-ticker` birikmiş duyuru geçmişini döndürür; satırlar
/// `HomepageGiftTickerGate` üzerinden geçer, böylece yalnızca bu oturumda
/// gerçekten yeni olan duyurular şeride düşer.
class GlobalSiteMarqueeListener extends ConsumerStatefulWidget {
  const GlobalSiteMarqueeListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GlobalSiteMarqueeListener> createState() =>
      _GlobalSiteMarqueeListenerState();
}

class _GlobalSiteMarqueeListenerState
    extends ConsumerState<GlobalSiteMarqueeListener>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 8);
  static const _newsSource = 'homepage_ticker';

  Timer? _poll;
  String? _sessionUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(StartupPerf.homeRealtimeBridgeDelay, () {
        if (!mounted) return;
        _startPolling();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_poll != null) return;
      // Arka planda kaçırılan duyurular dönüşte canlı olay gibi toplu
      // gösterilmesin — kaynak yeniden seed edilir.
      ref.read(homepageGiftTickerGateProvider).resetNewsSource(_newsSource);
      _startPolling();
      return;
    }
    _poll?.cancel();
    _poll = null;
  }

  void _startPolling() {
    if (_poll != null) return;
    unawaited(_refresh());
    _poll = Timer.periodic(_pollInterval, (_) => unawaited(_refresh()));
  }

  /// Hesap değişiminde önceki kullanıcının görülmüş duyuruları taşınmaz.
  void _handleSessionChange(String? userId) {
    if (_sessionUserId == userId) return;
    _sessionUserId = userId;
    ref.read(homepageGiftTickerGateProvider).reset();
    ref.read(staffEntranceMarqueeProvider.notifier).resetSession();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    try {
      final lines = await ref.read(homeRemoteProvider).fetchHomepageTicker();
      if (!mounted) return;
      final gate = ref.read(homepageGiftTickerGateProvider);
      final marquee = ref.read(staffEntranceMarqueeProvider.notifier);
      final fresh = gate.takeNewNewsLines(lines, source: _newsSource);
      VoiceRoomDebugLog.log('ticker.news', {
        'source': _newsSource,
        'fetched': lines.length,
        'emitted': fresh.length,
      });
      for (final line in fresh) {
        marquee.enqueue(line);
      }
      final overlay = ref.read(globalGiftOverlayProvider.notifier);
      for (final gift in gate.takeNewGiftAnnouncements(lines)) {
        overlay.enqueue(GlobalGiftNotification.fromTicker(gift));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (_, next) {
      _handleSessionChange(next.valueOrNull?.id);
    });
    return widget.child;
  }
}
