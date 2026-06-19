import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/psychic_entity.dart';
import '../../domain/entities/psychic_review_entity.dart';
import '../providers/live_psychics_providers.dart';

class PsychicsListState {
  const PsychicsListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isRefreshing = false,
  });

  final List<PsychicEntity> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isRefreshing;

  PsychicsListState copyWith({
    List<PsychicEntity>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isRefreshing,
  }) {
    return PsychicsListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class PsychicsListController extends AutoDisposeAsyncNotifier<PsychicsListState> {
  static const _pageSize = 20;

  @override
  Future<PsychicsListState> build() async {
    final repo = ref.read(livePsychicsRepositoryProvider);
    final first = await repo.fetchPsychics(
      page: 1,
      limit: _pageSize,
      onlineOnly: true,
      sort: 'rating',
    );
    return PsychicsListState(
      items: first,
      page: 1,
      hasMore: first.length >= _pageSize,
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(isRefreshing: true));
    }
    try {
      final repo = ref.read(livePsychicsRepositoryProvider);
      final first = await repo.fetchPsychics(
      page: 1,
      limit: _pageSize,
      onlineOnly: true,
      sort: 'rating',
    );
      state = AsyncData(PsychicsListState(
        items: first,
        page: 1,
        hasMore: first.length >= _pageSize,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final repo = ref.read(livePsychicsRepositoryProvider);
      final nextPage = current.page + 1;
      final batch = await repo.fetchPsychics(
        page: nextPage,
        limit: _pageSize,
        onlineOnly: true,
        sort: 'rating',
      );
      final merged = [...current.items, ...batch];
      final seen = <String>{};
      final unique = <PsychicEntity>[];
      for (final p in merged) {
        if (seen.add(p.id)) unique.add(p);
      }
      state = AsyncData(PsychicsListState(
        items: unique,
        page: nextPage,
        hasMore: batch.length >= _pageSize,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void patchOnlineStatus(String psychicId, {required bool isOnline}) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(PsychicsListState(
      items: current.items
          .map((p) => p.id == psychicId ? PsychicEntity(
                id: p.id,
                userId: p.userId,
                name: p.name,
                bio: p.bio,
                avatarUrl: p.avatarUrl,
                isOnline: isOnline,
                rating: p.rating,
                reviewCount: p.reviewCount,
                pricePerMinute: p.pricePerMinute,
                specialties: p.specialties,
                category: p.category,
                applicationStatus: p.applicationStatus,
              ) : p)
          .toList(growable: false),
      page: current.page,
      hasMore: current.hasMore,
    ));
  }
}

final psychicsListControllerProvider =
    AutoDisposeAsyncNotifierProvider<PsychicsListController, PsychicsListState>(
  PsychicsListController.new,
);

final psychicReviewsProvider =
    FutureProvider.autoDispose.family<List<PsychicReviewEntity>, String>(
  (ref, tellerId) async {
    return ref.read(livePsychicsRepositoryProvider).fetchReviews(tellerId);
  },
);

final psychicDetailProvider =
    FutureProvider.autoDispose.family<PsychicEntity?, String>((ref, id) async {
  return ref.read(livePsychicsRepositoryProvider).fetchPsychic(id);
});

final approvedPsychicProvider =
    AsyncNotifierProvider<ApprovedPsychicController, ApprovedPsychicState>(
  ApprovedPsychicController.new,
);

class ApprovedPsychicState {
  const ApprovedPsychicState({this.profile, this.isLoading = false});

  final PsychicEntity? profile;
  final bool isLoading;

  bool get isApprovedTeller => profile?.isUsable == true;
}

class ApprovedPsychicController extends AsyncNotifier<ApprovedPsychicState> {
  @override
  Future<ApprovedPsychicState> build() async {
    final profile = await ref.read(livePsychicsRepositoryProvider).fetchMyProfile();
    return ApprovedPsychicState(profile: profile);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile =
          await ref.read(livePsychicsRepositoryProvider).fetchMyProfile();
      return ApprovedPsychicState(profile: profile);
    });
  }
}
