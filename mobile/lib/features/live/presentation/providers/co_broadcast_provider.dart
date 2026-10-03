import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/live_stream_extras_datasource.dart';
import '../../domain/live_guest_request_result.dart';
import '../../domain/repositories/live_guest_repository.dart';
import 'live_namespace_providers.dart';
import 'live_providers.dart';

class CoBroadcastState {
  const CoBroadcastState({
    this.invites = const [],
    this.coBroadcasters = const [],
    this.joinRequests = const [],
    this.myGuestInvites = const [],
    this.loading = false,
    this.error,
  });

  final List<Map<String, dynamic>> invites;
  final List<Map<String, dynamic>> coBroadcasters;
  final List<Map<String, dynamic>> joinRequests;

  /// İzleyici: bu yayında bana gelmiş bekleyen misafir davetleri (inviteId).
  final List<Map<String, dynamic>> myGuestInvites;
  final bool loading;
  final String? error;

  CoBroadcastState copyWith({
    List<Map<String, dynamic>>? invites,
    List<Map<String, dynamic>>? coBroadcasters,
    List<Map<String, dynamic>>? joinRequests,
    List<Map<String, dynamic>>? myGuestInvites,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return CoBroadcastState(
      invites: invites ?? this.invites,
      coBroadcasters: coBroadcasters ?? this.coBroadcasters,
      joinRequests: joinRequests ?? this.joinRequests,
      myGuestInvites: myGuestInvites ?? this.myGuestInvites,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CoBroadcastNotifier extends Notifier<CoBroadcastState> {
  LiveStreamExtrasDataSource get _remote => ref.read(liveStreamExtrasProvider);

  LiveGuestRepository get _guest => ref.read(liveGuestRepositoryProvider);

  var _refreshInFlight = false;
  var _refreshStreamInFlight = false;

  @override
  CoBroadcastState build() => const CoBroadcastState();

  Future<void> refresh() async {
    if (_refreshInFlight) return;
    _refreshInFlight = true;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final invites = await _remote.fetchCoBroadcastInvites();
      state = state.copyWith(invites: invites, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
    } finally {
      _refreshInFlight = false;
    }
  }

  Future<void> refreshStream(String streamId) async {
    if (_refreshStreamInFlight) return;
    _refreshStreamInFlight = true;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final snapshot = await _remote.fetchCoBroadcastSnapshot(streamId);
      state = state.copyWith(
        coBroadcasters: snapshot.coBroadcasters,
        joinRequests: snapshot.joinRequests,
        myGuestInvites: _remote.lastMyGuestInvites,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
    } finally {
      _refreshStreamInFlight = false;
    }
  }

  Future<void> invite({
    required String streamId,
    required String inviteeId,
  }) async {
    await _remote.inviteCoBroadcast(streamId: streamId, inviteeId: inviteeId);
    await refresh();
  }

  /// Yayına katılma (misafirlik) isteği.
  ///
  /// `/api/live/guest` 2xx dönüp isteği kaydetmeyebiliyor; bu durumda
  /// yayıncının okuduğu `/api/video-streams/{id}/co-broadcast` ucuna da
  /// yazılır. Hiçbiri kaydı onaylamazsa sonuç [LiveGuestRequestOutcome.unconfirmed]
  /// olur ve arayüz "gönderildi" demez.
  Future<LiveGuestRequestOutcome> requestJoin(String streamId) async {
    final primary = await _guest.postCoBroadcastCompat(
      streamId: streamId,
      action: 'request',
    );
    if (isGuestRequestAcknowledged(primary)) {
      await refreshStream(streamId);
      return LiveGuestRequestOutcome.acknowledged;
    }

    Map<String, dynamic>? fallback;
    try {
      fallback = await _remote.coBroadcastAction(
        streamId: streamId,
        action: 'request',
      );
    } catch (_) {
      fallback = null;
    }
    await refreshStream(streamId);
    return isGuestRequestAcknowledged(fallback)
        ? LiveGuestRequestOutcome.acknowledged
        : LiveGuestRequestOutcome.unconfirmed;
  }

  /// Onay/red `POST /api/live/guest {action, streamId, requestId}` ister;
  /// yalnızca `userId` gönderildiğinde sunucu 400 "requestId gerekli" dönüyor,
  /// yayıncının Kabul/Red düğmeleri hiçbir şey yapmıyordu.
  Future<void> approveRequest({
    required String streamId,
    required String userId,
    String? requestId,
  }) =>
      _respondToRequest(
        streamId: streamId,
        userId: userId,
        requestId: requestId,
        action: 'approve',
      );

  Future<void> rejectRequest({
    required String streamId,
    required String userId,
    String? requestId,
  }) =>
      _respondToRequest(
        streamId: streamId,
        userId: userId,
        requestId: requestId,
        action: 'reject',
      );

  Future<void> _respondToRequest({
    required String streamId,
    required String userId,
    required String action,
    String? requestId,
  }) async {
    var id = requestId?.trim() ?? '';
    if (id.isEmpty) id = _requestIdFor(userId);
    if (id.isEmpty) {
      await refreshStream(streamId);
      id = _requestIdFor(userId);
    }
    if (id.isEmpty) {
      throw StateError('İstek bulunamadı — süresi dolmuş olabilir');
    }
    await _guest.postCoBroadcastCompat(
      streamId: streamId,
      action: action,
      userId: userId,
      requestId: id,
    );
    await refreshStream(streamId);
  }

  String _requestIdFor(String userId) {
    for (final r in state.joinRequests) {
      if (r['userId']?.toString() == userId) {
        return r['requestId']?.toString() ?? '';
      }
    }
    return '';
  }

  Future<void> acceptInvite(String streamId, {String? inviteId}) =>
      _respondToInvite(streamId, accept: true, inviteId: inviteId);

  Future<void> rejectInvite(String streamId, {String? inviteId}) =>
      _respondToInvite(streamId, accept: false, inviteId: inviteId);

  /// Davet edilen izleyicinin cevabı.
  ///
  /// `/api/live/guest` davet yanıtı `{action: respond, inviteId, accept}`
  /// ister; `accept` diye bir eylem yok (400), `reject` ise yayıncının istek
  /// reddetme dalıdır (403). Önceden izleyici daveti kabul/red edemiyordu.
  /// Davet eski co-broadcast sisteminden geldiyse onun PATCH ucu kullanılır.
  Future<void> _respondToInvite(
    String streamId, {
    required bool accept,
    String? inviteId,
  }) async {
    var id = inviteId?.trim() ?? '';
    if (id.isEmpty) id = await _pendingGuestInviteId(streamId);
    if (id.isNotEmpty) {
      await _guest.postGuestAction(
        {
          'action': 'respond',
          'streamId': streamId,
          'inviteId': id,
          'accept': accept,
        },
        streamId: streamId,
      );
      await refreshStream(streamId);
      return;
    }
    await _guest.patchCoBroadcastCompat(
      streamId: streamId,
      action: accept ? 'accept' : 'reject',
    );
  }

  /// `GET /api/live/guest?view=sync` — yetkisiz kullanıcıya yalnızca kendi
  /// bekleyen kayıtları döner; yayıncı daveti `kind: invite`.
  Future<String> _pendingGuestInviteId(String streamId) async {
    try {
      final body = await _guest.fetchGuestSession(
        streamId: streamId,
        view: 'sync',
      );
      final pending = body['pending'];
      if (pending is! List) return '';
      for (final p in pending) {
        if (p is! Map) continue;
        if (p['kind']?.toString() == 'invite' &&
            (p['status']?.toString() ?? 'pending') == 'pending') {
          return p['id']?.toString() ?? '';
        }
      }
    } catch (_) {}
    return '';
  }

  /// Yayıncı — misafiri yayından indirir (`/api/live/guest` kick; eski uçta
  /// `remove`). Ardından liste yenilenir.
  Future<void> removeGuest(String streamId, String userId) async {
    await _guest.postCoBroadcastCompat(
      streamId: streamId,
      action: 'kick',
      userId: userId,
    );
    await refreshStream(streamId);
  }

  Future<void> leave(String streamId) async {
    await _guest.patchCoBroadcastCompat(streamId: streamId, action: 'leave');
  }

  void clear() {
    state = const CoBroadcastState();
  }
}

final coBroadcastProvider =
    NotifierProvider<CoBroadcastNotifier, CoBroadcastState>(
  CoBroadcastNotifier.new,
);
