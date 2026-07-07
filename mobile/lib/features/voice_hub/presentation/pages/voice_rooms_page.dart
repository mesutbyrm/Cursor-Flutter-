import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../vip_gold/presentation/utils/open_voice_room_vip.dart';
import '../../domain/repositories/voice_rooms_discover_repository.dart';
import '../providers/voice_rooms_discover_providers.dart';
import '../widgets/voice_rooms_ui/voice_rooms_ui.dart';

/// Sesli Odalar ana ekranı — Premium 2026 UI (Abacus AI API).
class VoiceRoomsPage extends ConsumerStatefulWidget {
  const VoiceRoomsPage({super.key});

  @override
  ConsumerState<VoiceRoomsPage> createState() => _VoiceRoomsPageState();
}

class _VoiceRoomsPageState extends ConsumerState<VoiceRoomsPage> {
  VoiceRoomsNavItem _nav = VoiceRoomsNavItem.voice;

  @override
  Widget build(BuildContext context) {
    final discover = ref.watch(voiceRoomsDiscoverProvider);
    final notifier = ref.read(voiceRoomsDiscoverProvider.notifier);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 720;
    final bootstrapping = discover.isBootstrapping && discover.categories.isEmpty;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: VoiceRoomsUiTokens.bgAmoled,
        splashFactory: InkRipple.splashFactory,
      ),
      child: Scaffold(
        backgroundColor: VoiceRoomsUiTokens.bgAmoled,
        extendBody: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _AmbientBackground(),
            SafeArea(
              bottom: false,
              child: RefreshIndicator(
                color: VoiceRoomsUiTokens.purpleGlow,
                backgroundColor: VoiceRoomsUiTokens.bgAmoled,
                onRefresh: notifier.refresh,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollEndNotification || n is ScrollUpdateNotification) {
                      final m = n.metrics;
                      if (m.pixels >= m.maxScrollExtent - 280) {
                        notifier.loadMoreNearby();
                      }
                    }
                    return false;
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      const SliverToBoxAdapter(child: VoiceRoomsAppBar()),
                      if (bootstrapping)
                        const SliverToBoxAdapter(
                          child: VoiceRoomsCategorySkeleton(),
                        )
                      else
                        SliverToBoxAdapter(
                          child: CategorySelector(
                            categories: discover.categories,
                            selectedIndex: discover.categoryIndex,
                            onSelected: notifier.selectCategory,
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      if (bootstrapping)
                        const SliverToBoxAdapter(
                          child: VoiceRoomsFeaturedSkeleton(),
                        )
                      else
                        SliverToBoxAdapter(
                          child: FeaturedBanner(items: discover.featured),
                        ),
                      if (bootstrapping)
                        const SliverToBoxAdapter(
                          child: VoiceRoomsPopularSkeleton(),
                        )
                      else
                        SliverToBoxAdapter(
                          child: PopularRoomsCarousel(rooms: discover.popular),
                        ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: bootstrapping
                              ? (wide
                                  ? _WideSkeleton()
                                  : const _NarrowSkeleton())
                              : wide
                                  ? _WideContent(
                                      discover: discover,
                                      onTabChanged: (i) => notifier
                                          .selectNearbyTab(_tabFromIndex(i)),
                                      onJoinNearby: (item) => _openRoom(
                                        context,
                                        ref,
                                        discover.allRooms,
                                        item.id,
                                      ),
                                    )
                                  : _NarrowContent(
                                      discover: discover,
                                      onTabChanged: (i) => notifier
                                          .selectNearbyTab(_tabFromIndex(i)),
                                      onJoinNearby: (item) => _openRoom(
                                        context,
                                        ref,
                                        discover.allRooms,
                                        item.id,
                                      ),
                                    ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 140)),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniMusicPlayer(),
            ),
          ],
        ),
        bottomNavigationBar: VoiceRoomsBottomNav(
          active: _nav,
          onChanged: (item) => setState(() => _nav = item),
        ),
      ),
    );
  }

  VoiceRoomsNearbyTab _tabFromIndex(int i) =>
      VoiceRoomsNearbyTab.values[i.clamp(0, VoiceRoomsNearbyTab.values.length - 1)];

  void _openRoom(
    BuildContext context,
    WidgetRef ref,
    List<VoiceRoomEntity> rooms,
    String roomId,
  ) {
    VoiceRoomEntity? match;
    for (final r in rooms) {
      if (r.id == roomId) {
        match = r;
        break;
      }
    }
    if (match == null) return;
    openVoiceRoomWithVipGate(context, ref, match);
  }
}

