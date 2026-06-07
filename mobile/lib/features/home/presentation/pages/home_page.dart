import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Onaylı ana sayfa mockup — piksel uyumlu bölüm sırası.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeRealtimeBridgeProvider).start();
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
