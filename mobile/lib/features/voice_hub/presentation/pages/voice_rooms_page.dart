import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/canlifal_image_prefetch.dart';
import '../../../../core/performance/voice_room_entry_perf.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
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
  var _prefetchedImages = false;
  var _sidebarReady = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(VoiceRoomsPerf.sidebarLazyDelay, () {
      if (mounted) setState(() => _sidebarReady = true);
    });
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
      for (final room in rooms.take(3)) {
        VoiceRoomEntryPerf.prewarmOnRoomTap(ref, room);
      }
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

    // Alt navigasyon yalnızca uygulama kabuğundan gelir (AppBottomNavHost);
    // bu sayfa kendi menüsünü çizmez (çift navigasyon olmaz).
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: VoiceRoomsUiTokens.bgAmoled,
        splashFactory: InkRipple.splashFactory,
      ),
      child: Scaffold(
        backgroundColor: VoiceRoomsUiTokens.bgAmoled,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const VoiceRoomsStaticBackground(),
            SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: RefreshIndicator(
                    color: VoiceRoomsUiTokens.purpleGlow,
                    backgroundColor: VoiceRoomsUiTokens.bgAmoled,
                    onRefresh: () async {
                      invalidateDiscoverVoiceRooms(ref);
                      await ref.read(voiceRoomsProvider.future);
                      await ref
                          .read(voiceRoomsDiscoverProvider.notifier)
                          .refresh();
                    },
                    child: CustomScrollView(
                      physics: VoiceRoomsPerf.scrollPhysics,
                      scrollCacheExtent: VoiceRoomsPerf.scrollCacheExtent,
                      slivers: [
                        const SliverToBoxAdapter(child: VoiceRoomsHeaderBar()),
                        const SliverToBoxAdapter(child: VoiceRoomsHeroBanner()),
                        const SliverToBoxAdapter(child: SizedBox(height: 14)),
                        const SliverToBoxAdapter(
                          child: VoiceRoomsCategorySection(),
                        ),
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              VoiceRoomsUiTokens.padScreenH,
                              6,
                              VoiceRoomsUiTokens.padScreenH,
                              0,
                            ),
                            child: MyRoomCard(),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: VoiceRoomsPopularGridSection(),
                        ),
                        const SliverToBoxAdapter(
                          child: VoiceRoomsFeaturedBanner(),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              VoiceRoomsUiTokens.padScreenH,
                              VoiceRoomsUiTokens.gapLg + 4,
                              VoiceRoomsUiTokens.padScreenH,
                              0,
                            ),
                            child: _sidebarReady
                                ? const VoiceRoomsSidebarSection()
                                : const VoiceRoomsSidebarSkeleton(),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: VoiceRoomsFeaturedCategories(),
                        ),
                        const SliverToBoxAdapter(
                          child: VoiceRoomsCreateBanner(),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 28)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sabit (animasyonsuz) koyu mor zemin — sürekli çizim/parçacık yok.
class VoiceRoomsStaticBackground extends StatelessWidget {
  const VoiceRoomsStaticBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0B33), Color(0xFF0B0516), Color(0xFF050505)],
          stops: [0, 0.45, 1],
        ),
      ),
    );
  }
}
