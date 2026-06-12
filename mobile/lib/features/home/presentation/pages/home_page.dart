import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/bootstrap/stuck_overlay_guard.dart';
import '../providers/home_providers.dart';
import '../providers/home_realtime_bridge.dart';
import '../theme/home_approved_design.dart';
import '../widgets/approved/discover_section.dart';
import '../widgets/approved/fan_club_section.dart';
import '../widgets/approved/fortune_section.dart';
import '../widgets/approved/gold_section.dart';
import '../widgets/approved/home_header.dart';
import '../widgets/approved/live_broadcast_section.dart';
import '../widgets/approved/live_fortune_tellers_section.dart';
import '../widgets/approved/more_fortunes_button.dart';
import '../widgets/approved/stories_section.dart';
import '../widgets/approved/trending_video_section.dart';
import '../widgets/approved/voice_room_section.dart';
import '../widgets/home_game_center_section.dart';
import '../widgets/home_games_row.dart';

/// Onaylı ana sayfa mockup — piksel uyumlu bölüm sırası.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Timer? _overlayScrubTimer;
  var _overlayScrubTicks = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StuckOverlayGuard.dismissRoot(reason: 'home-mount');
      ref.read(homeRealtimeBridgeProvider).start();
    });
    _armOverlayScrub();
  }

  @override
  void dispose() {
    _overlayScrubTimer?.cancel();
    super.dispose();
  }

  void _armOverlayScrub() {
    _overlayScrubTimer?.cancel();
    _overlayScrubTicks = 0;
    _overlayScrubTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _overlayScrubTicks >= 40) {
        _overlayScrubTimer?.cancel();
        return;
      }
      _overlayScrubTicks++;
      StuckOverlayGuard.dismissRoot(reason: 'home-scrub-$_overlayScrubTicks');
    });
  }

  Future<void> _onRefresh() => refreshHomeData(ref);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: HomeApprovedDesign.background,
      body: RefreshIndicator(
        color: HomeApprovedDesign.purple,
        backgroundColor: HomeApprovedDesign.surface,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            const SliverToBoxAdapter(child: HomeHeader()),
            const SliverToBoxAdapter(child: StoriesSection()),
            const SliverToBoxAdapter(child: LiveBroadcastSection()),
            const SliverToBoxAdapter(child: VoiceRoomSection()),
            const SliverToBoxAdapter(child: LiveFortuneTellersSection()),
            const SliverToBoxAdapter(child: FortuneSection()),
            const SliverToBoxAdapter(child: TrendingVideoSection()),
            const SliverToBoxAdapter(child: DiscoverSection()),
            const SliverToBoxAdapter(child: HomeGameCenterSection()),
            const SliverToBoxAdapter(child: HomeGamesRow()),
            const SliverToBoxAdapter(child: FanClubSection()),
            const SliverToBoxAdapter(child: GoldSection()),
            const SliverToBoxAdapter(child: MoreFortunesButton()),
            SliverToBoxAdapter(child: SizedBox(height: 72 + bottom)),
          ],
        ),
      ),
    );
  }
}
