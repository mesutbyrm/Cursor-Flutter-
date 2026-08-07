import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/loading_timeout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/psychic_award_entity.dart';
import '../../domain/entities/psychic_entity.dart';
import '../../domain/entities/psychic_gift_entity.dart';
import '../../domain/entities/psychic_review_entity.dart';
import '../diagnostics/teller_role_diagnostic.dart';
import '../providers/live_psychics_providers.dart';

class PsychicsListFilters {
  const PsychicsListFilters({
    this.specialty,
    this.sort = 'rating',
    this.onlineOnly = true,
  });

  final String? specialty;
  final String sort;
  final bool onlineOnly;

  PsychicsListFilters copyWith({
    String? specialty,
    bool clearSpecialty = false,
    String? sort,
    bool? onlineOnly,
  }) {
    return PsychicsListFilters(
      specialty: clearSpecialty ? null : (specialty ?? this.specialty),
      sort: sort ?? this.sort,
      onlineOnly: onlineOnly ?? this.onlineOnly,
    );
  }
}

class PsychicsListState {
  const PsychicsListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.filters = const PsychicsListFilters(),
    this.favoritesOnly = false,
  });

  final List<PsychicEntity> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isRefreshing;
  final PsychicsListFilters filters;
  final bool favoritesOnly;

  PsychicsListState copyWith({
    List<PsychicEntity>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isRefreshing,
    PsychicsListFilters? filters,
    bool? favoritesOnly,
  }) {
    return PsychicsListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      filters: filters ?? this.filters,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    );
  }
}

class PsychicsListController extends AutoDisposeAsyncNotifier<PsychicsListState> {
  static const _pageSize = 20;

  @override
  Future<PsychicsListState> build() async {
    return _fetchFirst(const PsychicsListFilters());
  }

  Future<PsychicsListState> _fetchFirst(PsychicsListFilters filters,
      {bool favoritesOnly = false}) async {
    final repo = ref.read(livePsychicsRepositoryProvider);
    if (favoritesOnly) {
      final favorites = await repo.fetchFavoritePsychics();
      return PsychicsListState(
        items: favorites,
        page: 1,
        hasMore: false,
        filters: filters,
        favoritesOnly: true,
      );
    }
    final first = await repo.fetchPsychics(
      page: 1,
      limit: _pageSize,
      onlineOnly: filters.onlineOnly ? true : null,
      specialty: filters.specialty,
      sort: filters.sort,
    );
    return PsychicsListState(
      items: first,
      page: 1,
      hasMore: first.length >= _pageSize,
      filters: filters,
    );
  }

