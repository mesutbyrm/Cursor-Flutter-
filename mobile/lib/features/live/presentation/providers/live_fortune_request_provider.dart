import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/live_fortune_request_datasource.dart';
import '../../domain/entities/live_fortune_request_entity.dart';
import '../../domain/utils/live_discover_category.dart';
import 'live_providers.dart';

class LiveFortuneRequestsState {
  const LiveFortuneRequestsState({
    this.requests = const [],
    this.loading = false,
    this.error,
    this.newRequestPulse = 0,
  });

  final List<LiveFortuneRequestEntity> requests;
  final bool loading;
  final String? error;
  final int newRequestPulse;

  int get pendingCount => requests
      .where(
        (r) =>
            r.status == LiveFortuneRequestStatus.pending ||
            r.status == LiveFortuneRequestStatus.reviewing,
      )
      .length;

  LiveFortuneRequestsState copyWith({
    List<LiveFortuneRequestEntity>? requests,
    bool? loading,
    String? error,
    int? newRequestPulse,
    bool clearError = false,
  }) {
    return LiveFortuneRequestsState(
      requests: requests ?? this.requests,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      newRequestPulse: newRequestPulse ?? this.newRequestPulse,
    );
  }
}

class LiveFortuneRequestsNotifier
    extends AutoDisposeFamilyNotifier<LiveFortuneRequestsState, String> {
  @override
  LiveFortuneRequestsState build(String streamId) {
    Future.microtask(() => refresh());
    return const LiveFortuneRequestsState();
  }

  LiveFortuneRequestDataSource get _ds =>
      ref.read(liveFortuneRequestDataSourceProvider);

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final items = await _ds.fetchRequests(arg);
      state = state.copyWith(
        loading: false,
        requests: sortFortuneRequestQueue(items),
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<LiveFortuneRequestEntity?> submit({
    required String displayName,
    required String question,
    required String fortuneType,
    required LiveFortunePriority priority,
  }) async {
    try {
      final row = await _ds.createRequest(
        streamId: arg,
        displayName: displayName,
        question: question,
        fortuneType: fortuneType,
        priority: priority,
      );
      _upsert(row);
      return row;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> setStatus(
    String requestId,
    LiveFortuneRequestStatus status,
  ) async {
    try {
      final row = await _ds.updateStatus(
        streamId: arg,
        requestId: requestId,
        status: status,
      );
      _upsert(row);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void pushFromSse(Map<String, dynamic> map) {
    final row = LiveFortuneRequestEntity.fromJson(map);
    if (row.id.isEmpty) return;
    final existed = state.requests.any((r) => r.id == row.id);
    _upsert(row, notify: !existed);
  }

  void _upsert(LiveFortuneRequestEntity row, {bool notify = false}) {
    final list = [...state.requests];
    final i = list.indexWhere((r) => r.id == row.id);
    if (i >= 0) {
      list[i] = row;
    } else {
      list.add(row);
      notify = true;
    }
    state = state.copyWith(
      requests: sortFortuneRequestQueue(list),
      newRequestPulse: notify ? state.newRequestPulse + 1 : state.newRequestPulse,
    );
    if (notify) {
      HapticFeedback.heavyImpact();
    }
  }
}

final liveFortuneRequestDataSourceProvider =
    Provider<LiveFortuneRequestDataSource>((ref) {
  return LiveFortuneRequestDataSource(ref.watch(dioProvider));
});

final liveFortuneRequestsProvider = AutoDisposeNotifierProviderFamily<
    LiveFortuneRequestsNotifier,
    LiveFortuneRequestsState,
    String>(LiveFortuneRequestsNotifier.new);

/// Keşfet kategori filtresi.
final liveDiscoverCategoryProvider =
    StateProvider<LiveDiscoverCategory>((ref) => LiveDiscoverCategory.all);
