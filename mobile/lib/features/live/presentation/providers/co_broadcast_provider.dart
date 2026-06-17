import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/live_stream_extras_datasource.dart';
import 'live_providers.dart';

class CoBroadcastState {
  const CoBroadcastState({
    this.invites = const [],
    this.coBroadcasters = const [],
    this.loading = false,
    this.error,
  });

  final List<Map<String, dynamic>> invites;
  final List<Map<String, dynamic>> coBroadcasters;
  final bool loading;
  final String? error;

  CoBroadcastState copyWith({
    List<Map<String, dynamic>>? invites,
    List<Map<String, dynamic>>? coBroadcasters,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return CoBroadcastState(
      invites: invites ?? this.invites,
      coBroadcasters: coBroadcasters ?? this.coBroadcasters,
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

  Future<void> refreshStream(String streamId) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final coBroadcasters = await _remote.fetchCoBroadcasters(streamId);
      state = state.copyWith(coBroadcasters: coBroadcasters, loading: false);
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

  Future<void> requestJoin(String streamId) async {
    await _remote.coBroadcastAction(streamId: streamId, action: 'request');
  }

  Future<void> approveRequest({
    required String streamId,
    required String userId,
  }) async {
    await _remote.coBroadcastAction(
      streamId: streamId,
      action: 'approve',
      userId: userId,
    );
    await refreshStream(streamId);
  }

  Future<void> acceptInvite(String streamId) async {
    await _remote.patchCoBroadcast(streamId: streamId, action: 'accept');
  }

  Future<void> rejectInvite(String streamId) async {
    await _remote.patchCoBroadcast(streamId: streamId, action: 'reject');
  }

  Future<void> leave(String streamId) async {
    await _remote.patchCoBroadcast(streamId: streamId, action: 'leave');
  }
}

final coBroadcastProvider =
    NotifierProvider<CoBroadcastNotifier, CoBroadcastState>(
  CoBroadcastNotifier.new,
);
