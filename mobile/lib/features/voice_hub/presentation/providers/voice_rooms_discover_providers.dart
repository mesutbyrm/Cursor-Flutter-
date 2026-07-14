import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../gifts/data/leaderboard_remote_datasource.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../data/datasources/voice_rooms_discover_remote_datasource.dart';
import '../../data/repositories/voice_rooms_discover_repository_impl.dart';
import '../../data/mappers/voice_rooms_discover_mapper.dart';
import '../../domain/repositories/voice_rooms_discover_repository.dart';
import '../../presentation/widgets/voice_rooms_ui/voice_rooms_mock_data.dart';
import '../../../live/domain/entities/voice_room_entity.dart';

export '../../domain/repositories/voice_rooms_discover_repository.dart'
    show VoiceRoomsNearbyTab;

final voiceRoomsDiscoverRemoteProvider =
    Provider<VoiceRoomsDiscoverRemoteDataSource>((ref) {
  return VoiceRoomsDiscoverRemoteDataSource(
    ref.watch(dioProvider),
    ref.watch(liveRemoteProvider),
    LeaderboardRemoteDataSource(ref.watch(dioProvider)),
  );
});

final voiceRoomsDiscoverRepositoryProvider =
    Provider<VoiceRoomsDiscoverRepository>((ref) {
  return VoiceRoomsDiscoverRepositoryImpl(
    ref.watch(voiceRoomsDiscoverRemoteProvider),
  );
});

class VoiceRoomsDiscoverViewState {
  const VoiceRoomsDiscoverViewState({
    this.isBootstrapping = true,
    this.isLoadingMore = false,
    this.categoryIndex = 0,
    this.nearbyTab = VoiceRoomsNearbyTab.nearby,
    this.categories = const [],
    this.featured = const [],
    this.popular = const [],
    this.nearbyRooms = const [],
    this.trends = const [],
    this.speakers = const [],
    this.allRooms = const [],
    this.nearbyPage = 0,
    this.hasMoreNearby = true,
    this.error,
  });

  final bool isBootstrapping;
  final bool isLoadingMore;
  final int categoryIndex;
  final VoiceRoomsNearbyTab nearbyTab;
  final List<VoiceCategoryItem> categories;
  final List<FeaturedRoomItem> featured;
  final List<PopularRoomItem> popular;
  final List<NearbyRoomItem> nearbyRooms;
  final List<TrendingTopicItem> trends;
  final List<ActiveSpeakerItem> speakers;
  final List<VoiceRoomEntity> allRooms;
  final int nearbyPage;
  final bool hasMoreNearby;
  final String? error;

  String? get selectedCategoryId =>
      categories.isEmpty ? 'all' : categories[categoryIndex.clamp(0, categories.length - 1)].id;

