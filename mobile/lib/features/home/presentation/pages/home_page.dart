import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/bootstrap/app_startup_log.dart';
import 'package:canlifal_social/core/bootstrap/startup_perf.dart';
import 'package:canlifal_social/core/performance/scroll_perf.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
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
  HomeRealtimeBridge? _realtimeBridge;
  Timer? _realtimeStartTimer;

  @override
  void initState() {
    super.initState();
    _realtimeBridge = ref.read(homeRealtimeBridgeProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppStartupLog.homeScreenRender('/feed');
    });
    _realtimeStartTimer = Timer(StartupPerf.homeRealtimeBridgeDelay, () {
      if (!mounted) return;
      _realtimeBridge?.start();
    });
  }

  @override
  void dispose() {
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

    return Scaffold(
      backgroundColor: context.isDarkTheme
          ? HomeApprovedDesign.background
          : context.colors.scaffoldBackground,
      body: RefreshIndicator(
        displacement: 28,
        color: context.isDarkTheme
            ? HomeApprovedDesign.purple
            : context.colors.primary,
        backgroundColor: context.isDarkTheme
            ? HomeApprovedDesign.surface
            : context.colors.surface,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          cacheExtent: ScrollPerf.feedCacheExtent,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: HomePageSections.slivers(bottomInset: bottom),
        ),
      ),
    );
  }
}
