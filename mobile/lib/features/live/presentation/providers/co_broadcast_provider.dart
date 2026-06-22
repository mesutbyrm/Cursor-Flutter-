import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/live_stream_extras_datasource.dart';
import 'live_providers.dart';

class CoBroadcastState {
  const CoBroadcastState({
    this.invites = const [],
    this.coBroadcasters = const [],
    this.joinRequests = const [],
    this.viewers = const [],
    this.loading = false,
    this.viewersLoading = false,
    this.error,
    // Yayıncının "izleyici davet et" butonunu aktif/pasif gösterme
    // anahtarı. Yalnızca yerel/oturum bazlı (backend'e kaydedilmiyor)
    // — uygulama yeniden başladığında varsayılana (true) döner.
    // ÖNEMLİ: bu durum yalnızca YAYINCININ kendi cihazında anlamlıdır;
    // izleyici tarafında bu state'in bir karşılığı yoktur, dolayısıyla
    // izleyicinin "katılma isteği gönder" butonunu bu anahtara göre
    // kısıtlamıyoruz (backend desteği olmadan bunu güvenilir şekilde
    // yapamayız).
    this.inviteEnabled = true,
  });

  final List<Map<String, dynamic>> invites;
  final List<Map<String, dynamic>> coBroadcasters;
  final List<Map<String, dynamic>> joinRequests;
  final List<Map<String, dynamic>> viewers;
  final bool loading;
  final bool viewersLoading;
  final String? error;
  final bool inviteEnabled;

  CoBroadcastState copyWith({
    List<Map<String, dynamic>>? invites,
    List<Map<String, dynamic>>? coBroadcasters,
    List<Map<String, dynamic>>? joinRequests,
    List<Map<String, dynamic>>? viewers,
    bool? loading,
    bool? viewersLoading,
    String? error,
    bool clearError = false,
    bool? inviteEnabled,
  }) {
    return CoBroadcastState(
      invites: invites ?? this.invites,
      coBroadcasters: coBroadcasters ?? this.coBroadcasters,
      joinRequests: joinRequests ?? this.joinRequests,
      viewers: viewers ?? this.viewers,
      loading: loading ?? this.loading,
      viewersLoading: viewersLoading ?? this.viewersLoading,
      error: clearError ? null : (error ?? this.error),
      inviteEnabled: inviteEnabled ?? this.inviteEnabled,
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
      final snapshot = await _remote.fetchCoBroadcastSnapshot(streamId);
      state = state.copyWith(
        coBroadcasters: snapshot.coBroadcasters,
        joinRequests: snapshot.joinRequests,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
    }
  }

  Future<void> invite({
    required String streamId,
    required String inviteeId,
  }) async {
    // ÖNEMLİ: önceden hata yakalama yoktu — inviteCoBroadcast() hata
    // fırlatırsa Future sessizce reddediliyor, UI hiçbir şey görmüyordu
    // ("buton tıklanıyor ama hiçbir şey olmuyor"). Artık hata state'e
    // yazılıyor, çağıran widget bunu okuyup gösterebilir.
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _remote.inviteCoBroadcast(streamId: streamId, inviteeId: inviteeId);
      await refresh();
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
      rethrow;
    }
  }

  /// İzleyici listesi — davet etmek için kimi seçeceğimizi göstermek üzere.
  Future<void> loadViewers(String streamId) async {
    state = state.copyWith(viewersLoading: true);
    try {
      final viewers = await _remote.fetchViewers(streamId);
      state = state.copyWith(viewers: viewers, viewersLoading: false);
    } catch (e) {
      state = state.copyWith(viewersLoading: false, error: '$e');
    }
  }

  /// Yayıncının "izleyici davet et" butonunu göstermesini kontrol eden
  /// yerel anahtar. Yalnızca bu cihazın UI'ını etkiler (bkz. state
  /// dokümantasyonu) — izleyici tarafında karşılığı yoktur.
  void setInviteEnabled(bool enabled) {
    state = state.copyWith(inviteEnabled: enabled);
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
