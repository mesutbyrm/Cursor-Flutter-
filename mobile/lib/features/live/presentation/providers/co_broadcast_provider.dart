import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/live_stream_extras_datasource.dart';
import 'live_providers.dart';

class CoBroadcastState {
  const CoBroadcastState({
    this.invites = const [],
    this.loading = false,
    this.error,
  });

  final List<Map<String, dynamic>> invites;
  final bool loading;
  final String? error;

  CoBroadcastState copyWith({
    List<Map<String, dynamic>>? invites,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return CoBroadcastState(
      invites: invites ?? this.invites,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CoBroadcastNotifier extends Notifier<CoBroadcastState> {
  LiveStreamExtrasDataSource get _remote => ref.read(liveStreamExtrasProvider);

  @override
  CoBroadcastState build() => const CoBroadcastState();

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final invites = await _remote.fetchCoBroadcastInvites();
      state = state.copyWith(invites: invites, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
    }
  }

  Future<void> invite({
    required String streamId,
    required String inviteeId,
  }) async {
    await _remote.inviteCoBroadcast(streamId: streamId, inviteeId: inviteeId);
    await refresh();
  }

  Future<void> respond({
    required String streamId,
    required String inviteId,
    required bool accept,
  }) async {
    await _remote.respondCoBroadcast(
      streamId: streamId,
      inviteId: inviteId,
      accept: accept,
    );
    await refresh();
  }
}

final coBroadcastProvider =
    NotifierProvider<CoBroadcastNotifier, CoBroadcastState>(
  CoBroadcastNotifier.new,
);
