import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/live_remote_datasource.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../../domain/pk/live_pk_opponent_filter.dart';
import 'live_providers.dart';

/// PK rakip listesi — cache yok, 3 sn poll, 5 sn timeout, sonsuz loading yok.
class LivePkStreamsNotifier extends Notifier<AsyncValue<List<LiveStreamEntity>>> {
  Timer? _timer;
  CancelToken? _cancel;
  static const _pollInterval = Duration(seconds: 3);
  static const _fetchTimeout = Duration(seconds: 5);

  @override
  AsyncValue<List<LiveStreamEntity>> build() {
    ref.onDispose(_dispose);
    ref.listen(liveStreamsProvider, (_, next) {
      if (next.hasValue) unawaited(refresh(silent: true));
    });
    Future.microtask(refresh);
    _timer = Timer.periodic(_pollInterval, (_) => refresh(silent: true));
    return const AsyncValue.loading();
  }

  void _dispose() {
    _timer?.cancel();
    _cancel?.cancel();
  }

  Future<void> refresh({bool silent = false}) async {
    _cancel?.cancel('refresh');
    _cancel = CancelToken();
    final token = _cancel;

    if (!silent) {
      state = state.whenData((v) => v).copyWithPrevious(state);
      if (!state.hasValue) state = const AsyncValue.loading();
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
      state = state.hasValue
          ? state
          : AsyncValue.error(
              'PK listesi zaman aşımı (5 sn)',
              StackTrace.current,
            );
    } catch (e, st) {
      if (token?.isCancelled == true) return;
      if (state.hasValue) return;
      state = AsyncValue.error(e, st);
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