  Future<void> showFavoritesOnly(bool enabled) async {
    final current = state.valueOrNull;
    final filters = current?.filters ?? const PsychicsListFilters();
    if (current != null) {
      state = AsyncData(
        current.copyWith(isRefreshing: true, favoritesOnly: enabled),
      );
    } else {
      state = const AsyncLoading();
    }
    try {
      state = AsyncData(await _fetchFirst(filters, favoritesOnly: enabled));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> applyFilters(PsychicsListFilters filters) async {
    final current = state.valueOrNull;
    final favoritesOnly = current?.favoritesOnly ?? false;
    if (current != null) {
      state = AsyncData(current.copyWith(isRefreshing: true, filters: filters));
    } else {
      state = const AsyncLoading();
    }
    try {
      state = AsyncData(await _fetchFirst(filters, favoritesOnly: favoritesOnly));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    final filters = current?.filters ?? const PsychicsListFilters();
    final favoritesOnly = current?.favoritesOnly ?? false;
    if (current != null) {
      state = AsyncData(current.copyWith(isRefreshing: true));
    }
    try {
      state = AsyncData(await _fetchFirst(filters, favoritesOnly: favoritesOnly));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.favoritesOnly) return;
    if (!current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final repo = ref.read(livePsychicsRepositoryProvider);
      final nextPage = current.page + 1;
      final filters = current.filters;
      final batch = await repo.fetchPsychics(
        page: nextPage,
        limit: _pageSize,
        onlineOnly: filters.onlineOnly ? true : null,
        specialty: filters.specialty,
        sort: filters.sort,
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
        filters: filters,
        favoritesOnly: current.favoritesOnly,
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
      filters: current.filters,
      favoritesOnly: current.favoritesOnly,
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

final psychicAwardsProvider =
    FutureProvider.autoDispose.family<List<PsychicAwardEntity>, String>(
  (ref, tellerId) async {
    return ref.read(livePsychicsRepositoryProvider).fetchAwards(tellerId);
  },
);

final psychicGiftsProvider =
    FutureProvider.autoDispose.family<List<PsychicGiftEntity>, String>(
  (ref, tellerId) async {
    return ref.read(livePsychicsRepositoryProvider).fetchGifts(tellerId);
  },
);

final psychicDetailProvider =
    FutureProvider.autoDispose.family<PsychicEntity?, String>((ref, id) async {
  return ref.read(livePsychicsRepositoryProvider).fetchPsychic(id);
});

final approvedPsychicProvider =
    NotifierProvider<ApprovedPsychicNotifier, ApprovedPsychicState>(
  ApprovedPsychicNotifier.new,
);

class ApprovedPsychicState {
  const ApprovedPsychicState({
    this.profile,
    this.loading = false,
    this.checked = false,
    this.lastDiagnostic,
  });

  final PsychicEntity? profile;
  final bool loading;
  final bool checked;
  final String? lastDiagnostic;

  bool get isApprovedTeller => profile?.isUsable == true;
}

class ApprovedPsychicNotifier extends Notifier<ApprovedPsychicState> {
  @override
  ApprovedPsychicState build() {
    ref.listen(authControllerProvider, (prev, next) {
      final user = next.valueOrNull;
      if (user == null) {
        state = const ApprovedPsychicState(checked: true);
        return;
      }
      if (prev?.valueOrNull?.id != user.id) {
        unawaited(refresh());
      }
    });
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user != null) {
      Future.microtask(refresh);
    }
    return ApprovedPsychicState(loading: user != null);
  }

  void adoptProfile(PsychicEntity? profile) {
    if (profile == null) return;
    state = ApprovedPsychicState(
      profile: profile,
      loading: false,
      checked: true,
      lastDiagnostic: 'apply-response',
    );
  }

  Future<void> refresh() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      state = const ApprovedPsychicState(checked: true);
      return;
    }
    final previousDiagnostic = state.lastDiagnostic;
  final cachedProfile = state.profile;
    state = state.copyWith(loading: true);
    try {
      final myProfile = await LoadingTimeout.run(
        ref.read(livePsychicsRepositoryProvider).fetchMyProfile(),
        timeout: const Duration(seconds: 10),
        message: 'Falcı profili yüklenemedi',
      );
      if (myProfile != null && myProfile.isUsable) {
        state = ApprovedPsychicState(
          profile: myProfile,
          loading: false,
          checked: true,
          lastDiagnostic: 'my-profile',
        );
        return;
      }

      final quick = await LoadingTimeout.run(
        ref
            .read(livePsychicsRepositoryProvider)
            .findApprovedTellerForUser(user.id, username: user.username),
        timeout: const Duration(seconds: 8),
        message: 'Falcı listesi yüklenemedi',
      );
      if (quick != null && quick.isUsable) {
        state = ApprovedPsychicState(
          profile: quick,
          loading: false,
          checked: true,
          lastDiagnostic: 'list-fast',
        );
        return;
      }

      final resolved = await LoadingTimeout.run(
        ref
            .read(fortuneTellerProfileResolverProvider)
            .resolveFortuneTellerProfile(user),
        timeout: const Duration(seconds: 12),
        message: 'Falcı profili yüklenemedi',
      );
      final diagnostic = TellerRoleDiagnostic.fromResolve(
        user: user,
        resolved: resolved,
      );
      diagnostic.emit();
      state = ApprovedPsychicState(
        profile: resolved.profile,
        loading: false,
        checked: true,
        lastDiagnostic: resolved.source,
      );
    } catch (e, st) {
      debugPrint('[TellerDebug] refresh failed: $e\n$st');
      final preserved = cachedProfile ?? state.profile;
      state = ApprovedPsychicState(
        profile: preserved,
        loading: false,
        checked: true,
        lastDiagnostic: preserved?.isUsable == true
            ? (previousDiagnostic ?? 'cached_profile')
            : 'error',
      );
    }
  }
}

extension ApprovedPsychicStateCopy on ApprovedPsychicState {
  ApprovedPsychicState copyWith({
    PsychicEntity? profile,
    bool? loading,
    bool? checked,
    String? lastDiagnostic,
    bool clearProfile = false,
  }) {
    return ApprovedPsychicState(
      profile: clearProfile ? null : (profile ?? this.profile),
      loading: loading ?? this.loading,
      checked: checked ?? this.checked,
      lastDiagnostic: lastDiagnostic ?? this.lastDiagnostic,
    );
  }
}
