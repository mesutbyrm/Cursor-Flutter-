import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/bootstrap/app_startup_log.dart';
import 'package:canlifal_social/core/bootstrap/startup_perf.dart';
import 'package:canlifal_social/core/performance/scroll_perf.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import '../providers/home_bootstrap.dart';
import '../providers/home_providers.dart';
import '../providers/home_realtime_bridge.dart';
import '../theme/home_approved_design.dart';
import '../widgets/home_page_sections.dart';

/// Onaylı ana sayfa mockup — piksel uyumlu bölüm sırası.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _scroll = ScrollController();
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  HomeRealtimeBridge? _realtimeBridge;
  Timer? _realtimeStartTimer;

  @override
  void initState() {
    super.initState();
    _realtimeBridge = ref.read(homeRealtimeBridgeProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppStartupLog.homeScreenRender('/feed');
      ref.read(homeBootstrapProvider.future).ignore();
    });
    _realtimeStartTimer = Timer(StartupPerf.homeRealtimeBridgeDelay, () {
      if (!mounted) return;
      _realtimeBridge?.start();
    });
  }

  /// Alt bar «Ana sayfa» dokunuşu: en üste kaydır, sonra yenile.
  Future<void> _onReselect() async {
    if (!mounted) return;
    if (_scroll.hasClients && _scroll.offset > 0) {
      await _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
    if (!mounted) return;
    final indicator = _refreshKey.currentState;
    if (indicator != null) {
      await indicator.show();
    } else {
      await refreshHomeData(ref);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _realtimeStartTimer?.cancel();
    _realtimeBridge?.dispose();
    _realtimeBridge = null;
    super.dispose();
  }

  Future<void> _onRefresh() {
    // Yenileme anında haptic + tıklama sesi geri bildirimi.
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    return refreshHomeData(ref);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    ref.listen<int>(homeReselectProvider, (prev, next) {
      if (prev != next) unawaited(_onReselect());
    });

    return Scaffold(
      backgroundColor: context.isDarkTheme
          ? HomeApprovedDesign.background
          : context.colors.scaffoldBackground,
      body: RefreshIndicator(
        key: _refreshKey,
        displacement: 28,
        color: context.isDarkTheme
            ? HomeApprovedDesign.purple
            : context.colors.primary,
        backgroundColor: context.isDarkTheme
            ? HomeApprovedDesign.surface
            : context.colors.surface,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scroll,
          scrollCacheExtent: ScrollPerf.scrollCache(ScrollPerf.feedCacheExtent),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: HomePageSections.slivers(bottomInset: bottom),
        ),
      ),
    );
  }
}
