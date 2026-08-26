import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/live_fortune_request_datasource.dart';
import '../../domain/entities/live_fortune_request_entity.dart';
import '../../domain/utils/live_discover_category.dart';
import '../../domain/utils/live_fortune_host_bridge.dart';

/// Yayıncı kullanıcı kimliği — fal davet köprüsü için (SSE'de yoksa).
final liveFortuneHostUserIdProvider =
    StateProvider.autoDispose.family<String?, String>((ref, streamId) => null);

class LiveFortuneRequestsState {
  const LiveFortuneRequestsState({
    this.requests = const [],
    this.loading = false,
    this.submitting = false,
    this.error,
    this.newRequestPulse = 0,
  });

  final List<LiveFortuneRequestEntity> requests;
  final bool loading;
  final bool submitting;
  final String? error;
  final int newRequestPulse;

  int get pendingCount => requests
      .where(
        (r) =>
            r.status == LiveFortuneRequestStatus.pending ||
            r.status == LiveFortuneRequestStatus.held ||
            r.status == LiveFortuneRequestStatus.reviewing,
      )
      .length;

  LiveFortuneRequestsState copyWith({
    List<LiveFortuneRequestEntity>? requests,
    bool? loading,
    bool? submitting,
    String? error,
    int? newRequestPulse,
    bool clearError = false,
  }) {
    return LiveFortuneRequestsState(
      requests: requests ?? this.requests,
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
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
      final prevIds = state.requests.map((r) => r.id).toSet();
      final items = await _ds.fetchRequests(arg);
      final newPending = items.where(
        (r) =>
            !prevIds.contains(r.id) &&
            (r.status == LiveFortuneRequestStatus.pending ||
                r.status == LiveFortuneRequestStatus.held),
      );
      state = state.copyWith(
        loading: false,
        requests: sortFortuneRequestQueue(items),
        newRequestPulse: newPending.isNotEmpty
            ? state.newRequestPulse + newPending.length
            : state.newRequestPulse,
      );
      if (newPending.isNotEmpty) {
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: ApiException.userMessage(e));
    }
  }

  Future<LiveFortuneRequestEntity?> submit({
    required String displayName,
    required String question,
    required String fortuneType,
    required LiveFortunePriority priority,
    int? jetonCost,
  }) async {
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final row = await _ds
          .createRequest(
            streamId: arg,
            displayName: displayName,
            question: question,
            fortuneType: fortuneType,
            priority: priority,
            jetonCost: jetonCost,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Fal isteği gönderilemedi: sunucu yanıt vermiyor.',
              const Duration(seconds: 15),
            ),
          );
      _upsert(row);
      return row;
    } on TimeoutException {
      state = state.copyWith(
        submitting: false,
        error:
            'Fal isteği gönderilemedi: bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.',
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        submitting: false,
        error: ApiException.userMessage(e),
      );
      return null;
    } finally {
      if (state.submitting) {
        state = state.copyWith(submitting: false);
      }
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
      state = state.copyWith(error: ApiException.userMessage(e));
    }
  }

  void pushFromSse(Map<String, dynamic> map) {
    final row = _parseFortuneRequestFromSse(map);
    if (row.id.isEmpty) return;
    final existed = state.requests.any((r) => r.id == row.id);
    _upsert(row, notify: !existed);
  }

  LiveFortuneRequestEntity? latestFromMap(Map<String, dynamic> map) {
    final row = _parseFortuneRequestFromSse(map);
    return row.id.isEmpty ? null : row;
  }

  LiveFortuneRequestEntity _parseFortuneRequestFromSse(Map<String, dynamic> map) {
    return parseLiveFortuneRequestMap(map);
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
      _emitHostInvite(row);
    }
  }

  void _emitHostInvite(LiveFortuneRequestEntity row) {
    if (row.status != LiveFortuneRequestStatus.pending &&
        row.status != LiveFortuneRequestStatus.held) {
      return;
    }
    // Canlı yayın fal kuyruğu — 1:1 falcı diyaloğuna yönlendirme yapılmaz.
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
