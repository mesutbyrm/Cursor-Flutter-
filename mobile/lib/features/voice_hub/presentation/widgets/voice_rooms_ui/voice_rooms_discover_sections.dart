import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../performance/voice_rooms_perf.dart';
import '../../providers/voice_rooms_discover_providers.dart';
import 'voice_rooms_nearby_tabs.dart';
import 'voice_rooms_ui.dart';

/// Kategori şeridi — yalnızca kategori state değişince rebuild.
class VoiceRoomsCategorySection extends ConsumerWidget {
  const VoiceRoomsCategorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrapping = ref.watch(
      voiceRoomsDiscoverProvider.select(
        (s) => s.isBootstrapping && s.categories.isEmpty,
      ),
    );
    if (bootstrapping) {
      return const VoiceRoomsCategorySkeleton();
    }
    final categories = ref.watch(
      voiceRoomsDiscoverProvider.select((s) => s.categories),
    );
    final selectedIndex = ref.watch(
      voiceRoomsDiscoverProvider.select((s) => s.categoryIndex),
    );
    return VoiceRoomsFx.sectionEnter(
      VoiceRoomsPerf.section(
        CategorySelector(
          categories: categories,
          selectedIndex: selectedIndex,
          onSelected: ref.read(voiceRoomsDiscoverProvider.notifier).selectCategory,
        ),
      ),
    );
  }
}

class VoiceRoomsFeaturedSection extends ConsumerWidget {
  const VoiceRoomsFeaturedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrapping = ref.watch(
      voiceRoomsDiscoverProvider.select(
        (s) => s.isBootstrapping && s.categories.isEmpty,
      ),
    );
    if (bootstrapping) {
      return const VoiceRoomsFeaturedSkeleton();
    }
    final items = ref.watch(
      voiceRoomsDiscoverProvider.select((s) => s.featured),
    );
    return VoiceRoomsFx.sectionEnter(
      VoiceRoomsPerf.section(FeaturedBanner(items: items)),
      delayMs: 60,
    );
  }
}

class VoiceRoomsPopularSection extends ConsumerWidget {
  const VoiceRoomsPopularSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrapping = ref.watch(
      voiceRoomsDiscoverProvider.select(
        (s) => s.isBootstrapping && s.categories.isEmpty,
      ),
    );
    if (bootstrapping) {
      return const VoiceRoomsPopularSkeleton();
    }
    final rooms = ref.watch(
      voiceRoomsDiscoverProvider.select((s) => s.popular),
    );
    return VoiceRoomsFx.sectionEnter(
      VoiceRoomsPerf.section(PopularRoomsCarousel(rooms: rooms)),
      delayMs: 120,
    );
  }
}

class VoiceRoomsSidebarSection extends ConsumerWidget {
  const VoiceRoomsSidebarSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trends = ref.watch(
      voiceRoomsDiscoverProvider.select((s) => s.trends),
    );
    final speakers = ref.watch(
      voiceRoomsDiscoverProvider.select((s) => s.speakers),
    );
    return VoiceRoomsFx.sectionEnter(
      VoiceRoomsPerf.section(
        Column(
          children: [
            const MyRoomCard(),
            const SizedBox(height: VoiceRoomsUiTokens.gapMd),
            TrendingTopicsCard(topics: trends),
            const SizedBox(height: VoiceRoomsUiTokens.gapMd),
            ActiveSpeakersCard(speakers: speakers),
          ],
        ),
      ),
      delayMs: 180,
    );
  }
}

class VoiceRoomsNearbyTabsSection extends ConsumerWidget {
  const VoiceRoomsNearbyTabsSection({super.key});

  static const _tabs = VoiceRoomsMockData.nearbyTabs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(
      voiceRoomsDiscoverProvider.select((s) => s.nearbyTab.index),
    );
    return VoiceRoomsPerf.section(
      VoiceRoomsNearbyTabs(
        tabs: _tabs,
        selectedTab: selectedTab,
        onTabChanged: (i) => ref
            .read(voiceRoomsDiscoverProvider.notifier)
            .selectNearbyTab(VoiceRoomsNearbyTab.values[i.clamp(0, 2)]),
      ),
    );
  }
}
