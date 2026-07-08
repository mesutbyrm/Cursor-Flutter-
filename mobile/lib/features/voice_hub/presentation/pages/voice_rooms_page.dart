import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/canlifal_image_prefetch.dart';
import '../../../../core/performance/animation_perf.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../vip_gold/presentation/utils/open_voice_room_vip.dart';
import '../performance/voice_rooms_perf.dart';
import '../providers/voice_rooms_discover_providers.dart';
import '../widgets/voice_rooms_ui/voice_rooms_ui.dart';

/// Sesli Odalar ana ekranı — Premium 2026 UI + TikTok seviyesi performans.
class VoiceRoomsPage extends ConsumerStatefulWidget {
  const VoiceRoomsPage({super.key});

  @override
  ConsumerState<VoiceRoomsPage> createState() => _VoiceRoomsPageState();
}

class _VoiceRoomsPageState extends ConsumerState<VoiceRoomsPage>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();
  VoiceRoomsNavItem _nav = VoiceRoomsNavItem.voice;
  var _prefetchedImages = false;
  var _sidebarReady = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future<void>.delayed(VoiceRoomsPerf.sidebarLazyDelay, () {
      if (mounted) setState(() => _sidebarReady = true);
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels < pos.maxScrollExtent - VoiceRoomsPerf.scrollPreloadPx) {
      return;
    }
    ref.read(voiceRoomsDiscoverProvider.notifier).loadMoreNearby();
  }

  void _prefetchRoomImages(List<VoiceRoomEntity> rooms) {
    if (_prefetchedImages || !mounted) return;
    _prefetchedImages = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final urls = rooms
          .map((r) => r.backgroundImageUrl ?? r.ownerAvatarUrl)
          .whereType<String>()
          .where((u) => u.trim().isNotEmpty)
          .take(VoiceRoomsPerf.imagePrefetchMax);
      unawaited(
        prefetchCanlifalImages(
          context,
          urls: urls,
          thumbnailWidth: VoiceRoomsPerf.imageThumbnailWidth,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ref.listen(
      voiceRoomsDiscoverProvider.select((s) => s.allRooms),
      (prev, next) {
        if (next.isNotEmpty && next != prev) {
          _prefetchRoomImages(next);
        }
      },
    );

    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 720;
    final bootstrapping = ref.watch(
      voiceRoomsDiscoverProvider.select(
        (s) => s.isBootstrapping && s.categories.isEmpty,
      ),
    );
    final nearbyRooms = ref.watch(
      voiceRoomsDiscoverProvider.select((s) => s.nearbyRooms),
    );
    final isLoadingMore = ref.watch(
      voiceRoomsDiscoverProvider.select((s) => s.isLoadingMore),
    );
    final allRooms = ref.watch(
      voiceRoomsDiscoverProvider.select((s) => s.allRooms),
    );

    final sidebarPad = wide
        ? (width - VoiceRoomsUiTokens.padScreenH * 2) * 3 / 8 +
            VoiceRoomsUiTokens.gapLg +
            VoiceRoomsUiTokens.padScreenH
        : 0.0;

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
                onRefresh: ref.read(voiceRoomsDiscoverProvider.notifier).refresh,
                child: CustomScrollView(
                  controller: _scroll,
                  physics: VoiceRoomsPerf.scrollPhysics,
                  scrollCacheExtent: VoiceRoomsPerf.scrollCacheExtent,
                  slivers: [
                    const SliverToBoxAdapter(child: VoiceRoomsAppBar()),
                    const SliverToBoxAdapter(child: VoiceRoomsCategorySection()),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    const SliverToBoxAdapter(child: VoiceRoomsFeaturedSection()),
                    const SliverToBoxAdapter(child: VoiceRoomsPopularSection()),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: VoiceRoomsUiTokens.gapSm),
                    ),
                    if (bootstrapping)
                      const SliverToBoxAdapter(child: VoiceRoomsNearbySkeleton())
                    else ...[
                      if (wide)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: VoiceRoomsUiTokens.padScreenH,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Expanded(
                                  flex: 5,
                                  child: VoiceRoomsNearbyTabsSection(),
                                ),
                                const SizedBox(width: VoiceRoomsUiTokens.gapLg),
                                Expanded(
                                  flex: 3,
                                  child: _sidebarReady
                                      ? const VoiceRoomsSidebarSection()
                                      : const VoiceRoomsSidebarSkeleton(),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        const SliverToBoxAdapter(
                          child: VoiceRoomsNearbyTabsSection(),
                        ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: VoiceRoomsUiTokens.gapMd),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.only(
                          left: VoiceRoomsUiTokens.padScreenH,
                          right: wide
                              ? sidebarPad
                              : VoiceRoomsUiTokens.padScreenH,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index >= nearbyRooms.length) {
                                return const _NearbyLoadMoreShimmer();
                              }
                              final room = nearbyRooms[index];
                              return RepaintBoundary(
                                key: ValueKey('nearby_${room.id}'),
                                child: NearbyRoomTileCard(
                                  room: room,
                                  onJoin: () => _openRoom(
                                    context,
                                    allRooms,
                                    room.id,
                                  ),
                                ),
                              );
                            },
                            childCount:
                                nearbyRooms.length + (isLoadingMore ? 1 : 0),
                            addAutomaticKeepAlives: false,
                            addRepaintBoundaries: false,
                          ),
                        ),
                      ),
                      if (!wide)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              VoiceRoomsUiTokens.padScreenH,
                              VoiceRoomsUiTokens.gapLg,
                              VoiceRoomsUiTokens.padScreenH,
                              0,
                            ),
                            child: _sidebarReady
                                ? const VoiceRoomsSidebarSection()
                                : const VoiceRoomsSidebarSkeleton(),
                          ),
                        ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 140)),
                  ],
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

  void _openRoom(
    BuildContext context,
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

class _NearbyLoadMoreShimmer extends StatelessWidget {
  const _NearbyLoadMoreShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: VoiceRoomsUiTokens.gapMd),
      child: _ShimmerTile(),
    );
  }
}

class _ShimmerTile extends StatelessWidget {
  const _ShimmerTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusMd),
        color: const Color(0xFF141414),
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return const DeferredTickerMode(
      delay: Duration(milliseconds: 200),
      child: Stack(
        fit: StackFit.expand,
        children: [
          VoiceDynamicGradientBackground(),
          VoiceRoomParticleField(),
        ],
      ),
    );
  }
}
