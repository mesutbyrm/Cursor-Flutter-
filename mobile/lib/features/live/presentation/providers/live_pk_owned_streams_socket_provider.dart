import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/sse/sse_hub_provider.dart';
import '../../../../core/network/token_storage.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/live_stream_entity.dart';
import 'discover_live_streams.dart';
import 'live_pk_invite_signal_provider.dart';
import 'pk_room_providers.dart';

/// Sahip olunan canlı yayınlar için arka plan SSE — yayıncı odada değilken PK daveti.
///
/// Socket.IO yok; `GET /api/video-streams/{id}/stream` üzerinden `pk_battle` olayları.
final livePkOwnedStreamsSocketProvider =
    NotifierProvider<LivePkOwnedStreamsSocketNotifier, void>(
  LivePkOwnedStreamsSocketNotifier.new,
);

class LivePkOwnedStreamsSocketNotifier extends Notifier<void> {
  final Set<String> _attached = {};

  @override
  void build() {
    ref.onDispose(_detachAll);
    ref.listen(authControllerProvider, (_, __) => _sync());
    ref.listen(liveStreamsProvider, (_, __) => _sync());
    Future.microtask(_sync);
  }

  List<LiveStreamEntity> _ownedLiveStreams(String userId) {
    final streams = ref.read(liveStreamsProvider).valueOrNull ?? const [];
    return streams
        .where((s) {
          if (!s.isLive) return false;
          final host = s.hostUserId?.trim() ?? '';
          return host.isNotEmpty && host == userId;
        })
        .toList(growable: false);
  }

  void _sync() {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      _detachAll();
      return;
    }

    final ownedIds = _ownedLiveStreams(user.id)
        .map((s) => s.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final id in _attached.toList()) {
      if (!ownedIds.contains(id)) _detach(id);
    }
    for (final id in ownedIds) {
      _attachIfNeeded(id);
    }
  }

  void _attachIfNeeded(String streamId) {
    final id = streamId.trim();
    if (id.isEmpty || _attached.contains(id)) return;

    final hub = ref.read(sseConnectionHubProvider);
    final storage = ref.read(tokenStorageProvider);
    hub.attachVideoStream(id);
    final sse = hub.videoStream(id);
    unawaited(
      sse.connect(
        streamId: id,
        accessToken: storage.readAccess,
        onPkBattle: (battle) {
          final status = (battle['status'] ?? '').toString().toLowerCase();
          if (status == 'pending' || status == 'invited') {
            ref.read(livePkInviteSignalProvider.notifier).bump();
            ref.invalidate(pkPendingInvitesProvider);
          }
        },
      ),
    );
    _attached.add(id);
  }

  void _detach(String streamId) {
    final id = streamId.trim();
    if (!_attached.remove(id)) return;
    ref.read(sseConnectionHubProvider).releaseVideoStream(id);
  }

  void _detachAll() {
    for (final id in _attached.toList()) {
      _detach(id);
    }
  }
}
