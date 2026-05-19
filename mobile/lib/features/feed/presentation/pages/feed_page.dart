import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_design.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../providers/feed_providers.dart';
import '../widgets/discover/discover_background.dart';
import '../widgets/discover/discover_fortune_tarot.dart';
import '../widgets/discover/discover_header.dart';
import '../widgets/discover/discover_hero.dart';
import '../widgets/discover/discover_live_carousel.dart';
import '../widgets/discover/discover_quick_actions.dart';
import '../widgets/discover/discover_voice_orbs.dart';

/// Keşfet ana sayfa — pixel tasarım (canlı yayın, hızlı işlemler, odalar, fal).
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  Future<void> _refresh() async {
    ref.invalidate(liveStreamsProvider);
    ref.invalidate(voiceRoomsProvider);
    await ref.read(feedNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppDesign.bgBase,
      body: DiscoverBackground(
        child: RefreshIndicator(
          color: AppDesign.accentPink,
          backgroundColor: AppDesign.bgPurpleGlow,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: top)),
              const SliverToBoxAdapter(child: DiscoverHeader()),
              const SliverToBoxAdapter(child: DiscoverHeroHeadline()),
              const SliverToBoxAdapter(child: DiscoverLiveCarousel()),
              const SliverToBoxAdapter(child: DiscoverQuickActions()),
              const SliverToBoxAdapter(child: DiscoverVoiceOrbs()),
              const SliverToBoxAdapter(child: DiscoverFortuneTarot()),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.paddingOf(context).bottom + 100,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
