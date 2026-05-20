import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_refresh.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../providers/feed_providers.dart';
import '../widgets/discover/discover_background.dart';
import '../widgets/discover/discover_fortune_tarot.dart';
import '../widgets/discover/discover_header.dart';
import '../widgets/discover/discover_hero.dart';
import '../widgets/discover/discover_live_carousel.dart';
import '../widgets/discover/discover_quick_actions.dart';
import '../widgets/discover/discover_voice_orbs.dart';

/// Keşfet ana sayfa — premium discover layout.
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  Future<void> _refresh() async {
    await Future.wait([
      ref.refresh(liveStreamsProvider.future),
      ref.refresh(voiceRoomsProvider.future),
      ref.read(feedNotifierProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: DiscoverRefresh.wrap(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverSafeArea(
                top: true,
                bottom: false,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const RepaintBoundary(child: DiscoverHeader()),
                    const RepaintBoundary(child: DiscoverHeroHeadline()),
                    const RepaintBoundary(child: DiscoverLiveCarousel()),
                    const RepaintBoundary(child: DiscoverQuickActions()),
                    const RepaintBoundary(child: DiscoverVoiceOrbs()),
                    const RepaintBoundary(child: DiscoverFortuneTarot()),
                    SizedBox(height: bottom + 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
