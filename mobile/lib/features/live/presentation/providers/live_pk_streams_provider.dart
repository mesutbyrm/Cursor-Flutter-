import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/live_stream_entity.dart';
import '../../domain/pk/live_pk_opponent_filter.dart';
import 'live_providers.dart';

/// PK rakip listesi — cache yok, SSE/socket ile yenilenir; 5 sn timeout.
class LivePkStreamsNotifier extends Notifier<AsyncValue<List<LiveStreamEntity>>> {
  CancelToken? _cancel;
  static const _fetchTimeout = Duration(seconds: 5);

  @override
  AsyncValue<List<LiveStreamEntity>> build() {
    ref.onDispose(_dispose);
    ref.listen(liveStreamsProvider, (_, next) {
      if (next.hasValue) unawaited(refresh(silent: true));
    });
    Future.microtask(refresh);
    return const AsyncValue.loading();
  }

  void _dispose() {
    _cancel?.cancel();
  }

  Future<void> refresh({bool silent = false}) async {
    _cancel?.cancel('refresh');
    _cancel = CancelToken();
    final token = _cancel;

    // Sessiz yenilemede loading'e düşme — PK ekranı spinner'da kalmasın.
    if (!silent && !state.hasValue) {
      state = const AsyncValue.loading();
    }

    try {
      final remote = ref.read(liveRemoteProvider);
      final raw = await remote
          .fetchPkEligibleStreams(cancelToken: token)
          .timeout(_fetchTimeout);
      if (token?.isCancelled == true) return;
      state = AsyncValue.data(raw);
    } on TimeoutException {
      if (token?.isCancelled == true) return;
      state = state.hasValue ? state : const AsyncValue.data([]);
    } catch (_) {
      if (token?.isCancelled == true) return;
      if (state.hasValue) return;
      // İlk yüklemede boş liste — sonsuz spinner olmasın.
      state = const AsyncValue.data([]);
    }
  }

  List<LiveStreamEntity> opponentsFor(String? myStreamId) {
    return filterPkEligibleLiveStreams(
      state.valueOrNull ?? const [],
      excludeStreamId: myStreamId,
    );
  }
}

final livePkStreamsProvider = NotifierProvider<LivePkStreamsNotifier,
    AsyncValue<List<LiveStreamEntity>>>(LivePkStreamsNotifier.new);