  VoiceRoomsDiscoverViewState copyWith({
    bool? isBootstrapping,
    bool? isLoadingMore,
    int? categoryIndex,
    VoiceRoomsNearbyTab? nearbyTab,
    List<VoiceCategoryItem>? categories,
    List<FeaturedRoomItem>? featured,
    List<PopularRoomItem>? popular,
    List<NearbyRoomItem>? nearbyRooms,
    List<TrendingTopicItem>? trends,
    List<ActiveSpeakerItem>? speakers,
    List<VoiceRoomEntity>? allRooms,
    int? nearbyPage,
    bool? hasMoreNearby,
    String? error,
    bool clearError = false,
  }) {
    return VoiceRoomsDiscoverViewState(
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      categoryIndex: categoryIndex ?? this.categoryIndex,
      nearbyTab: nearbyTab ?? this.nearbyTab,
      categories: categories ?? this.categories,
      featured: featured ?? this.featured,
      popular: popular ?? this.popular,
      nearbyRooms: nearbyRooms ?? this.nearbyRooms,
      trends: trends ?? this.trends,
      speakers: speakers ?? this.speakers,
      allRooms: allRooms ?? this.allRooms,
      nearbyPage: nearbyPage ?? this.nearbyPage,
      hasMoreNearby: hasMoreNearby ?? this.hasMoreNearby,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class VoiceRoomsDiscoverNotifier extends StateNotifier<VoiceRoomsDiscoverViewState> {
  VoiceRoomsDiscoverNotifier(this._repo) : super(const VoiceRoomsDiscoverViewState());

  final VoiceRoomsDiscoverRepository _repo;
  var _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> bootstrap({bool forceRefresh = false}) async {
    if (!forceRefresh || state.categories.isEmpty) {
      state = state.copyWith(isBootstrapping: true, clearError: true);
    }
    try {
      final categoryId = state.selectedCategoryId;
      final bundle = await _repo.fetchDiscoverBundle(
        categoryId: categoryId,
        forceRefresh: forceRefresh,
      );
      if (_disposed) return;
      final nearby = _repo.mapNearbyPage(
        rooms: bundle.allRooms,
        tab: state.nearbyTab,
        page: 0,
      );
      state = state.copyWith(
        isBootstrapping: false,
        categories: bundle.categories,
        featured: bundle.featured,
        popular: bundle.popular,
        allRooms: bundle.allRooms,
        nearbyRooms: nearby,
        nearbyPage: 0,
        hasMoreNearby: _repo.hasMoreNearby(
          rooms: bundle.allRooms,
          tab: state.nearbyTab,
          loadedCount: nearby.length,
        ),
        clearError: true,
      );
      unawaited(_loadSecondary(forceRefresh: forceRefresh));
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        isBootstrapping: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _loadSecondary({bool forceRefresh = false}) async {
    try {
      final trends = await _repo.fetchTrends(forceRefresh: forceRefresh);
      final speakers = VoiceRoomsDiscoverMapper.speakersFromRooms(
        state.allRooms,
      );
      if (_disposed) return;
      state = state.copyWith(
        trends: trends,
        speakers: speakers,
      );
    } catch (_) {}
  }

  Future<void> selectCategory(int index) async {
    if (index == state.categoryIndex) return;
    state = state.copyWith(categoryIndex: index);
    await bootstrap(forceRefresh: true);
  }

  Future<void> selectNearbyTab(VoiceRoomsNearbyTab tab) async {
    if (tab == state.nearbyTab) return;
    state = state.copyWith(nearbyTab: tab);
    try {
      final nearby = _repo.mapNearbyPage(
        rooms: state.allRooms,
        tab: tab,
        page: 0,
      );
      state = state.copyWith(
        nearbyRooms: nearby,
        nearbyPage: 0,
        hasMoreNearby: _repo.hasMoreNearby(
          rooms: state.allRooms,
          tab: tab,
          loadedCount: nearby.length,
        ),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadMoreNearby() async {
    if (state.isLoadingMore || !state.hasMoreNearby || state.allRooms.isEmpty) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.nearbyPage + 1;
    final nearby = _repo.mapNearbyPage(
      rooms: state.allRooms,
      tab: state.nearbyTab,
      page: nextPage,
    );
    state = state.copyWith(
      isLoadingMore: false,
      nearbyRooms: nearby,
      nearbyPage: nextPage,
      hasMoreNearby: _repo.hasMoreNearby(
        rooms: state.allRooms,
        tab: state.nearbyTab,
        loadedCount: nearby.length,
      ),
    );
  }

  Future<void> refresh() => bootstrap(forceRefresh: true);
}

final voiceRoomsDiscoverProvider =
    StateNotifierProvider<VoiceRoomsDiscoverNotifier, VoiceRoomsDiscoverViewState>(
  (ref) {
    ref.keepAlive();
    final notifier = VoiceRoomsDiscoverNotifier(
      ref.watch(voiceRoomsDiscoverRepositoryProvider),
    );
    notifier.bootstrap();
    return notifier;
  },
);
