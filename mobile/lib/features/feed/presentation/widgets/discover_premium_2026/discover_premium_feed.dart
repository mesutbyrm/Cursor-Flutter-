import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../../../../../core/ui/premium_2026/premium_motion.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../live/presentation/providers/live_providers.dart';
import '../../../domain/discover_category.dart';
import 'discover_premium_categories.dart';
import 'discover_premium_header.dart';
import 'discover_premium_search.dart';
import 'discover_premium_sections.dart';
import 'discover_premium_stories.dart';
import 'discover_premium_visual.dart';

/// PART 2 — Premium keşfet ana gövde.
class DiscoverPremiumFeed extends ConsumerStatefulWidget {
  const DiscoverPremiumFeed({super.key, this.onRefresh});

  final Future<void> Function()? onRefresh;

  @override
  ConsumerState<DiscoverPremiumFeed> createState() =>
      _DiscoverPremiumFeedState();
}

class _DiscoverPremiumFeedState extends ConsumerState<DiscoverPremiumFeed> {
  final _search = TextEditingController();
  String? _categoryId;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _scheduleVoiceRefresh();
  }

  void _scheduleVoiceRefresh() {
    Future.delayed(const Duration(seconds: 15), () {
      if (!mounted) return;
      ref.invalidate(voiceRoomsProvider);
      _scheduleVoiceRefresh();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onCategoryTap(String? id) {
    if (id == 'pk') {
      final rooms = ref.read(voiceRoomsProvider).valueOrNull;
      if (rooms != null && rooms.isNotEmpty) {
        final r = trendingRooms(rooms).first;
        context.push('/voice-room/${r.apiRoomKey}/pk', extra: r);
        return;
      }
    }
    setState(() => _categoryId = id);
  }

  void _openRoom(VoiceRoomEntity room) {
    context.push('/voice-room/${room.apiRoomKey}', extra: room);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return CosmicGalaxyBackground(
      showVignette: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DiscoverPremiumHeader(),
          DiscoverPremiumSearchBar(
            controller: _search,
            onChanged: (_) => setState(() {}),
            onOpenGlobalSearch: () => context.push('/search'),
          ),
          Expanded(
            child: RefreshIndicator(
              color: DiscoverPremiumVisual.accent,
              backgroundColor: DiscoverPremiumVisual.backgroundMid,
              onRefresh: widget.onRefresh ?? () async {},
              child: CustomScrollView(
              physics: PremiumMotion.listPhysics,
              slivers: [
                const SliverToBoxAdapter(
                  child: RepaintBoundary(child: DiscoverPremiumStories()),
                ),
                SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: DiscoverPremiumCategories(
                      selectedId: _categoryId,
                      onCategoryTap: _onCategoryTap,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: DiscoverPremiumTabs(
                        index: _tab,
                        onChanged: (i) => setState(() => _tab = i),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: AnimatedSwitcher(
                    duration: PremiumMotion.medium,
                    switchInCurve: PremiumMotion.easeOut,
                    switchOutCurve: PremiumMotion.easeIn,
                    child: KeyedSubtree(
                      key: ValueKey('$_tab-$_categoryId-${_search.text}'),
                      child: _tabBody(),
                    ),
                  ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: bottom + 108)),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBody() {
    final query = _search.text;
    switch (_tab) {
      case 1:
        return DiscoverPremiumVoicePanel(
          categoryId: _categoryId,
          query: query,
          onRoomTap: _openRoom,
        );
      case 2:
        return const DiscoverPremiumLivePanel();
      case 0:
      default:
        return DiscoverPremiumTrendPanel(
          categoryId: _categoryId,
          query: query,
          onRoomTap: _openRoom,
        );
    }
  }
}