class _WideSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VoiceRoomsUiTokens.padScreenH),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Expanded(flex: 5, child: VoiceRoomsNearbySkeleton()),
          SizedBox(width: VoiceRoomsUiTokens.gapLg),
          Expanded(flex: 3, child: VoiceRoomsSidebarSkeleton()),
        ],
      ),
    );
  }
}

class _NarrowSkeleton extends StatelessWidget {
  const _NarrowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        VoiceRoomsNearbySkeleton(),
        SizedBox(height: VoiceRoomsUiTokens.gapLg),
        VoiceRoomsSidebarSkeleton(),
      ],
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ColoredBox(color: VoiceRoomsUiTokens.bgAmoled),
        Positioned(
          top: -100,
          right: -60,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: VoiceRoomsUiTokens.purpleGlow.withValues(alpha: 0.22),
                  blurRadius: 120,
                  spreadRadius: 30,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 280,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: VoiceRoomsUiTokens.magenta.withValues(alpha: 0.12),
                  blurRadius: 100,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          right: -40,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: VoiceRoomsUiTokens.blue.withValues(alpha: 0.10),
                  blurRadius: 90,
                  spreadRadius: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WideContent extends StatelessWidget {
  const _WideContent({
    required this.discover,
    required this.onTabChanged,
    required this.onJoinNearby,
  });

  final VoiceRoomsDiscoverViewState discover;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<NearbyRoomItem> onJoinNearby;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VoiceRoomsUiTokens.padScreenH),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: NearbyRoomsList(
              rooms: discover.nearbyRooms,
              tabs: VoiceRoomsMockData.nearbyTabs,
              selectedTab: discover.nearbyTab.index,
              onTabChanged: onTabChanged,
              isLoadingMore: discover.isLoadingMore,
              onJoin: onJoinNearby,
            ),
          ),
          const SizedBox(width: VoiceRoomsUiTokens.gapLg),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                const MyRoomCard(),
                const SizedBox(height: VoiceRoomsUiTokens.gapMd),
                TrendingTopicsCard(topics: discover.trends),
                const SizedBox(height: VoiceRoomsUiTokens.gapMd),
                ActiveSpeakersCard(speakers: discover.speakers),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NarrowContent extends StatelessWidget {
  const _NarrowContent({
    required this.discover,
    required this.onTabChanged,
    required this.onJoinNearby,
  });

  final VoiceRoomsDiscoverViewState discover;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<NearbyRoomItem> onJoinNearby;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NearbyRoomsList(
          rooms: discover.nearbyRooms,
          tabs: VoiceRoomsMockData.nearbyTabs,
          selectedTab: discover.nearbyTab.index,
          onTabChanged: onTabChanged,
          isLoadingMore: discover.isLoadingMore,
          onJoin: onJoinNearby,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VoiceRoomsUiTokens.padScreenH,
            VoiceRoomsUiTokens.gapLg,
            VoiceRoomsUiTokens.padScreenH,
            0,
          ),
          child: Column(
            children: [
              const MyRoomCard(),
              const SizedBox(height: VoiceRoomsUiTokens.gapMd),
              TrendingTopicsCard(topics: discover.trends),
              const SizedBox(height: VoiceRoomsUiTokens.gapMd),
              ActiveSpeakersCard(speakers: discover.speakers),
            ],
          ),
        ),
      ],
    );
  }
}
